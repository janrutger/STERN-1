# /home/janrutger/git/STERN-1/CPUmonitor1.py
import time

class CpuMonitor:
    """
    Measures and reports CPU performance metrics like clock speed,
    cycle times, and time spent in specific operations like SIO.
    """
    def __init__(self):
        self._start_time = 0.0
        self._end_time = 0.0
        self._cycle_count = 0
        self._cycle_times_ns = [] # Store cycle times in nanoseconds for precision
        self._min_cycle_ns = float('inf')
        self._max_cycle_ns = 0.0
        self._cycle_start_ns = 0

        # --- SIO Timing Attributes ---
        self._sio_call_count = 0
        self._total_sio_time_ns = 0
        self._sio_start_ns = 0
        self._min_sio_time_ns = float('inf') # <-- Add Min SIO time tracker
        self._max_sio_time_ns = 0.0         # <-- Add Max SIO time tracker
        # --- End SIO ---

    def start_monitoring(self):
        """Records the overall start time of the CPU execution."""
        self._start_time = time.perf_counter()
        # Reset counters
        self._cycle_count = 0
        self._cycle_times_ns = []
        self._min_cycle_ns = float('inf')
        self._max_cycle_ns = 0.0
        self._sio_call_count = 0
        self._total_sio_time_ns = 0
        self._min_sio_time_ns = float('inf') # <-- Reset Min SIO
        self._max_sio_time_ns = 0.0         # <-- Reset Max SIO
        print("CPU Monitor: Started.")

    def start_cycle(self):
        """Records the start time of a single instruction cycle."""
        self._cycle_start_ns = time.perf_counter_ns()

    def end_cycle(self):
        """
        Records the end time of a single instruction cycle, calculates
        its duration, and updates statistics.
        """
        cycle_end_ns = time.perf_counter_ns()
        cycle_duration_ns = cycle_end_ns - self._cycle_start_ns

        if cycle_duration_ns < 0:
             print(f"Warning: Negative cycle duration detected ({cycle_duration_ns} ns). Skipping cycle measurement.")
             return

        self._cycle_count += 1
        self._cycle_times_ns.append(cycle_duration_ns)

        if cycle_duration_ns < self._min_cycle_ns:
            self._min_cycle_ns = cycle_duration_ns
        if cycle_duration_ns > self._max_cycle_ns:
            self._max_cycle_ns = cycle_duration_ns

    # --- SIO Timing Methods ---
    def start_sio_call(self):
        """Records the start time before calling sio.IO()."""
        self._sio_start_ns = time.perf_counter_ns()

    def end_sio_call(self):
        """Records the end time after sio.IO() returns and updates SIO stats."""
        sio_end_ns = time.perf_counter_ns()
        sio_duration_ns = sio_end_ns - self._sio_start_ns

        if sio_duration_ns < 0:
            print(f"Warning: Negative SIO duration detected ({sio_duration_ns} ns). Skipping SIO measurement for this call.")
            return

        self._sio_call_count += 1
        self._total_sio_time_ns += sio_duration_ns

        # --- Update Min/Max SIO Time ---
        if sio_duration_ns < self._min_sio_time_ns:
            self._min_sio_time_ns = sio_duration_ns
        if sio_duration_ns > self._max_sio_time_ns:
            self._max_sio_time_ns = sio_duration_ns
        # --- End Update ---

    # --- End SIO ---

    def stop_monitoring(self):
        """Records the overall end time of the CPU execution."""
        self._end_time = time.perf_counter()
        print("CPU Monitor: Stopped.")

    def report(self):
        """Calculates and prints the performance report including SIO time."""
        print("\n--- CPU Performance Report ---")
        if self._cycle_count == 0:
            print("  No cycles executed.")
            print("----------------------------\n")
            return

        total_duration_sec = self._end_time - self._start_time
        if total_duration_sec <= 0:
             print("  Total duration is zero or negative. Cannot calculate speed.")
             total_duration_sec = 0
        else:
            cycles_per_second = self._cycle_count / total_duration_sec
            clock_speed_mhz = cycles_per_second / 1_000_000
            print(f"  - Total Execution Time : {total_duration_sec:.4f} seconds")
            print(f"  - Total Cycles Executed: {self._cycle_count}")
            print(f"  - Estimated Clock Speed: {clock_speed_mhz:.4f} MHz ({cycles_per_second:.2f} Hz)\n")

        min_cycle_ms = self._min_cycle_ns / 1_000_000 if self._min_cycle_ns != float('inf') else 0
        max_cycle_ms = self._max_cycle_ns / 1_000_000

        if self._cycle_times_ns:
            total_cycle_time_ns = sum(self._cycle_times_ns)
            total_cycle_time_s = total_cycle_time_ns / 1_000_000_000
            
            avg_cycle_time_ns = total_cycle_time_ns / self._cycle_count
            avg_cycle_ms = avg_cycle_time_ns / 1_000_000
        else:
             avg_cycle_ms = 0

        print(f"  - Fastest Cycle: {min_cycle_ms:.6f} ms")
        print(f"  - Slowest Cycle: {max_cycle_ms:.6f} ms")
        print(f"  - Average Cycle: {avg_cycle_ms:.6f} ms")
        print(f"  - Total Core time     : {total_cycle_time_s:.4f} seconds")

        core_cycles_per_second = self._cycle_count / total_cycle_time_s
        core_speed_mhz = core_cycles_per_second / 1_000_000
        print(f"  - Estimated Core Speed: {core_speed_mhz:.4f} MHz ({core_cycles_per_second:.2f} Hz)")


        # --- SIO Report ---
        print("\n  -   --- Serial IO Performance ---")
        if self._sio_call_count > 0:
            total_sio_ms = self._total_sio_time_ns / 1_000_000
            total_sio_s  = self._total_sio_time_ns / 1_000_000_000
            avg_sio_ms = total_sio_ms / self._sio_call_count
            #sio_percentage = (self._total_sio_time_ns / (total_duration_sec * 1_000_000_000)) * 100 if total_duration_sec > 0 else 0
            sio_percentage = (self._total_sio_time_ns / (total_cycle_time_ns)) * 100 if total_duration_sec > 0 else 0

            # Convert min/max SIO from nanoseconds to milliseconds
            min_sio_ms = self._min_sio_time_ns / 1_000_000 if self._min_sio_time_ns != float('inf') else 0
            max_sio_ms = self._max_sio_time_ns / 1_000_000

            # --- Updated Report Lines ---
            print(f"    - Fastest SIO Call: {min_sio_ms:.6f} ms") # <-- Report Min
            print(f"    - Slowest SIO Call: {max_sio_ms:.6f} ms") # <-- Report Max
            print(f"    - Average SIO Call: {avg_sio_ms:.6f} ms")
            print(f"    - Total SIO Time: {total_sio_s:.4f} seconds")
            if total_duration_sec > 0:
                print(f"    - SIO Time as % of Total: {sio_percentage:.2f}%")
            # --- End Updated Report Lines ---
        else:
            print("    - No SIO calls were measured.")
        # --- End SIO Report ---

        print("----------------------------------------------\n")

