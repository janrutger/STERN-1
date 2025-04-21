from time import time

class RTC:
    def __init__(self, interrupts):
        self.interrupts = interrupts
        self.epoch = time()
        self.last_tick = time()
        self.tick_time = .5 

    def tick(self):
        if time() - self.last_tick > self.tick_time:
            value = int((time() - self.epoch)*10)
            #print (value)
            self.interrupts.interrupt(8, value) # 8 = RTC interrupt
            self.last_tick = time()

