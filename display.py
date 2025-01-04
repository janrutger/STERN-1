from tkinter import *

class Display():
    def __init__(self, width, height, memory, scale=10):
        self.width = width
        self.height = height
        self.scale = scale
        self.memory = memory
        self.videoadres = self.memory.MEMmax() - (self.width * self.height) + 1

        self.display = Tk()
        self.canvas = Canvas(self.display, width=self.width * self.scale, height=self.height * self.scale)
        self.canvas.pack()
        self.canvas.config(bg="black")

        self.rectangles = [[self.canvas.create_rectangle(
            x * self.scale, y * self.scale, 
            (x + 1) * self.scale, (y + 1) * self.scale, 
            fill="black") for x in range(self.width)] for y in range(self.height)]

        self.update_videoMemory()

    def update_videoMemory(self):
        videoMemory = [self.memory.read(self.videoadres + i) for i in range(self.width * self.height)]
        self.draw_screen(videoMemory)
        self.display.after(5000, self.update_videoMemory)  # Reduced delay for smoother updates

    def draw_pixel(self, x, y, s):
        color = "white" if s == 1 else "black"
        self.canvas.itemconfig(self.rectangles[y][x], fill=color)

    def draw_screen(self, memory):
        mem_pointer = 0
        print("Drawscreen")
        for y in range(self.height):
            for x in range(self.width):
                self.draw_pixel(x, y, memory[mem_pointer])
                mem_pointer += 1
        self.display.update()