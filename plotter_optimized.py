# /home/janrutger/git/STERN-1/plotter_optimized.py
import matplotlib.pyplot as plt
from time import time
from collections import deque # Use deque for efficient fixed-size buffer

class PlotterOptimized:
    def __init__(self, sio, max_points=1024, update_interval=2) -> None: # Reduced interval
        self.sio = sio
        self.channel = 0
        self.status = 'offline'

        # Use deque for efficient appends and pops from both ends
        self.max_points = max_points
        self.x_buffer = deque(maxlen=max_points)
        self.y_buffer = deque(maxlen=max_points)

        self.last_update_time = 0
        self.update_interval = update_interval # Update more frequently if faster

        self.sample_count = 0 # Keep track of total samples for x-axis
        self.new_data_received = False # Flag to indicate new data

        self.fig = None
        self.ax = None
        self.line = None # Store the plot line object
        print("Optimized Plotter initialized (Offline). Waiting for channel 0 activation.")

    def _initialize_plot(self):
        """Initializes the matplotlib figure, axes, and line object."""
        if self.fig is None:
            try:
                print("Initializing optimized plotter window...")
                plt.ion() # Turn on interactive mode
                self.fig, self.ax = plt.subplots(figsize=(8, 5))

                # --- Remove Toolbar/Navigation (Optional) ---
                if self.fig.canvas.manager.toolmanager:
                    self.fig.canvas.manager.toolmanager.remove_tool("navigation")
                elif self.fig.canvas.manager.toolbar:
                    self.fig.canvas.manager.toolbar.pack_forget()
                # --- End Remove ---

                # Create an empty line object and store it
                # 'o' for circle markers, adjust markersize as needed
                self.line, = self.ax.plot([], [], 'o', color='blue', markersize=2) # Note the comma!

                self.ax.set_title(f"Serial Plotter (Channel {self.channel})")
                self.ax.set_xlabel("Sample Index")
                self.ax.set_ylabel("Value")

                # Use non-blocking show if available, or standard show
                if hasattr(self.fig.canvas.manager, 'show'):
                     self.fig.canvas.manager.show()
                else:
                     plt.show(block=False) # Fallback for some backends

                self.fig.canvas.draw_idle() # Initial draw
                self.fig.canvas.flush_events() # Process events

                # Reset buffers and counter
                self.x_buffer.clear()
                self.y_buffer.clear()
                self.sample_count = 0
                self.last_update_time = time()
                print("Optimized Plotter window initialized.")
                return True
            except Exception as e:
                print(f"Error initializing plot: {e}")
                #traceback.print_exc() # Print full traceback
                self.fig = None
                self.ax = None # Ensure ax is also cleared
                self.line = None
                return False
        return True # Return True if fig already exists

    def _close_plot(self):
        """Closes the matplotlib plot window."""
        if self.fig is not None:
            print("Closing plotter window...")
            try:
                plt.close(self.fig)
            except Exception as e:
                print(f"Error closing plot: {e}")
            finally:
                # Ensure all plot-related attributes are reset
                self.fig = None
                self.ax = None
                self.line = None
                self.x_buffer.clear()
                self.y_buffer.clear()
                self.sample_count = 0 # Reset counter

    def _redraw_plot(self):
        """Helper function to update the plot line data and redraw the canvas."""
        # Check if plot elements exist and there's data to plot
        if self.fig and self.ax and self.line and self.x_buffer:
            try:
                # Update the existing line's data (MUCH FASTER than clearing/replotting)
                # Convert deques to lists for set_data
                self.line.set_data(list(self.x_buffer), list(self.y_buffer))

                # Adjust plot limits efficiently
                self.ax.relim() # Recalculate data limits based on the *current* line data
                self.ax.autoscale_view(True, True, True) # Rescale axes based on new limits

                # Redraw only the necessary parts of the canvas
                self.fig.canvas.draw_idle()
                self.fig.canvas.flush_events() # Process the draw events
                self.last_update_time = time() # Update time after redraw
                # print(f"Redraw done at {self.last_update_time}") # Debug print
            except Exception as e:
                # Handle potential errors during redraw (e.g., window closed unexpectedly)
                print(f"Error during plot redraw: {e}")
                # If redraw fails, it's safer to go offline and attempt cleanup
                self.status = 'offline'
                self._close_plot()

    def plot_update(self):
        """Checks channel status and updates the plot efficiently."""
        try:
            # --- Status Check ---
            is_channel_active = self.sio.check_channel(self.channel)

            # Transition from offline to online
            if is_channel_active and self.status == 'offline':
                print(f"Plotter channel {self.channel} opened, going online...")
                if self._initialize_plot():
                    self.status = 'online'
                    self.sio.set_idle() # Signal SIO device if needed
                else:
                    print("Failed to initialize plot, staying offline.")
                    self.status = 'offline' # Ensure it stays offline if init fails

            # Transition from online to offline
            elif not is_channel_active and self.status == 'online':
                print(f"Plotter channel {self.channel} closed, going offline...")
                # --- Perform final redraw BEFORE closing --- # <<< FIX
                print("Attempting final plot update before closing...")
                self._redraw_plot() # Draw whatever is left in the buffer
                # --- End final redraw ---
                self.status = 'offline' # Set status after final plot attempt
                self._close_plot() # Now close the plot window and clean up

            # --- End Status Check ---

            # Currently online and active
            elif self.status == 'online':
                # --- Ensure Plot Exists ---
                # Double-check if plot objects are still valid (e.g., wasn't closed unexpectedly)
                if self.fig is None or self.ax is None or self.line is None:
                    print("Plotter online, but figure/axis/line missing. Reinitializing.")
                    if not self._initialize_plot():
                        print("Reinitialization failed. Going offline.")
                        self.status = 'offline'
                        # Don't call _close_plot here, it's already handled by _initialize_plot failure
                        return # Exit if reinitialization fails

                # Check if the window was manually closed by the user
                # plt.fignum_exists requires the figure number
                if not plt.fignum_exists(self.fig.number):
                    print("Plotter window was closed manually. Going offline.")
                    self.status = 'offline'
                    self._close_plot() # Clean up internal state
                    return
                # --- End Ensure Plot Exists ---

                # --- Batch Read Data ---
                while True:
                    data = self.sio.read_channel(self.channel)
                    if data is not None:
                        # Append new data point using the persistent sample counter
                        self.x_buffer.append(self.sample_count)
                        self.y_buffer.append(data)
                        self.sample_count += 1
                        self.new_data_received = True # Set flag ONLY if data was read
                    else:
                        break # No more data available in the channel for now
                # --- End Batch Read Data ---

                # --- Efficient Plot Update (based on interval AND new data) ---
                current_time = time()

                if self.new_data_received and (current_time - self.last_update_time > self.update_interval):
                    self._redraw_plot()
                    self.new_data_received = False # Reset flag after redraw
                # else:
                #     print(self.new_data_received )
                # --- End Efficient Plot Update ---

        except Exception as e:
            # Catch-all for unexpected errors during the update process
            print(f"Error during plotter update: {e}")
            self.status = 'offline' # Go offline on error
            self._close_plot() # Attempt to close plot window cleanly
