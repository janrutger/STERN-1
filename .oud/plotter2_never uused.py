# /home/janrutger/git/STERN-1/plotter.py
import matplotlib.pyplot as plt
from time import sleep

# It's often better to call plt.ion() once globally if needed,
# but managing within the update loop can also work.
# plt.ion() # Enable interactive mode

class Plotter:
    def __init__(self, sio) -> None:
        self.sio = sio
        self.channel = 0  # Assuming plotter uses channel 0
        self.status = 'offline'
        self.x_ax = 0
        self.fig = None
        self.ax = None
        print("Plotter initialized (Offline). Waiting for channel 0 activation.")

    def _initialize_plot(self):
        """Initializes the matplotlib figure and axes."""
        if self.fig is None:
            try:
                print("Initializing plotter window...")
                plt.ion() # Ensure interactive mode is on for this figure
                self.fig, self.ax = plt.subplots(figsize=(8, 5))
                self.ax.set_title(f"Serial Plotter (Channel {self.channel})")
                self.ax.set_xlabel("Sample Index")
                self.ax.set_ylabel("Value")
                # Show the plot window without blocking the main thread
                self.fig.canvas.manager.show()
                # Force a draw to make sure the window appears
                self.fig.canvas.draw_idle()
                self.fig.canvas.flush_events()
                print("Plotter window initialized.")
                return True
            except Exception as e:
                print(f"Error initializing plot: {e}")
                self.fig = None # Ensure fig is None if init failed
                return False
        return True # Already initialized

    def _close_plot(self):
        """Closes the matplotlib plot window."""
        if self.fig is not None:
            print("Closing plotter window...")
            try:
                plt.close(self.fig)
            except Exception as e:
                print(f"Error closing plot: {e}")
            finally:
                self.fig = None
                self.ax = None
                self.x_ax = 0 # Reset x-axis

    def plot_update(self):
        """Checks channel status and updates the plot accordingly. Should be called periodically."""
        try:
            is_channel_active = self.sio.check_channel(self.channel)

            if is_channel_active and self.status == 'offline':
                # Channel just opened
                print(f"Plotter channel {self.channel} opened, going online...")
                if self._initialize_plot():
                    self.status = 'online'
                    self.sio.set_idle() # Signal ready in the simulation
                else:
                    print("Failed to initialize plot, staying offline.")
                    # Optionally set error status in SIO if needed

            elif not is_channel_active and self.status == 'online':
                # Channel just closed
                print(f"Plotter channel {self.channel} closed, going offline...")
                self.status = 'offline'
                self._close_plot()
                # CPU simulation should handle the close command; plotter just reacts.

            elif self.status == 'online':
                # Plotter is active, check for data
                if self.fig is None or self.ax is None:
                    print("Plotter online, but figure/axis is missing. Attempting reinitialization.")
                    if not self._initialize_plot():
                        print("Reinitialization failed. Going offline.")
                        self.status = 'offline'
                        return # Exit update if plot cannot be shown

                # Check if the figure window still exists
                if not plt.fignum_exists(self.fig.number):
                     print("Plotter window was closed manually. Going offline.")
                     self.status = 'offline'
                     self.fig = None # Clear references
                     self.ax = None
                     self.x_ax = 0
                     # Optionally inform the simulation if needed (e.g., set SIO error)
                     return


                data = self.sio.read_channel(self.channel)
                if data is not None:
                    # print(f"Plotting data: x={self.x_ax}, y={data}")
                    self.ax.scatter(self.x_ax, data, s=10, c='blue')
                    self.x_ax += 1
                    # Optional: Adjust view limits automatically
                    # self.ax.relim()
                    # self.ax.autoscale_view(True, True, True)

                    # Redraw the canvas using idle_draw for better integration
                    self.fig.canvas.draw_idle()
                    # Process events to update the window (important!)
                    self.fig.canvas.flush_events()
                    # print("Plot updated.")

            # else: plotter is offline and channel is inactive - do nothing

        except Exception as e:
            print(f"Error during plotter update: {e}")
            # Decide how to handle errors, e.g., go offline
            self.status = 'offline'
            self._close_plot()

