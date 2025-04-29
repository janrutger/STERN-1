# xy_plotter.py (New file or add to plotter_optimized.py)
import matplotlib.pyplot as plt
import numpy as np # Needed for efficient scatter plot updates
from time import time

class XYPlotter:
    """
    Plots X, Y coordinate pairs received sequentially via an SIO channel
    onto a Matplotlib scatter plot with fixed axes.
    """
    def __init__(self, sio, channel=1, width=640, height=480, update_interval=5):
        self.sio = sio
        self.channel = channel # SIO Channel to listen on
        self.status = 'offline'

        # --- Plot Configuration ---
        self.plot_width = width
        self.plot_height = height
        self.update_interval = update_interval # Time in seconds between plot redraws

        # --- Data Buffers ---
        # Store all received points to display
        self.x_buffer = []
        self.y_buffer = []
        self.pending_x = None # Temporarily store X value while waiting for Y
        self.plotted_points = set() # keep track of the already plottet pixels


        # --- Timing and State ---
        self.last_update_time = 0
        self.new_data_received = False # Flag to indicate a new point is ready

        # --- Matplotlib Objects ---
        self.fig = None
        self.ax = None
        self.scatter = None # Store the scatter plot object

        print(f"XY Plotter initialized (Offline). Waiting for channel {self.channel} activation.")

    def _initialize_plot(self):
        """Initializes the Matplotlib figure, axes, and scatter plot."""
        if self.fig is None:
            try:
                print(f"Initializing XY plotter window (Channel {self.channel})...")
                plt.ion() # Turn on interactive mode
                self.fig, self.ax = plt.subplots(figsize=(8, 6)) # Adjust figsize as needed

                # --- Optional: Remove Toolbar ---
                if self.fig.canvas.manager.toolmanager:
                    self.fig.canvas.manager.toolmanager.remove_tool("navigation")
                elif self.fig.canvas.manager.toolbar:
                    self.fig.canvas.manager.toolbar.pack_forget()
                # --- End Remove ---

                # Create an empty scatter plot object and store it
                # Use small markers '.' for pixels, adjust size 's'
                self.scatter = self.ax.scatter([], [], s=1, marker='.', c='blue')

                self.ax.set_title(f"XY Plotter (Channel {self.channel})")
                self.ax.set_xlabel("X Coordinate")
                self.ax.set_ylabel("Y Coordinate")

                # --- Set Fixed Axes Limits ---
                # Add a small margin if desired, e.g., 5%
                margin_x = self.plot_width * 0.05
                margin_y = self.plot_height * 0.05
                self.ax.set_xlim(-margin_x, self.plot_width + margin_x)
                self.ax.set_ylim(-margin_y, self.plot_height + margin_y)
                # Or set exactly:
                # self.ax.set_xlim(0, self.plot_width)
                # self.ax.set_ylim(0, self.plot_height)

                # Ensure aspect ratio is equal if needed (pixels are square)
                self.ax.set_aspect('equal', adjustable='box')

                # Show non-blocking
                if hasattr(self.fig.canvas.manager, 'show'):
                     self.fig.canvas.manager.show()
                else:
                     plt.show(block=False)

                self.fig.canvas.draw_idle()
                self.fig.canvas.flush_events()

                # Reset buffers and state
                self.x_buffer.clear()
                self.y_buffer.clear()
                self.plotted_points.clear() # Add this line
                self.pending_x = None
                self.last_update_time = time()
                print("XY Plotter window initialized.")
                return True
            except Exception as e:
                print(f"Error initializing XY plot: {e}")
                self._close_plot() # Ensure cleanup on failure
                return False
        return True # Already initialized

    def _close_plot(self):
        """Closes the Matplotlib plot window and resets state."""
        if self.fig is not None:
            print(f"Closing XY plotter window (Channel {self.channel})...")
            try:
                plt.close(self.fig)
            except Exception as e:
                print(f"Error closing XY plot: {e}")
            finally:
                self.fig = None
                self.ax = None
                self.scatter = None
                self.x_buffer.clear()
                self.y_buffer.clear()
                self.plotted_points.clear() # Add this line
                self.pending_x = None
                # Don't reset status here, plot_update handles transitions

    def _redraw_plot(self):
        """Updates the scatter plot data and redraws the canvas."""
        if self.fig and self.ax and self.scatter and self.x_buffer:
            try:
                # --- Update Scatter Plot Data ---
                # Combine x and y buffers into a 2D array of coordinates
                # This is the efficient way to update scatter plots
                offsets = np.c_[self.x_buffer, self.y_buffer]
                self.scatter.set_offsets(offsets)

                # --- Adjust Limits (Optional) ---
                # If you want the plot to zoom dynamically (not usually desired for fixed size)
                # self.ax.relim()
                # self.ax.autoscale_view(True, True, True)
                # --- End Optional Adjust ---

                # Redraw efficiently
                self.fig.canvas.draw_idle()
                self.fig.canvas.flush_events()
                self.last_update_time = time()
                # print(f"XY Redraw done at {self.last_update_time}") # Debug
            except Exception as e:
                print(f"Error during XY plot redraw: {e}")
                # traceback.print_exc()
                # If redraw fails, go offline and attempt cleanup
                self.status = 'offline'
                self._close_plot()

    def plot_update(self):
        """Checks channel status, reads X/Y pairs, and updates the plot."""
        try:
            # --- Status Check ---
            is_channel_active = self.sio.check_channel(self.channel)

            # Transition: Offline -> Online
            if is_channel_active and self.status == 'offline':
                print(f"XY Plotter channel {self.channel} opened, going online...")
                if self._initialize_plot():
                    self.status = 'online'
                    self.sio.set_idle() # Signal SIO ready if needed
                else:
                    print("Failed to initialize XY plot, staying offline.")
                    self.status = 'offline' # Stay offline if init fails

            # Transition: Online -> Offline
            elif not is_channel_active and self.status == 'online':
                print(f"XY Plotter channel {self.channel} closed, going offline...")
                # Perform final redraw BEFORE closing
                if self.new_data_received: # Only redraw if there was pending data
                     print("Attempting final XY plot update before closing...")
                     self._redraw_plot()
                self.status = 'offline'
                self._close_plot() # Close window and clean up

            # --- Online Operation ---
            elif self.status == 'online':
                # Double-check plot objects are valid
                if self.fig is None or self.ax is None or self.scatter is None:
                    print("XY Plotter online, but plot objects missing. Reinitializing.")
                    if not self._initialize_plot():
                        print("Reinitialization failed. Going offline.")
                        self.status = 'offline'
                        return # Exit if reinitialization fails

                # Check if the window was manually closed
                if not plt.fignum_exists(self.fig.number):
                    print("XY Plotter window was closed manually. Going offline.")
                    self.status = 'offline'
                    self._close_plot() # Clean up internal state
                    return

                # --- Read X/Y Data Pairs ---
                while True:
                    data = self.sio.read_channel(self.channel)
                    # Inside the while loop after getting 'data'
                    if data is not None:
                        try:
                            value = int(data)
                            if self.pending_x is None:
                                self.pending_x = value
                            else:
                                # We have a complete pair (self.pending_x, value)
                                current_point = (self.pending_x, value) # Create a tuple

                                # *** Check if the point is already plotted ***
                                if current_point not in self.plotted_points:
                                    # Only append and add to set if it's new
                                    self.x_buffer.append(self.pending_x)
                                    self.y_buffer.append(value)
                                    self.plotted_points.add(current_point) # Add to the set
                                    self.new_data_received = True
                                    # print(f"Received NEW point: {current_point}") # Debug
                                # else:
                                #     print(f"Skipping duplicate point: {current_point}") # Debug

                                self.pending_x = None # Reset for the next X
                        except ValueError:
                            print(f"Warning: Received non-integer data '{data}' on channel {self.channel}. Skipping.")
                            self.pending_x = None
                    else:
                        break

                # --- End Data Reading ---

                # --- Efficient Plot Update ---
                current_time = time()
                # Update only if new points were added AND enough time has passed
                if self.new_data_received and (current_time - self.last_update_time > self.update_interval):
                    self._redraw_plot()
                    self.new_data_received = False # Reset flag after redraw
                # else:
                #     print(self.new_data_received)

        except Exception as e:
            print(f"Error during XY plotter update: {e}")
            # traceback.print_exc() # Uncomment for full trace
            self.status = 'offline'
            self._close_plot() # Attempt cleanup

