# /home/janrutger/git/STERN-1/plotter2.py
import matplotlib.pyplot as plt
from time import sleep, time

class Plotter:
    def __init__(self, sio) -> None:
        self.sio = sio
        self.channel = 0
        self.status = 'offline'
        # Buffers for batch plotting
        self.x_buffer = []
        self.y_buffer = []
        self.last_update_time = 0
        self.update_interval = 1 # Redraw every 10ms

        # --- ADD A PERSISTENT COUNTER ---
        self.sample_count = 0

        self.fig = None
        self.ax = None
        print("Plotter initialized (Offline). Waiting for channel 0 activation.")

    def _initialize_plot(self):
        """Initializes the matplotlib figure and axes."""
        if self.fig is None:
            try:
                print("Initializing plotter window...")
                plt.ion()
                self.fig, self.ax = plt.subplots(figsize=(8, 5))
                if self.fig.canvas.manager.toolmanager:
                     self.fig.canvas.manager.toolmanager.remove_tool("navigation")
                elif self.fig.canvas.manager.toolbar:
                     self.fig.canvas.manager.toolbar.pack_forget()

                self.ax.set_title(f"Serial Plotter (Channel {self.channel})")
                self.ax.set_xlabel("Sample Index")
                self.ax.set_ylabel("Value")
                self.fig.canvas.manager.show()
                self.fig.canvas.draw_idle()
                self.fig.canvas.flush_events()
                self.x_buffer = []
                self.y_buffer = []
                self.last_update_time = time()
                # --- RESET COUNTER ON NEW PLOT ---
                self.sample_count = 0
                print("Plotter window initialized.")
                return True
            except Exception as e:
                print(f"Error initializing plot: {e}")
                self.fig = None
                return False
        return True

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
                self.x_buffer = []
                self.y_buffer = []
                # --- RESET COUNTER ON CLOSE ---
                self.sample_count = 0

    def plot_update(self):
        """Checks channel status and updates the plot using batching."""
        try:
            is_channel_active = self.sio.check_channel(self.channel)

            # (Status change logic remains the same)
            if is_channel_active and self.status == 'offline':
                print(f"Plotter channel {self.channel} opened, going online...")
                if self._initialize_plot():
                    self.status = 'online'
                    self.sio.set_idle()
                else:
                    print("Failed to initialize plot, staying offline.")

            elif not is_channel_active and self.status == 'online':
                print(f"Plotter channel {self.channel} closed, going offline...")
                self.status = 'offline'
                self._close_plot()

            elif self.status == 'online':
                if self.fig is None or self.ax is None:
                    print("Plotter online, but figure/axis missing. Reinitializing.")
                    if not self._initialize_plot():
                        print("Reinitialization failed. Going offline.")
                        self.status = 'offline'
                        return

                if not plt.fignum_exists(self.fig.number):
                     print("Plotter window was closed manually. Going offline.")
                     self.status = 'offline'
                     self._close_plot()
                     return

                # --- Batch Read Data ---
                if not self.x_buffer:
                    new_data_received = False
                else:
                    new_data_received = True

                # No need for start_index anymore if using the persistent counter

                while True:
                    data = self.sio.read_channel(self.channel)
                    if data is not None:
                        # --- USE AND INCREMENT THE PERSISTENT COUNTER ---
                        self.x_buffer.append(self.sample_count)
                        self.y_buffer.append(data)
                        self.sample_count += 1 # Increment for the next sample
                        # --- END CHANGE ---
                        #new_data_received = True
                    else:
                        break # No more data

                # --- Batch Plot and Redraw ---
                current_time = time()
                if new_data_received and (current_time - self.last_update_time > self.update_interval):
                    if self.x_buffer:
                        # print(f"Plotting batch up to sample {self.sample_count-1}")
                        self.ax.scatter(self.x_buffer, self.y_buffer, s=10, c='blue')

                        # --- IMPORTANT: Auto-scaling is needed now ---
                        #self.ax.relim() # Recalculate limits based on ALL data (including previous batches if not clearing plot)
                        #self.ax.autoscale_view(True, True, True) # Rescale axes to show new points

                        self.fig.canvas.draw_idle()
                        self.fig.canvas.flush_events()
                        self.last_update_time = current_time

                        # --- Clear buffers for the *next* batch ---
                        # This is still good practice for performance.
                        # We are plotting only the *new* points collected since the last update,
                        # but their x-values are now continuous.
                        self.x_buffer = []
                        self.y_buffer = []

        except Exception as e:
            print(f"Error during plotter update: {e}")
            self.status = 'offline'
            self._close_plot()

