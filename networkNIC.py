# create an virtial networkcard for the stern
import queue # For queue.Empty exception
# Like orther devices of the Stern-1 it works with Memory mapped IO

# when the host want to send
#   write value to data_out_register
#   write destination to dst_register
#   Knows the source adres
#   write command is send
# the NIC places outgoig message on the send queue, format:(destination, source, value)

# when a message receives, format :(source, value)
# The NIC checks if the receive queue not empty
# when not empty:
#   if receive_status = "idle" (0)
#   write source to src_register
#   write value to data_in_register
#   sets receive_status = "waiting" (1)
#
#   the CPU is checking the receive_status
#   if receive_status = "waiting" (1)
#   CPU reads (or can read) the src_ and data_in_ register
#       do something usefull
#   sets receive_status to "idle" (0)
#    

# --- Status Constants ---
NIC_STATUS_IDLE = 0
NIC_STATUS_SEND_REQUEST = 1 # Host wants to send
NIC_STATUS_DATA_WAITING = 1 # Data has arrived for host
# --- Interrupt Number ---
NIC_RX_INTERRUPT_NUM = 9 # Example interrupt number for Receive Ready
# --- End Status Constants ---

class VirtualNIC:
    def __init__(self, instance_id, MainMem, BaseAdres, send_queue, receive_queue, interrupts):
        self.mainmem = MainMem 
        self.send_queue = send_queue
        self.receive_queue = receive_queue
        self.instance_id = instance_id # The NIC needs to know its own address
        self.interrupts = interrupts   # Store the interrupt controller object

        # set the device registers
        self.receive_status_register = BaseAdres
        self.src_register = BaseAdres + 1
        self.data_in_register = BaseAdres + 2

        self.send_status_register = BaseAdres + 3
        self.dst_register = BaseAdres + 4
        self.data_out_register = BaseAdres + 5

        # Initialize status registers to IDLE
        self.mainmem.write(self.receive_status_register, NIC_STATUS_IDLE)
        self.mainmem.write(self.send_status_register, NIC_STATUS_IDLE)


    def update(self):
        # each update (every 20ms) had to:
        # read the device registers
        receive_status = int(self.mainmem.read(self.receive_status_register))
        send_status = int(self.mainmem.read(self.send_status_register))
        # src = int(self.mainmem.read(self.src_register)) # Only relevant for host reading incoming
        # data_in = int(self.mainmem.read(self.data_in_register)) # Only relevant for host reading incoming
        dst = int(self.mainmem.read(self.dst_register))
        data_out = int(self.mainmem.read(self.data_out_register))

        
        # --- Handle Sending ---
        # Check if the host has requested a send
        if send_status == NIC_STATUS_SEND_REQUEST:
            # Use the NIC's own instance_id as the source
            message = (dst, self.instance_id, data_out)
            # Use put() for multiprocessing.Queue
            self.send_queue.put(message)
            # Signal host that send is complete (or queued)
            self.mainmem.write(self.send_status_register, str(NIC_STATUS_IDLE))
            print("NIC ", self.instance_id, " sent message:", message)
            
        # --- Handle Receiving ---
        # Check if the NIC is idle (ready for new data) AND if data is available in the queue
        if receive_status == NIC_STATUS_IDLE:
            try:
                # Try to get data without blocking
                source, value = self.receive_queue.get_nowait() # Use get_nowait()
                self.mainmem.write(self.src_register, str(source)) # Write source address for host
                self.mainmem.write(self.data_in_register, str(value)) # Write data for host
                self.mainmem.write(self.receive_status_register, NIC_STATUS_DATA_WAITING) # Signal host data is ready
                # Trigger the interrupt *after* data is ready and status is set
                self.interrupts.interrupt(NIC_RX_INTERRUPT_NUM, 0) # Value 0, could be used later if needed
                print("NIC ", self.instance_id, " received message:", (source, value))
            except queue.Empty:
                pass # No data currently in queue, NIC remains idle
        # NOTE: Do NOT reset receive_status here. The CPU must do that after reading.