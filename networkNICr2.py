# create an virtial networkcard for the stern
import queue # For queue.Empty exception
import time

# --- message type
DATA_TYPE = 0       # (DATA_TYPE, dst (src, packetnumber, data))
ACK_TYPE  = 1       # (DATA_TYPE, dst (packetnumber, ACK_STATUS))

# --- Status Constants ---
NIC_STATUS_IDLE = 0
NIC_STATUS_SEND_REQUEST = 1 # Host wants to send
NIC_STATUS_DATA_WAITING = 1 # Data has arrived for host
ACK_STATUS_ACK  = 0
ACK_STATUS_NACK = 1
ACK_STATUS_NORESEND = 2


# --- Interrupt Number ---
NIC_RX_INTERRUPT_NUM = 9 # Example interrupt number for Receive Ready


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

        self.ack_status_register = BaseAdres + 6
        self.message_type_register = BaseAdres + 7
        self.packetnumber_register = BaseAdres + 8

        # registers for Serivice ID
        self.service_id_out_register = BaseAdres + 9
        self.service_id_in_register = BaseAdres + 10



        # Initialize status registers to IDLE
        self.mainmem.write(self.receive_status_register, str(NIC_STATUS_IDLE))
        self.mainmem.write(self.send_status_register,    str(NIC_STATUS_IDLE))
        self.mainmem.write(self.ack_status_register,     str(ACK_STATUS_ACK))
        self.mainmem.write(self.message_type_register,   str(DATA_TYPE))
        self.mainmem.write(self.service_id_out_register, str(0))
        self.mainmem.write(self.service_id_in_register,  str(0))

        self.packetnumber = 0
        self.sent_packets_buffer = {}


    def update(self):
        # each update (every 20ms) had to:
        # read the device registers
        receive_status = int(self.mainmem.read(self.receive_status_register))
        # send_status and message_type for CPU requests are read later, before the actual send logic.
        # Other registers (dst_register, data_out_register, etc.) are read on demand.

        # --- Handle Receiving ---
        # Hub sends: (original_source_nic_id, (protocol_message_type, packet_id_or_num, service_id, content)) for DATA
        # Hub sends: (original_source_nic_id, (protocol_message_type, packet_id_or_num, ack_status_content)) for ACK
        # Check if the NIC is idle (ready for new data) AND if data is available in the queue
        if receive_status == NIC_STATUS_IDLE:
            try:
                # Try to get data without blocking
                original_sender_id, protocol_payload = self.receive_queue.get_nowait()
                actual_msg_type = protocol_payload[0] 

                if actual_msg_type == DATA_TYPE:
                    # Unpack: (DATA_TYPE, packet_num, service_id, data_content)
                    _, received_packet_num, received_service_id, received_data = protocol_payload

                    print(f"NIC {self.instance_id}: Received DATA packet {received_packet_num} from {original_sender_id} for service {received_service_id}")
                    
                    self.mainmem.write(self.src_register, str(original_sender_id)) 
                    self.mainmem.write(self.data_in_register, str(received_data)) # Data is string
                    self.mainmem.write(self.service_id_in_register, str(received_service_id)) # Make Service ID available to CPU

                    # CPU needs packet number to ACK/NACK, so pass it via interrupt or a register.
                    # self.mainmem.write(self.packetnumber_register, str(received_packet_num)) # Option 1: Write to packetnumber_register
                
                    self.mainmem.write(self.receive_status_register, str(NIC_STATUS_DATA_WAITING))
                    # Trigger the interrupt *after* data is ready and status is set
                    self.interrupts.interrupt(NIC_RX_INTERRUPT_NUM, received_packet_num) # Option 2: Pass via interrupt value

                elif actual_msg_type == ACK_TYPE:
                    # Unpack: (ACK_TYPE, packet_num, ack_status)
                    _, acked_packet_number, received_ack_status = protocol_payload

                    if received_ack_status == ACK_STATUS_ACK:
                        if acked_packet_number in self.sent_packets_buffer:
                            print(f"NIC {self.instance_id}: Received ACK for sent packet {acked_packet_number} from {original_sender_id}.")
                            del self.sent_packets_buffer[acked_packet_number]
                        else:
                            print(f"NIC {self.instance_id}: Received ACK for unknown/already ACKed packet {acked_packet_number}.")
                        # self.mainmem.write(self.receive_status_register, str(NIC_STATUS_IDLE)) # Already IDLE, or will be set by CPU

                    elif received_ack_status == ACK_STATUS_NACK:
                        print(f"NIC {self.instance_id}: Received NACK for sent packet {acked_packet_number} from {original_sender_id}. Resending (Go-Back-N).")
                        if acked_packet_number in self.sent_packets_buffer:
                            ids_to_resend_sorted = sorted([
                                pid for pid in self.sent_packets_buffer.keys() if pid >= acked_packet_number
                            ])
                            for pid_to_resend in ids_to_resend_sorted:
                                if pid_to_resend in self.sent_packets_buffer: # Check again
                                    packet_info = self.sent_packets_buffer[pid_to_resend]
                                    # Resend must include service_id
                                    resend_protocol_payload = (DATA_TYPE, pid_to_resend, packet_info['service_id'], packet_info['data'])
                                    resend_hub_message = (packet_info['dst'], self.instance_id, resend_protocol_payload) # Hub expects (dst, src, payload)
                                    self.send_queue.put(resend_hub_message)
                                    print(f"NIC {self.instance_id}: Resent (GBN) DATA packet {pid_to_resend} to {packet_info['dst']}")
                        else:
                            print(f"NIC {self.instance_id}: Received NACK for unknown/already ACKed packet {acked_packet_number}.")
                        # self.mainmem.write(self.receive_status_register, str(NIC_STATUS_IDLE)) # Already IDLE
                    elif received_ack_status == ACK_STATUS_NORESEND:
                        #print(f"NIC {self.instance_id}: Received NORESEND for sent packet {acked_packet_number} from {original_sender_id}.")
                        print(f"NIC {self.instance_id}: Received NORESEND from {original_sender_id}, receiver expects packet {acked_packet_number}.")


            except queue.Empty:
                pass # No data currently in queue, NIC remains idle
            except ValueError as e:
                print(f"NIC {self.instance_id}: Error processing register value: {e}")
            except Exception as e:
                print(f"NIC {self.instance_id}: Error processing incoming message: {e}")
        
        # --- Handle Sending (Moved after Receiving) ---
        # Re-read send_status and message_type as they might have been set by CPU
        # while the receive block was executing or if this is a new cycle.
        # However, for atomicity of one CPU request, we use the initially read values.
        # If CPU sets send_status to SEND_REQUEST, it expects it to be handled.
        # The key is that NACK processing above has already queued GBN packets.
        
        send_status = int(self.mainmem.read(self.send_status_register)) # Read current send status
        message_type = int(self.mainmem.read(self.message_type_register)) # Read current message type

        if send_status == NIC_STATUS_SEND_REQUEST:
            if message_type == DATA_TYPE:
                dst_nic_id = int(self.mainmem.read(self.dst_register))
                data_payload = self.mainmem.read(self.data_out_register) # Data is string
                service_id_payload = int(self.mainmem.read(self.service_id_out_register)) # outgoing serivce ID


                # Protocol payload: (MSG_TYPE, packet_number, service_id, actual_data)
                protocol_payload = (DATA_TYPE, self.packetnumber, service_id_payload, data_payload)
                hub_message = (dst_nic_id, self.instance_id, protocol_payload) # Hub expects (dst, src, payload)

                
                self.sent_packets_buffer[self.packetnumber] = { # save the packet for potential resend
                    'dst' : dst_nic_id, 
                    'data': data_payload,
                    'service_id': service_id_payload 
                }
                self.send_queue.put(hub_message)
                
                print(f"NIC {self.instance_id}: Sent NEW DATA packet {self.packetnumber} to {dst_nic_id} for service {service_id_payload}")
                self.packetnumber += 1
                self.mainmem.write(self.send_status_register, str(NIC_STATUS_IDLE))

            elif message_type == ACK_TYPE: # CPU is sending an ACK/NACK for data it received
                dst_nic_id = int(self.mainmem.read(self.dst_register)) 
                packet_num_to_ack = int(self.mainmem.read(self.packetnumber_register))
                ack_status_val = int(self.mainmem.read(self.ack_status_register))

                protocol_payload = (ACK_TYPE, packet_num_to_ack, ack_status_val)
                hub_message = (dst_nic_id, self.instance_id, protocol_payload) # Hub expects (dst, src, payload)


                self.send_queue.put(hub_message)
                status_text = "ACK" if ack_status_val == ACK_STATUS_ACK else "NACK"
                print(f"NIC {self.instance_id}: Sent CPU-initiated {status_text} for packet {packet_num_to_ack} to {dst_nic_id}")
                self.mainmem.write(self.send_status_register, str(NIC_STATUS_IDLE))

        # NOTE: Do NOT reset receive_status here. The CPU must do that after reading.