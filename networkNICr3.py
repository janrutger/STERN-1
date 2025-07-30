# create an virtial networkcard for the stern
import queue # For queue.Empty exception
import time

# --- Protocol Message Types ---
DATA_TYPE = 0
ACK_TYPE  = 1

# --- NIC Status Constants (for CPU communication) ---
NIC_STATUS_IDLE = 0         # NIC can check the incomming queue
NIC_STATUS_SEND_ACK = 2     # Host wants to send an ACK, by NIC and set to NIC_STATUS_IDLE
NIC_STATUS_SEND_REQUEST = 1 # Host wants to send a packet
NIC_STATUS_DATA_WAITING = 1 # Data has arrived and is waiting for the host

# --- ACK Payload Status ---
ACK_STATUS_ACK = 0 # Positive acknowledgment

# --- Network Behavior Configuration ---
RETRANSMISSION_TIMEOUT = 1.0 # Resend a packet if not ACKed within 1.0 seconds

# --- Interrupt Number ---
NIC_RX_INTERRUPT_NUM = 9 # Interrupt for a new, valid data packet received

class VirtualNIC:
    """
    Simulates a reliable, multi-destination Network Interface Card for the STERN-1 computer.

    This virtual hardware component implements a reliable transport protocol using
    packet sequencing, acknowledgments (ACKs), and timeout-based retransmissions.
    It is designed to interface with the STERN-1 CPU via memory-mapped I/O registers
    and interrupts.

    Key Features:
    - Per-Peer State: Manages separate packet sequence numbers for each destination,
      allowing simultaneous reliable communication with multiple peers.
    - Automatic Retransmission: DATA packets sent by the CPU are buffered. If an ACK
      is not received within the RETRANSMISSION_TIMEOUT, the packet is resent.
    - CPU-Driven Acknowledgment: When a valid DATA packet is received, the NIC
      places its details in registers and triggers an interrupt. The CPU's ISR is
      responsible for reading these details and commanding the NIC to send an ACK.
    - Flow Control: The NIC will not process a new incoming packet from the network
      if its internal receive buffer (registers) is still full (i.e., the CPU
      has not cleared the receive status).

    --- Network Message Formats ---

    All messages sent over the network via the NetworkHub have the following
    top-level tuple structure, which is placed on the NIC's `send_queue`:

    `(destination_nic_id, source_nic_id, payload)`

    The `payload` is a tuple whose structure depends on the message type.

    1. DATA Message Payload:
       - Purpose: To transmit application data to a service on a peer.
       - Sent by: A process on the CPU.
       - Structure: `(DATA_TYPE, packet_number, service_id, data_content)`

    2. ACK Message Payload:
       - Purpose: To acknowledge the successful receipt of a DATA packet.
       - Sent by: The receiving NIC's CPU (via an ISR) in response to a DATA packet.
       - Structure: `(ACK_TYPE, packet_number_acked, status)`

    The `receive_queue` from the Hub provides tuples of `(original_sender_id, payload)`.
    """
    def __init__(self, instance_id, MainMem, BaseAdres, send_queue, receive_queue, interrupts):
        self.mainmem = MainMem
        self.send_queue = send_queue
        self.receive_queue = receive_queue
        self.instance_id = instance_id
        self.interrupts = interrupts

        # --- Memory Mapped Registers ---
        # Receive side (NIC -> CPU)
        self.receive_status_register = BaseAdres      # 0
        self.src_register = BaseAdres + 1             # 1
        self.data_in_register = BaseAdres + 2         # 2
        self.packetnumber_in_register = BaseAdres + 3 # 3 - Tells CPU which packet # was received
        self.service_id_in_register = BaseAdres + 4   # 4

        # Send side (CPU -> NIC)
        self.send_status_register = BaseAdres + 5     # 5
        self.dst_register = BaseAdres + 6             # 6
        self.data_out_register = BaseAdres + 7        # 7
        self.ack_status_register = BaseAdres + 8      # 8 - For CPU to specify ACK status
        self.message_type_register = BaseAdres + 9    # 9 - For CPU to specify DATA or ACK
        # NOTE: Address 3 is used for both IN and OUT packet numbers, 
        #       a common hardware pattern.
        self.packetnumber_out_register = BaseAdres + 3 # 3 - For CPU to specify which packet # to ACK
        self.service_id_out_register = BaseAdres + 10  # 10

        # Initialize status registers
        self.mainmem.write(self.receive_status_register, str(NIC_STATUS_IDLE))
        self.mainmem.write(self.send_status_register,    str(NIC_STATUS_IDLE))
        self.mainmem.write(self.message_type_register,   str(DATA_TYPE))
        self.mainmem.write(self.ack_status_register,     str(ACK_STATUS_ACK))

        # --- Per-Peer State Management ---
        # Keeps track of packet numbers for each destination.
        # Format: { peer_id: {'next_packet_to_send': int, 'next_packet_expected': int} }
        self.peer_states = {}

        # --- Resend Buffer for Reliability ---
        # Stores unacknowledged packets for potential retransmission.
        # Key: (destination_id, packet_number) tuple
        # Value: {'hub_message': tuple, 'send_time': float}
        self.resend_buffer = {}

    def _get_or_create_peer_state(self, peer_id):
        """Gets the state for a peer, creating it if it doesn't exist."""
        if peer_id not in self.peer_states:
            self.peer_states[peer_id] = {
                'next_packet_to_send': 0,
                'next_packet_expected': 0
            }
        return self.peer_states[peer_id]

    def update(self):
        """Main update loop for the NIC, called periodically."""
        # --- 1. Check if an ACK message of the previous message must be send ---
        if int(self.mainmem.read(self.receive_status_register)) == NIC_STATUS_SEND_ACK:
            message_type_to_send = ACK_TYPE
            dst_nic_id = int(self.mainmem.read(self.src_register))
            packet_num_to_ack = int(self.mainmem.read(self.packetnumber_out_register))
            ack_status = int(self.mainmem.read(self.ack_status_register))


            # Message format for Hub: (receiver, sender, payload)
            # Payload: (ACK_TYPE, packet_num_, ack_status)
            protocol_payload = (ACK_TYPE, packet_num_to_ack, ack_status)
            hub_message = (dst_nic_id, self.instance_id, protocol_payload)

            self.send_queue.put(hub_message)
            print(f"NIC {self.instance_id}: Sent ACK for packet {packet_num_to_ack} to {dst_nic_id}")
            
            peer_state = self._get_or_create_peer_state(dst_nic_id)
            expected_packet_to_ack = peer_state['next_packet_expected']
            if packet_num_to_ack == expected_packet_to_ack:
                peer_state['next_packet_expected'] += 1 # Only advance on new packets
            
            # Reset receive status to idle
            self.mainmem.write(self.receive_status_register, str(NIC_STATUS_IDLE))


        # --- 2. Handle Incoming Messages from the Hub ---
        # Only try to receive a new packet if the CPU has processed the previous one
        # and the ACK is send
        if int(self.mainmem.read(self.receive_status_register)) == NIC_STATUS_IDLE:
            try:
                # Hub provides (original_sender_id, message_body) on the receive_queue.
                original_sender_id, message_body = self.receive_queue.get_nowait()
                msg_type = message_body[0]

                if msg_type == DATA_TYPE:
                    # Unpack: (DATA, packet_num, service_id, data)
                    _, rcv_packet_num, rcv_service_id, rcv_data = message_body
                    peer_state = self._get_or_create_peer_state(original_sender_id)
                    expected_packet_num = peer_state['next_packet_expected']

                    # --- BEHAVIOR CHANGE: The CPU/ISR is now responsible for sending the ACK ---

                    # The outer 'if' already confirmed the receive buffer is idle.
                    # The ISR will be responseble for set the correct register when
                    # ACK must be send.
                    if rcv_packet_num < expected_packet_num:
                        print(f"NIC {self.instance_id}: Received DUPLICATE DATA packet {rcv_packet_num} from {original_sender_id} ")
                    else: # Correct packet
                        print(f"NIC {self.instance_id}:  Received expected DATA packet {rcv_packet_num} from {original_sender_id}.")

                    
                    self.mainmem.write(self.src_register, str(original_sender_id))
                    self.mainmem.write(self.data_in_register, str(rcv_data))
                    self.mainmem.write(self.service_id_in_register, str(rcv_service_id))
                    self.mainmem.write(self.packetnumber_in_register, str(rcv_packet_num)) # Tell CPU which packet this is
                    self.mainmem.write(self.receive_status_register, str(NIC_STATUS_DATA_WAITING))
                    self.interrupts.interrupt(NIC_RX_INTERRUPT_NUM, expected_packet_num)
                    
                elif msg_type == ACK_TYPE: 
                    # Unpack: (ACK_TYPE, acked_packet_num, status)
                    _, acked_packet_num, _ = message_body
                    buffer_key = (original_sender_id, acked_packet_num)

                    if buffer_key in self.resend_buffer:
                        print(f"NIC {self.instance_id}: Received ACK for packet {acked_packet_num} from {original_sender_id}. Packet confirmed.")
                        del self.resend_buffer[buffer_key]
                    else:
                        print(f"NIC {self.instance_id}: Received stale ACK for packet {acked_packet_num}. Ignoring.")

            except queue.Empty:
                pass # No incoming messages
            except Exception as e:
                print(f"NIC {self.instance_id}: FATAL error processing incoming message: {e}")

        # --- 3. Handle Outgoing Messages from the CPU ---
        if int(self.mainmem.read(self.send_status_register)) == NIC_STATUS_SEND_REQUEST:
            # CPU can request to send DATA
            message_type_to_send = int(self.mainmem.read(self.message_type_register))
            dst_nic_id = int(self.mainmem.read(self.dst_register))

            if message_type_to_send == DATA_TYPE:
                data_payload = self.mainmem.read(self.data_out_register)
                service_id_payload = int(self.mainmem.read(self.service_id_out_register))

                peer_state = self._get_or_create_peer_state(dst_nic_id)
                packet_num_to_send = peer_state['next_packet_to_send']

                # Message format for Hub: (receiver, sender, payload)
                # Payload: (DATA_TYPE, packet_num, service_id, data)
                protocol_payload = (DATA_TYPE, packet_num_to_send, service_id_payload, data_payload)
                hub_message = (dst_nic_id, self.instance_id, protocol_payload)

                # Store for retransmission
                buffer_key = (dst_nic_id, packet_num_to_send) #dst and packet_num to be unique
                self.resend_buffer[buffer_key] = {
                    'hub_message': hub_message,
                    'send_time': time.time()
                }

                self.send_queue.put(hub_message)
                print(f"NIC {self.instance_id}: Sent NEW DATA packet {packet_num_to_send} to {dst_nic_id}")

                peer_state['next_packet_to_send'] += 1
            else:
                # an unsupported messagetype
                print(f"NIC {self.instance_id}: Sent by CPU-initiated, unsupported message type {message_type_to_send}")
            
            # Reset status for DATA and unsupported messagetypes
            self.mainmem.write(self.send_status_register, str(NIC_STATUS_IDLE))


        # --- 4. Handle Retransmissions for Timed-out Packets ---
        current_time = time.time()
        for buffer_key, packet_info in list(self.resend_buffer.items()):
            if current_time - packet_info['send_time'] > RETRANSMISSION_TIMEOUT:
                hub_message_to_resend = packet_info['hub_message']

                dst_id, _, payload = hub_message_to_resend  # used for printing
                packet_num = payload[1]                     # used for prinintg
                print(f"NIC {self.instance_id}: TIMEOUT for packet {packet_num} to {dst_id}. Resending.")
                
                self.send_queue.put(hub_message_to_resend)
                packet_info['send_time'] = current_time # Reset the timer for this packet