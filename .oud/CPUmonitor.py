import time

class CpuMonitor:
    """
    Measures and reports CPU performance metrics like clock speed,
    fastest cycle, and slowest cycle.
    """
    def __init__(self):
        self._start_time = 0.0
        self._end_time = 0.0
        self._cycle_count = 0
        self._cycle_times_ns = [] # Store cycle times in nanoseconds for precision
        self._min_cycle_ns = float('inf')
        self._max_cycle_ns = 0.0
        self._cycle_start_ns = 0

    def start_monitoring(self):
        """Records the overall start time of the CPU execution."""
        self._start_time = time.perf_counter()
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

        if cycle_duration_ns < 0: # Handle potential counter wrap-around or anomalies
             print(f"Warning: Negative cycle duration detected ({cycle_duration_ns} ns). Skipping.")
             return # Skip this cycle measurement

        self._cycle_count += 1
        self._cycle_times_ns.append(cycle_duration_ns)

        if cycle_duration_ns < self._min_cycle_ns:
            self._min_cycle_ns = cycle_duration_ns
        if cycle_duration_ns > self._max_cycle_ns:
            self._max_cycle_ns = cycle_duration_ns
            #print(f"Cycle took (new max): {cycle_duration_ns / 1_000_000:.6f} ms")

    def stop_monitoring(self):
        """Records the overall end time of the CPU execution."""
        self._end_time = time.perf_counter()
        print("CPU Monitor: Stopped.")

    def report(self):
        """Calculates and prints the performance report."""
        if self._cycle_count == 0:
            print("CPU Monitor Report: No cycles executed.")
            return

        total_duration_sec = self._end_time - self._start_time
        if total_duration_sec <= 0:
             print("CPU Monitor Report: Total duration is zero or negative. Cannot calculate speed.")
             # Still report min/max cycle times if available
             if self._min_cycle_ns != float('inf'):
                 min_cycle_ms = self._min_cycle_ns / 1_000_000
                 max_cycle_ms = self._max_cycle_ns / 1_000_000
                 print(f"  - Fastest Cycle: {min_cycle_ms:.6f} ms")
                 print(f"  - Slowest Cycle: {max_cycle_ms:.6f} ms")
             return


        # Calculate Clock Speed
        cycles_per_second = self._cycle_count / total_duration_sec
        clock_speed_mhz = cycles_per_second / 1_000_000

        # Convert min/max from nanoseconds to milliseconds
        min_cycle_ms = self._min_cycle_ns / 1_000_000
        max_cycle_ms = self._max_cycle_ns / 1_000_000

        # --- Optional: Calculate Average Cycle Time ---
        total_cycle_time_ns = sum(self._cycle_times_ns)
        avg_cycle_time_ns = total_cycle_time_ns / self._cycle_count
        avg_cycle_ms = avg_cycle_time_ns / 1_000_000

        print("\n--- CPU Performance Report ---")
        print(f"  - Total Execution Time: {total_duration_sec:.4f} seconds")
        print(f"  - Total Cycles Executed: {self._cycle_count}")
        print(f"  - Estimated Clock Speed: {clock_speed_mhz:.4f} MHz ({cycles_per_second:.2f} Hz)")
        print(f"  - Fastest Cycle: {min_cycle_ms:.6f} ms")
        print(f"  - Slowest Cycle: {max_cycle_ms:.6f} ms")
        print(f"  - Average Cycle: {avg_cycle_ms:.6f} ms") # Uncomment if needed
        print("----------------------------\n")

