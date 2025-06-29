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
                # Block with a timeout to allow for graceful shutdown checks
                # and to reduce busy-waiting if the queue is empty for long periods.
                message = self.input_queue.get(block=True, timeout=0.1) # Timeout of 0.1 seconds

                # Check for a shutdown signal (optional but good practice)
                if message is None:
                    print("Network Hub received shutdown signal.")
                    self.running = False # Ensure loop terminates
                    break # Exit the loop gracefully

                # Validate message structure before accessing elements
                if not isinstance(message, (list, tuple)) or len(message) < 3:
                    print(f"HUB: Malformed message received (not a tuple/list of 3+ elements): {message}")
                    continue

                destination_id = message[0]
                source_id = message[1]
                payload = message[2]

                if 0 <= destination_id < self.max_connection:
                    #time.sleep(3)
                    print(f"HUB received message: To {destination_id} From {source_id} Payload {payload}") # Verbose
                    self.output_queues[destination_id].put((source_id, payload))
                else:
                    # print warning and continue
                    print(f"WARNING: Hub received message for out-of-range destination {destination_id} from {source_id}")
            except queue.Empty:
                # This exception is raised if the timeout occurs before a message is available.
                # This is normal and allows the loop to continue, checking self.running.
                # No explicit sleep is needed here as the timeout in get() serves this purpose.
                pass
            except (EOFError, BrokenPipeError) as e:
                print(f"Network Hub queue error: {e}. Stopping.")
                self.running = False # Stop on queue errors
            except IndexError as e:
                # This might occur if a message is not structured as (dst, src, payload)
                # The earlier check for isinstance and len should prevent most of these.
                print(f"Network Hub: Error processing message (IndexError): {message} - {e}. Skipping.")
            except Exception as e: # Catch any other unexpected errors
                print(f"Network Hub: An unexpected error occurred: {e}. Stopping.")
                self.running = False
        print("Network Hub stopped.")

    def stop(self):
        print("Network Hub: stop() called.")
        self.running = False
        # Attempt to unblock the input_queue.get() by putting a sentinel value.
        try:
            self.input_queue.put(None, block=False, timeout=0.1) # Non-blocking put with a short timeout
        except queue.Full:
            print("Network Hub: Input queue full while trying to send stop signal. Hub might take a moment to stop.")
        except Exception as e:
            print(f"Network Hub: Error sending stop signal to input queue: {e}")