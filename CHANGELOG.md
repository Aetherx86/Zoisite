# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-08

### Added
- Initial release of Zoisite: Hardware PMU & Instruction-Retired Auditor in Zig.
- Direct CPU cycle counter reading (rdtsc on x86_64, cntvct_el0 on AArch64).
- Hardware execution serialization barriers (cpuid on x86_64, isb on AArch64).
- Function auditing harness computing Cycles Per Instruction (CPI) and Instructions Per Cycle (IPC).
- Comprehensive unit test suite verifying counter sampling and telemetry calculation.
