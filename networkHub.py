from time import sleep

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
            # check if the input queue not empty
            # read a message from the input queue (destination, source, value)
            # reads message and place (source, value) on destinations putput queue
 
            if self.input_queue.qsize() > 0:
                message = self.input_queue.pop(0)
                if message[0] < self.max_connection:
                    self.output_queues[message[0]].append((message[1], message[2]))
                else:
                    # print warning and continue
                    print("WARING: destination out of range", message[0])
            # else: 
            #     print("Input queue is empty. Waiting for messages...")
            sleep(0.5)

    def stop(self):
        self.running = False