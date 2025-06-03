# /home/janrutger/git/STERN-1/display7.py
from tkinter import *
from time import time
# No need to import Plotter here, just accept it as an argument

class CharDisplay():
    # Add 'plotter' to the __init__ signature
    def __init__(self, myASCII, interrupts, vdisk, plotter, width, height, memory, scale=10):
        self.ASCII = myASCII
        self.int = interrupts
        self.vdisk = vdisk
        self.plotter = plotter # <-- Store the plotter instance
        self.width = width
        self.height = height
        self.scale = scale
        self.memory = memory
        self.videoadres = self.memory.MEMmax() - (self.width * self.height) + 1

        self.display = Tk()
        self.display.title("STERN I")
        # Handle window close event gracefully
        self.display.protocol("WM_DELETE_WINDOW", self._on_closing)
        self.canvas = Canvas(self.display, width=self.width * self.scale, height=self.height * self.scale)
        self.canvas.pack()
        self.canvas.config(bg="black")

        self.input_var = StringVar()
        self.input_bar = Entry(self.display, textvariable=self.input_var, width=16)
        self.input_bar.pack()
        self.input_bar.bind("<Key>", self.key_pressed)

        self.prev_mem = []
        self.char_map = {}

        self.chars = {}
        for y in range(self.height):
            for x in range(self.width):
                # Initialize with placeholder IDs, actual text objects created in draw_screen
                self.chars[(x, y)] = None

        self._running = True # Flag to control the update loop
        self.my_tasks() # Start the update loop

    def _on_closing(self):
        """Handles the Tkinter window close button."""
        print("Tkinter window closing...")
        self._running = False # Signal the update loop to stop
        # Optionally close the plotter window here too
        if self.plotter:
            self.plotter._close_plot()
        self.display.destroy() # Close the Tkinter window

    def my_tasks(self):
        """Periodically update screen, disk, and plotter."""
        if not self._running: # Check if we should stop
            return

        try:
            # Update other components
            self.update_disk()
            self.update_videoMemory()

            # --- Call plotter update ---
            if self.plotter:
                self.plotter.plot_update()

            # --- Schedule next call ---
            # Use a regular interval (e.g., 50ms)
            self.display.after(50, self.my_tasks)
            #self.display.after_idle(self.my_tasks)

        except Exception as e:
            # Catch errors to prevent the update loop from stopping unexpectedly
            # Check if the error is due to the Tkinter window being destroyed
            if isinstance(e, TclError) and "invalid command name" in str(e):
                 print("Tkinter TclError likely due to window closing. Stopping updates.")
                 self._running = False # Ensure loop stops
            else:
                 print(f"Error in update loop: {e}")
                 # Optionally stop the loop on other errors too
                 # self._running = False
            # Don't reschedule if there was an error or if _running is false
            if not self._running:
                return


    def update_videoMemory(self):
        # Avoid reading if memory object is gone (less likely here)
        if not self.memory: return
        try:
            videoMemory = [self.memory.read(self.videoadres + i) for i in range(self.width * self.height)]
            if self.prev_mem != videoMemory:
                self.draw_screen(videoMemory)
                self.prev_mem = videoMemory
        except Exception as e:
            print(f"Error reading video memory: {e}")
            # Handle error, maybe clear screen or show error state

    def update_disk(self):
        # Avoid accessing if vdisk object is gone
        if not self.vdisk: return
        try:
            self.vdisk.access()
        except Exception as e:
            print(f"Error accessing virtual disk: {e}")


    def draw_screen(self, memory):
        if not self._running or not self.canvas.winfo_exists(): # Check if canvas exists
             return

        mem_pointer = 0
        changes = []
        for y in range(self.height):
            for x in range(self.width):
                mem_val = memory[mem_pointer]
                try:
                    index = int(mem_val)
                except ValueError:
                    index = self.ASCII.get('?', 0) # Use '?' or null for invalid data

                # Find character, default to '?' if not found or invalid index
                char = next((k for k, v in self.ASCII.items() if v == index), '?')
                # Handle specific non-printable chars if needed
                if char == "space":
                    char = " " # Display space as actual space
                elif index == 0: # Handle null character
                    char = "" # Display null as empty

                # Only update if character changed or position was never drawn
                current_char = self.char_map.get((x, y))
                if current_char != char:
                    changes.append((x, y, char))
                mem_pointer += 1

        # Apply batched changes
        for x, y, char in changes:
            if not self._running or not self.canvas.winfo_exists(): break # Stop if window closed during loop

            old_id = self.chars.get((x, y))
            if old_id:
                try:
                    self.canvas.delete(old_id)
                except TclError:
                    pass # Item might already be gone

            # Create new text element only if char is not empty
            if char:
                try:
                    new_id = self.canvas.create_text(
                        (x * self.scale + self.scale // 2, y * self.scale + self.scale // 2), # Center text
                        text=char,
                        fill="white",
                        anchor=CENTER, # Use CENTER anchor
                        font=("Courier", self.scale)
                    )
                    self.chars[(x, y)] = new_id
                except TclError:
                     pass # Canvas might be destroyed
            else:
                 self.chars[(x, y)] = None # No object exists for this empty char

            self.char_map[(x, y)] = char # Update the map regardless

        # No need for self.display.update() - rely on Tkinter's event loop


    def key_pressed(self, event):
        if not self._running: return # Ignore keys if closing

        value = -1
        key_name = None

        if event.keysym in self.ASCII: # Prefer keysym for special keys (Return, Up, etc.)
            key_name = event.keysym
            value = self.ASCII[key_name]
            if key_name == "Return":
                self.input_var.set("") # Clear input box
        elif event.char and event.char in self.ASCII: # Use char for printable characters
             key_name = event.char
             value = self.ASCII[key_name]

        if value != -1:
            # print(f"Key pressed: {key_name}, Value: {value}")
            self.int.interrupt(0, value) # Assuming interrupt 0 is keyboard
        else:
            # Don't print every unknown key, can be noisy
            print(f"Unknown key pressed: char='{event.char}', keysym='{event.keysym}'")
            pass

