# Zoisite

Zoisite is a hardware Performance Monitoring Unit (PMU) and instruction-retired telemetry auditor written in pure Zig.

## Overview

Software timing mechanisms like `clock_gettime` or wall-clock timers suffer from operating system scheduling jitter and CPU frequency scaling noise. Zoisite bypasses kernel abstractions to read hardware processor performance counters directly via inline assembly with strict serialization barriers.

## Architecture

- **Hardware Cycle Readers**:
  - `x86_64`: Emits `rdtsc` preceded by `cpuid` serialization barriers to flush out-of-order execution pipelines.
  - `AArch64`: Emits `cntvct_el0` virtual counter reads preceded by `isb` (instruction synchronization barriers).
- **Metric Computation**: Computes true processor micro-architectural metrics:
  - Total elapsed CPU cycles.
  - Cycles Per Instruction (CPI).
  - Instructions Per Cycle (IPC).
- **Zero OS Latency**: Completely eliminates syscall overhead during hot-loop benchmarking.

## Building

```bash
# Run unit tests
zig build test

# Build optimized binary
zig build -Doptimize=ReleaseFast
```

## Usage

```bash
# Run hardware PMU audit on sample kernel (100,000 iterations)
./zig-out/bin/zoisite audit 100000
```

## License

MIT License. Copyright (c) 2026 Jeong Hoon Kim.
