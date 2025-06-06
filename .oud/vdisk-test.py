import os
import hashlib

class VirtualDisk:
    def __init__(self, real_directory):
        self.directory = real_directory
        self.file_map = {}
        self.buffer = None
        self.buffer_index = 0
        self._build_file_map()

    def _build_file_map(self):
        for filename in os.listdir(self.directory):
            if os.path.isfile(os.path.join(self.directory, filename)):
                name, ext = os.path.splitext(filename)
                if ext:  # Consider only files with extensions (assuming text files have them)
                    base_name = name
                    hashed_name = hashlib.sha256(base_name.encode()).hexdigest()
                    self.file_map[hashed_name] = os.path.join(self.directory, filename)

    def open(self, hashed_filename):
        if hashed_filename in self.file_map:
            real_path = self.file_map[hashed_filename]
            try:
                with open(real_path, 'r') as f:
                    self.buffer = f.readlines()
                    self.buffer_index = 0
                    return True
            except FileNotFoundError:
                print(f"Error: Real file not found at {real_path}")
                self.buffer = None
                self.buffer_index = 0
                return False
            except Exception as e:
                print(f"Error opening file: {e}")
                self.buffer = None
                self.buffer_index = 0
                return False
        else:
            return False

    def read(self):
        if self.buffer is not None:
            if self.buffer_index < len(self.buffer):
                line = self.buffer[self.buffer_index].rstrip('\n')  # Remove trailing newline
                self.buffer_index += 1
                return line
            else:
                return None
        else:
            return None

    def close(self):
        if self.buffer is not None:
            self.buffer = None
            self.buffer_index = 0
            return True
        else:
            return False

if __name__ == '__main__':
    # Create a temporary directory and some files for testing
    temp_dir = "temp_virtual_disk"
    os.makedirs(temp_dir, exist_ok=True)
    with open(os.path.join(temp_dir, "file1.txt"), "w") as f:
        f.write("This is line 1 of file1.\n")
        f.write("This is line 2 of file1.\n")
    with open(os.path.join(temp_dir, "another_file.txt"), "w") as f:
        f.write("First line of another file.\n")
        f.write("Second line.\n")
        f.write("Third line.\n")
    with open(os.path.join(temp_dir, "no_extension"), "w") as f:
        f.write("This file has no extension.\n")

    virtual_disk = VirtualDisk(temp_dir)
    print("File Map:", virtual_disk.file_map)

    # Test opening and reading file1.txt
    filename_to_open = "file1"
    hashed_filename = hashlib.sha256(filename_to_open.encode()).hexdigest()
    if virtual_disk.open(hashed_filename):
        print(f"\nOpened file with hash: {hashed_filename}")
        line = virtual_disk.read()
        while line is not None:
            print(f"Read line: {line}")
            line = virtual_disk.read()
        virtual_disk.close()
        print("Closed the file.")
    else:
        print(f"\nCould not open file with hash: {hashed_filename}")

    # Test opening and reading another_file.txt
    filename_to_open = "another_file"
    hashed_filename = hashlib.sha256(filename_to_open.encode()).hexdigest()
    if virtual_disk.open(hashed_filename):
        print(f"\nOpened file with hash: {hashed_filename}")
        line = virtual_disk.read()
        while line is not None:
            print(f"Read line: {line}")
            line = virtual_disk.read()
        virtual_disk.close()
        print("Closed the file.")
    else:
        print(f"\nCould not open file with hash: {hashed_filename}")

    # Test opening a non-existent file (by incorrect hash)
    incorrect_hash = "invalid_hash"
    if virtual_disk.open(incorrect_hash):
        print("\nOpened a file with an incorrect hash (this should not happen).")
        virtual_disk.close()
    else:
        print(f"\nCould not open file with hash: {incorrect_hash} (as expected).")

    # Clean up the temporary directory and files
    # import shutil
    # shutil.rmtree(temp_dir)