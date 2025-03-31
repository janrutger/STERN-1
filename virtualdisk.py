import os

class VirtualDisk:
    def __init__(self, myASCII, MainMem, BaseAdres, real_directory):
        self.directory = real_directory
        self.ASCII = myASCII
        self.mainmem = MainMem

        self.status_register  = BaseAdres
        self.command_register = BaseAdres + 1
        self.data_register    = BaseAdres + 2
        
        self.mainmem.write(self.status_register, 0)

        self.file_map = {}
        self.buffer = None
        self.serial_buffer = str()
        self.serial_buffer_index = 0
        self._build_file_map()

    def _myhash(self, filename):
        myhash = 0
        for char in filename:
            myhash = myhash * 7 + self.ASCII[char]
        return myhash
    
    def _build_file_map(self):
        for filename in os.listdir(self.directory):
            if os.path.isfile(os.path.join(self.directory, filename)):
                name, ext = os.path.splitext(filename)
                if ext:  # Consider only files with extensions (assuming text files have them)
                    base_name = name
                    hashed_name = self._myhash(base_name)
                    self.file_map[hashed_name] = os.path.join(self.directory, filename)


    def access(self):
        # read the status and dispatch disk-request
        
        # status options
        # 00 = idle (0)
        # 01 = request from disk (answer) (1)
        # 10 = request from host (2)
        # 11 = error (3)

        # command options
        # 00 = open file (0)
        # 01 = read fromfile (1)
        # 11 = close file (3)

        status  = int(self.mainmem.read(self.status_register))
        command = int(self.mainmem.read(self.command_register))
        data    = int(self.mainmem.read(self.data_register))

        
        if status == 2: # Request van host
            if command == 0: # open file
                hashed_filename = data
                if hashed_filename in self.file_map:
                    real_path = self.file_map[hashed_filename]
                    try:
                        with open(real_path, 'r') as f:
                            # self.buffer = f.readlines()
                            # # self.buffer_index = 0
                            # for line in self.buffer:
                            #     self.serial_buffer = self.serial_buffer  +  line +  " "
                            # self.serial_buffer_index = 0
                            # self.buffer = None
                            # self.mainmem.write(self.status_register, 1)

                            self.serial_buffer = ""  # Reset the buffer before reading a new file
                            for line in f:
                                self.serial_buffer += line
                                #self.serial_buffer += " " # add a space after each line
                            self.serial_buffer_index = 0
                            self.mainmem.write(self.status_register, 1)

                    except FileNotFoundError:
                        print(f"Error: Real file not found at {real_path}")
                        self.mainmem.write(self.status_register, 3)
                        self.buffer = None
                        #self.buffer_index = 0
                else:
                    self.mainmem.write(self.status_register, 3)
                    self.buffer = None
                    #self.buffer_index = 0

            elif command == 1: # read from file
                if self.serial_buffer == "":
                    self.mainmem.write(self.status_register, 3)
                else:
                    if len(self.serial_buffer) > self.serial_buffer_index:
                        char = self.serial_buffer[self.serial_buffer_index]
                        self.serial_buffer_index += 1
                        if char == "\n":
                            self.mainmem.write(self.data_register, self.ASCII["Return"])
                            self.mainmem.write(self.status_register, 1)
                        elif char == " ":
                            self.mainmem.write(self.data_register, self.ASCII["space"])
                            self.mainmem.write(self.status_register, 1)
                        else:
                            self.mainmem.write(self.data_register, self.ASCII[char])
                            self.mainmem.write(self.status_register, 1)
                    else:
                        self.mainmem.write(self.data_register, self.ASCII["null"])
                        self.mainmem.write(self.status_register, 1)
            
                        
        
        else:
            pass

