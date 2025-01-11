from tkinter import *

class Display():
    def __init__(self, width, height, memory, scale=10):
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


        self.update_videoMemory()

    def update_videoMemory(self):
        videoMemory = [self.memory.read(self.videoadres + i) for i in range(self.width * self.height)]
        self.draw_screen(videoMemory)
        self.display.after(20, self.update_videoMemory)  # Reduced delay for smoother updates
        
    def draw_pixel(self, x, y, s):
        x1 =  x * self.scale
        y1 =  y * self.scale 
        x2 = x1 + self.scale
        y2 = y1 + self.scale

        if s == "1":
            self.canvas.create_rectangle(x1, y1, x2, y2, fill="gray")
        elif s == "0":
            self.canvas.create_rectangle(x1, y1, x2, y2, fill="lightgray")
        else:
            self.canvas.create_rectangle(x1, y1, x2, y2, fill="black")

    def draw_screen(self, memory):
        mem_pointer = 0
        for y in range(self.height):
            for x in range(self.width):
                self.draw_pixel(x, y, memory[mem_pointer])
                mem_pointer += 1
        self.display.update_idletasks()
        self.display.update()