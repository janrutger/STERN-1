import tkinter as tk
from tkinter import ttk
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.backends.backend_tkagg import NavigationToolbar2Tk

root = tk.Tk()
root.title("Main Window")

def open_plot_window():
    # Create a new Toplevel window
    plot_window = tk.Toplevel(root)
    plot_window.title("Second Window with Plot")

    # Create a Matplotlib figure and axes
    fig, ax = plt.subplots()

    # Example plot (you can customize this)
    x = [1, 2, 3, 4, 5]
    y = [2, 4, 1, 5, 3]
    ax.plot(x, y)
    ax.set_xlabel("X-axis")
    ax.set_ylabel("Y-axis")
    ax.set_title("Example Plot")

    # Create a Tkinter canvas to embed the Matplotlib figure
    canvas = FigureCanvasTkAgg(fig, master=plot_window)
    canvas_widget = canvas.get_tk_widget()
    canvas_widget.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

    # Create a navigation toolbar (optional but useful)
    toolbar = NavigationToolbar2Tk(canvas, plot_window)
    toolbar.update()
    canvas_widget.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

    canvas.draw()

open_button = ttk.Button(root, text="Open Plot Window", command=open_plot_window)
open_button.pack(pady=20)

root.mainloop()