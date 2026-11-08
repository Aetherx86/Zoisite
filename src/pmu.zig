const std = @import("std");
const builtin = @import("builtin");

pub const Arch = enum {
    x86_64,
    aarch64,
    generic,
};

pub const PmuReader = struct {
    pub inline fn serialize() void {
        if (builtin.cpu.arch == .x86_64) {
            var eax: u32 = undefined;
            var ebx: u32 = undefined;
            var ecx: u32 = undefined;
            var edx: u32 = undefined;
            asm volatile ("cpuid"
                : [_] "={eax}" (eax),
                  [_] "={ebx}" (ebx),
                  [_] "={ecx}" (ecx),
                  [_] "={edx}" (edx),
                : [_] "{eax}" (0),
                  [_] "{ecx}" (0),
            );
        } else if (builtin.cpu.arch == .aarch64) {
            asm volatile ("isb");
        }
    }

    pub inline fn readCycles() u64 {
        if (builtin.cpu.arch == .x86_64) {
            var low: u32 = undefined;
            var high: u32 = undefined;
            asm volatile ("rdtsc"
                : [low] "={eax}" (low),
                  [high] "={edx}" (high)
            );
            return (@as(u64, high) << 32) | @as(u64, low);
        } else if (builtin.cpu.arch == .aarch64) {
            var val: u64 = undefined;
            asm volatile ("mrs %[val], cntvct_el0"
                : [val] "=r" (val)
            );
            return val;
        } else {
            return 0;
        }
    }
};

pub const AuditSample = struct {
    start_cycles: u64,
    end_cycles: u64,
    elapsed_cycles: u64,
    estimated_instructions: u64,
    cpi: f64,
    ipc: f64,

    pub fn compute(start: u64, end: u64, instructions: u64) AuditSample {
        const elapsed = if (end >= start) end - start else 0;
        const cpi = if (instructions > 0)
            @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(instructions))
        else
            0.0;
        const ipc = if (cpi > 0.0) 1.0 / cpi else 0.0;

        return AuditSample{
            .start_cycles = start,
            .end_cycles = end,
            .elapsed_cycles = elapsed,
            .estimated_instructions = instructions,
            .cpi = cpi,
            .ipc = ipc,
        };
    }
};

test "Hardware PMU Counter Reading & Serialization" {
    PmuReader.serialize();
    const t0 = PmuReader.readCycles();

    // Do some work
    var acc: u64 = 0;
    for (0..1000) |i| {
        acc +%= i;
    }
    std.mem.doNotOptimizeAway(acc);

    PmuReader.serialize();
    const t1 = PmuReader.readCycles();

    try std.testing.expect(t1 >= t0);

    const sample = AuditSample.compute(t0, t1, 1000);
    try std.testing.expect(sample.elapsed_cycles > 0);
    try std.testing.expect(sample.cpi >= 0.0);
    try std.testing.expect(sample.ipc >= 0.0);
}
