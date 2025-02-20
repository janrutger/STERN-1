from tkinter import *
from time import time

class Display():
    def __init__(self, myASCII, interrupts, width, height, memory, scale=10):
        self.ASCII = myASCII
        self.int = interrupts
        self.width = width
        self.height = height
        self.scale = scale
        self.memory = memory
        self.videoadres = self.memory.MEMmax() - (self.width * self.height) + 1

        self.display = Tk()
        self.display.title("STERN I")
        self.canvas = Canvas(self.display, width=self.width * self.scale, height=self.height * self.scale)
        self.canvas.pack()
        self.canvas.config(bg="gray")

        self.input_var = StringVar()
        self.input_bar = Entry(self.display, textvariable=self.input_var, width=16)
        self.input_bar.pack()
        self.input_bar.bind("<Key>", self.key_pressed)

        self.prev_mem = []
        self.pixel_map = {}  # Dictionary to keep track of current pixel states

        # Initialize rectangles
        self.rectangles = {}
        for y in range(self.height):
            for x in range(self.width):
                x1 = x * self.scale
                y1 = y * self.scale
                x2 = x1 + self.scale
                y2 = y1 + self.scale
                rect_id = self.canvas.create_rectangle(x1, y1, x2, y2, fill="gray")
                self.rectangles[(x, y)] = rect_id

        self.update_videoMemory()

    def update_videoMemory(self):
        videoMemory = [self.memory.read(self.videoadres + i) for i in range(self.width * self.height)]
        if self.prev_mem != videoMemory:
            self.draw_screen(videoMemory)
            self.prev_mem = videoMemory
        self.display.after(10, self.update_videoMemory)  # Reduced delay for smoother updates

    def draw_pixel(self, x, y, s):
        color = "gray"  # Default color

        if s == "1":
            color = "white"
        elif s == "0":
            color = "black"

        # Update only if the pixel state has changed
        if (x, y) not in self.pixel_map or self.pixel_map[(x, y)] != color:
            self.canvas.itemconfig(self.rectangles[(x, y)], fill=color)
            self.pixel_map[(x, y)] = color

    def draw_screen(self, memory):
        mem_pointer = 0
        changes = []
        for y in range(self.height):
            for x in range(self.width):
                color = "gray"
                if memory[mem_pointer] == "1":
                    color = "white"
                elif memory[mem_pointer] == "0":
                    color = "black"
                if (x, y) not in self.pixel_map or self.pixel_map[(x, y)] != color:
                    changes.append((x, y, color))
                mem_pointer += 1

        # Apply batched changes
        for x, y, color in changes:
            self.canvas.itemconfig(self.rectangles[(x, y)], fill=color)
            self.pixel_map[(x, y)] = color

        self.display.update_idletasks()
        self.display.update()

    def key_pressed(self, event):
        if event.char in self.ASCII.keys():
            value = self.ASCII[event.char]
            self.int.interrupt(0, value)
        elif event.keysym in self.ASCII.keys():
            value = self.ASCII[event.keysym]
            if event.keysym == "Return":
                self.input_var.set("") #clear imputbox
            self.int.interrupt(0, value)
        else:
            print("Unknown key ", event.keysym)




class CharDisplay():
    def __init__(self, myASCII, interrupts, width, height, memory, scale=10):
        self.ASCII = myASCII
        self.int = interrupts
        self.width = width
        self.height = height
        self.scale = scale
        self.memory = memory
        self.videoadres = self.memory.MEMmax() - (self.width * self.height) + 1

        self.display = Tk()
        self.display.title("STERN I")
        self.canvas = Canvas(self.display, width=self.width * self.scale, height=self.height * self.scale)
        self.canvas.pack()
        self.canvas.config(bg="black")

        self.input_var = StringVar()
        self.input_bar = Entry(self.display, textvariable=self.input_var, width=16)
        self.input_bar.pack()
        self.input_bar.bind("<Key>", self.key_pressed)

        self.prev_mem = []
        self.char_map = {}  # Dictionary to keep track of current char states

        # Initialize characters
        self.chars = {}
        for y in range(self.height):
            for x in range(self.width):
                char_id = self.canvas.create_text((x * self.scale, y * self.scale), text="", fill="white", anchor=NW, font=("Courier", self.scale))
                self.chars[(x, y)] = char_id

        self.update_videoMemory()

    def update_videoMemory(self):
        videoMemory = [self.memory.read(self.videoadres + i) for i in range(self.width * self.height)]
        if self.prev_mem != videoMemory:
            self.draw_screen(videoMemory)
            self.prev_mem = videoMemory
        self.display.after(10, self.update_videoMemory)  # Reduced delay for smoother updates

    def draw_screen(self, memory):
        mem_pointer = 0
        changes = []
        for y in range(self.height):
            for x in range(self.width):
                index = int(memory[mem_pointer])
                char = next((k for k, v in self.ASCII.items() if v == index and (v > 0 and v <= 56)), '#')
                if (x, y) not in self.char_map or self.char_map[(x, y)] != char:
                    if char == "space":
                        char = ""
                    changes.append((x, y, char))
                mem_pointer += 1

        # Apply batched changes
        for x, y, char in changes:
            # Delete previous text element to prevent overwriting characters
            print(f"Deleting item ID: {self.chars.get((x, y), 'None')}")
            id = self.chars[(x, y)]
            self.canvas.delete(id) # Delete the old text object

            # Create new text element, and register new_id
            new_id = self.canvas.create_text((x * self.scale, y * self.scale), text=char, fill="white", anchor=NW, font=("Courier", self.scale))
            self.chars[(x, y)] = new_id

            # register new char
            self.char_map[(x, y)] = char

        #Sself.display.update_idletasks()
        self.display.update()

    def key_pressed(self, event):
        if event.char in self.ASCII.keys():
            value = self.ASCII[event.char]
            self.int.interrupt(0, value)
        elif event.keysym in self.ASCII.keys():
            value = self.ASCII[event.keysym]
            if event.keysym == "Return":
                self.input_var.set("") #clear input box
            self.int.interrupt(0, value)
        else:
            print("Unknown key ", event.keysym)