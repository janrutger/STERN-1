import matplotlib.pyplot as plt
from time import sleep
import threading


class Plotter:
    def __init__(self, sio) -> None:
        self.sio = sio
        self.channel = 0
        self.status  = 'offline'
        self.x_ax = 0

        self.fig, self.ax = plt.subplots(figsize=(8,5))
        plt.show()
        plt.pause(0.1)
        
        
    def run_plotter(self):
        #plt.ion()
        #plt.show(block=False)
        #sleep(0.1)
        #plt.show()
        # print("set online...........")
        # self.status = 'online'
        # self.sio.set_idle()
        print("plotter running...........")
        while self.status == 'online':
            data = self.sio.read_channel(self.channel)
            if data is not None:
                self.ax.scatter(self.x_ax, data, s=5, c='black')
                #self.ax.scatter(data, self.x_ax, s=5, c='black')
                self.x_ax = self.x_ax + 1
                plt.show()
                plt.pause(0.001)
                print("write data...........")
            #else: 
                #print("no data...........")
        sleep(1)




    def plot_update(self):
        if self.sio.check_channel(self.channel) and self.status == 'offline':
            print("set online...........")
            self.status = 'online'
            self.sio.set_idle() 
            
            

        elif not self.sio.check_channel(self.channel) and self.status == 'online':
            self.status = 'offline'
            #plt.close('all')
            print("set offline...........")


                

        