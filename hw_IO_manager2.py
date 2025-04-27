# /home/janrutger/git/STERN-1/hw_IO_manager1.py
from tkinter import *
from time import time
from tkinter import TclError # Import TclError for specific exception handling
# Import the new XYPlotter
from XY_plotter import XYPlotter

class DeviceIO():
    # Add 'xy_plotter' to the __init__ signature
    def __init__(self, myASCII, interrupts, vdisk, plotter, xy_plotter, sio, width, height, memory, scale=10): # <-- Add xy_plotter
        self.ASCII = myASCII
        self.int = interrupts
        self.vdisk = vdisk
        self.plotter = plotter # Existing plotter (PlotterOptimized)
        self.xy_plotter = xy_plotter # <-- Store the new XYPlotter instance
        self.sio = sio
        self.width = width
        self.height = height
        self.scale = scale
        self.memory = memory
        self.videoadres = self.memory.MEMmax() - (self.width * self.height) + 1

        self.display = Tk()
        self.display.title("STERN I")
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
                self.chars[(x, y)] = None

        self._running = True
        self.my_tasks()

    def _on_closing(self):
        """Handles the Tkinter window close button."""
        print("Tkinter window closing...")
        self._running = False
        # Close both plotters if they exist
        if self.plotter:
            try:
                self.plotter._close_plot()
            except Exception as e:
                print(f"Error closing standard plotter: {e}")
        if self.xy_plotter: # <-- Add closing for xy_plotter
            try:
                self.xy_plotter._close_plot()
            except Exception as e:
                print(f"Error closing XY plotter: {e}")
        try:
            self.display.destroy()
        except TclError:
             print("Display already destroyed.") # Handle case where destroy might be called twice


    def my_tasks(self):
        """Periodically update screen, disk, plotters, and SIO.""" # <-- Updated docstring
        if not self._running:
            return

        try:
            # Update other components
            self.update_disk()
            self.update_videoMemory()
            self.update_sio()
            self.update_plotter() # <-- Call plotter update method
            self.update_xy_plotter() # <-- Call XY plotter update method

            # Schedule next call
            self.display.after(20, self.my_tasks) # Keep interval consistent

        except Exception as e:
            if isinstance(e, TclError) and "invalid command name" in str(e):
                 print("Tkinter TclError likely due to window closing. Stopping updates.")
                 self._running = False
            else:
                 print(f"Error in update loop: {e}")
                 # Decide if you want to stop on other errors
                 # self._running = False
            if not self._running:
                return

    def update_videoMemory(self):
        if not self.memory: return
        try:
            # Check if display still exists before memory access tied to drawing
            if not self.display.winfo_exists():
                self._running = False # Stop if display is gone
                return
            videoMemory = [self.memory.read(self.videoadres + i) for i in range(self.width * self.height)]
            if self.prev_mem != videoMemory:
                self.draw_screen(videoMemory)
                self.prev_mem = videoMemory
        except TclError: # Catch Tkinter errors specifically if display is destroyed mid-operation
            print("TclError during video memory update (likely window closed).")
            self._running = False
        except Exception as e:
            print(f"Error reading/drawing video memory: {e}")
            # self._running = False # Optionally stop on memory errors

    def update_disk(self):
        if not self.vdisk: return
        try:
            self.vdisk.access()
        except Exception as e:
            print(f"Error accessing virtual disk: {e}")

    def update_sio(self):
        """Calls the SIO device's IO method."""
        if not self.sio: return
        try:
            self.sio.IO()
        except Exception as e:
            print(f"Error accessing serial IO: {e}")

    # --- Method to update the standard plotter ---
    def update_plotter(self):
        """Calls the standard plotter's update method."""
        if not self.plotter: return
        try:
            self.plotter.plot_update()
        except Exception as e:
            print(f"Error updating standard plotter: {e}")
            # Optionally disable plotter on error: self.plotter = None

    # --- Add method to update the XY Plotter ---
    def update_xy_plotter(self):
        """Calls the XY plotter's update method."""
        if not self.xy_plotter: return
        try:
            self.xy_plotter.plot_update()
        except Exception as e:
            print(f"Error updating XY plotter: {e}")
            # Optionally disable plotter on error: self.xy_plotter = None
    # --- End Add ---

    def draw_screen(self, memory):
        # Check if canvas exists at the beginning
        if not self._running or not hasattr(self.canvas, 'winfo_exists') or not self.canvas.winfo_exists():
             return

        mem_pointer = 0
        changes = []
        for y in range(self.height):
            for x in range(self.width):
                # Ensure mem_pointer stays within bounds
                if mem_pointer >= len(memory):
                    print(f"Warning: mem_pointer ({mem_pointer}) out of bounds for memory length ({len(memory)}).")
                    break # Stop processing this row

                mem_val = memory[mem_pointer]
                try:
                    index = int(mem_val)
                except ValueError:
                    # Use '?' or null for invalid data, ensure ASCII dict exists
                    index = self.ASCII.get('?', 0) if self.ASCII else 0

                # Find character, default to '?' if not found or invalid index
                char = '?' # Default character
                if self.ASCII:
                    char = next((k for k, v in self.ASCII.items() if v == index), '?')

                # Handle specific non-printable chars if needed
                if char == "space":
                    char = " "
                elif index == 0: # Handle null character
                    char = ""

                current_char = self.char_map.get((x, y))
                if current_char != char:
                    changes.append((x, y, char))
                mem_pointer += 1
            if mem_pointer >= len(memory): # Check again after finishing a row
                 break

        # Apply batched changes
        for x, y, char in changes:
             # Check again before each canvas operation
            if not self._running or not hasattr(self.canvas, 'winfo_exists') or not self.canvas.winfo_exists():
                break

            old_id = self.chars.get((x, y))
            if old_id:
                try:
                    self.canvas.delete(old_id)
                except TclError:
                    pass # Item might already be gone if window closed rapidly

            # Create new text element only if char is not empty
            if char:
                try:
                    font_size = max(1, self.scale - 1)
                    new_id = self.canvas.create_text(
                        (x * self.scale + self.scale // 2, y * self.scale + self.scale // 2),
                        text=char,
                        fill="white",
                        anchor=CENTER,
                        font=("Courier", font_size)
                    )
                    self.chars[(x, y)] = new_id
                except TclError:
                     pass # Canvas might be destroyed
            else:
                 self.chars[(x, y)] = None

            self.char_map[(x, y)] = char


    def key_pressed(self, event):
        if not self._running: return

        value = -1
        key_name = None

        # Check if ASCII map exists
        if not self.ASCII:
            print("Warning: ASCII map not available in key_pressed.")
            return

        if event.keysym in self.ASCII:
            key_name = event.keysym
            value = self.ASCII[key_name]
            if key_name == "Return":
                try:
                    # Check if input_bar still exists
                    if self.input_bar.winfo_exists():
                        self.input_var.set("")
                except TclError:
                    pass # Input bar might be gone
        elif event.char and event.char in self.ASCII:
             key_name = event.char
             value = self.ASCII[key_name]

        if value != -1:
            # Check if interrupt handler exists
            if self.int:
                self.int.interrupt(0, value) # Assuming interrupt 0 is keyboard
            else:
                print("Warning: Interrupt handler not available.")
        else:
            # print(f"Unknown key pressed: char='{event.char}', keysym='{event.keysym}'")
            pass

