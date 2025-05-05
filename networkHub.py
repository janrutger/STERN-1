import queue # For exception handling if needed
import time 

class NetworkHub:
    def __init__(self, input_queue, output_queues, max_connection):
        self.input_queue = input_queue
        self.output_queues = output_queues
        self.max_connection = max_connection
        self.running = True  

        # incomming message format:(destination, source, value)
        # outgoing message format :(source, value)



    def start(self):
        print("Network Hub started")
        while self.running:
            try:
                # Block until a message is available
                message = self.input_queue.get() # Use get() for multiprocessing.Queue

                # Check for a shutdown signal (optional but good practice)
                if message is None:
                    print("Network Hub received shutdown signal.")
                    break # Exit the loop gracefully

                if message[0] < self.max_connection:
                    self.output_queues[message[0]].append((message[1], message[2]))
                else:
                    # print warning and continue
                    print(f"WARNING: Hub received message for out-of-range destination {message[0]} from {message[1]}")
            except (queue.Empty, EOFError, BrokenPipeError) as e:
                print(f"Network Hub queue error: {e}. Stopping.")
                self.running = False # Stop on queue errors
        time.sleep(0.5)

    def stop(self):
        self.running = False