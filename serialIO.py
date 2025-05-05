from time import sleep


class serialIO:
    def __init__(self, MainMem, BaseAdres) -> None:
        self.mainmem = MainMem

        self.channels = {}
        
        self.channel = BaseAdres

        # commands
        # 00 (0) open channel
        # 01 (1) write to channel
        # 10 (2) read from channel
        # 11 (3) close channel
        self.command_register = BaseAdres + 1

        self.data_register = BaseAdres + 2

        # Status
        # 00 (0) Idle
        # 01 (1) Data ready
        # 10 (2) Waiting for data
        # 11 (3) Error
        self.status_register = BaseAdres + 3

        # set init status to idle
        self.mainmem.write(self.status_register, 0)
    
    def IO(self) -> None: 
        # read device registers
        channel = int(self.mainmem.read(self.channel))
        command = int(self.mainmem.read(self.command_register))
        data    = int(self.mainmem.read(self.data_register))
        status  = int(self.mainmem.read(self.status_register))


        if status == 1:       # data ready
            if command == 0:  # open channel
                self.mainmem.write(self.status_register, 2)
                self.channels[channel] = []

            elif command == 1: # write to channel
                if channel in self.channels:
                    self.channels[channel].append(data)
                    self.mainmem.write(self.status_register, 0)
                else:
                    self.mainmem.write(self.status_register, 3)
                    

            elif command == 2: # read from channel
                pass

            elif command == 3: # close channel
                if channel in self.channels:
                    del self.channels[channel]
                    self.mainmem.write(self.status_register, 0)
                else:
                    self.mainmem.write(self.status_register, 3)
            else:
                pass
                
        else:
            pass

    def check_channel(self, channel) -> bool:
        if channel in self.channels:
            return True
        else:
            return False
        
    def read_channel(self, channel):
        if len(self.channels[channel]) > 0:
            return self.channels[channel].pop(0)
        else:
            return None
    
    def set_idle(self):
        self.mainmem.write(self.status_register, 0)
            

        
        
        
        

        
        
