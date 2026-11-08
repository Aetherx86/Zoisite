const std = @import("std");
const builtin = @import("builtin");
pub const pmu = @import("pmu.zig");
pub const auditor = @import("auditor.zig");

fn sampleMathKernel() void {
    var a: u64 = 0x12345678;
    var b: u64 = 0x9ABCDEF0;
    for (0..50) |i| {
        a = a *% 6364136223846793005 +% 1;
        b ^= (a >> 17);
        b +%= i;
    }
    std.mem.doNotOptimizeAway(a);
    std.mem.doNotOptimizeAway(b);
}

pub fn main(init: std.process.Init) !void {
    _ = init.arena.allocator();
    var args = init.minimal.args.iterate();
    _ = args.next(); // skip prog name

    const cmd = args.next() orelse {
        printUsage();
        return;
    };

    if (std.mem.eql(u8, cmd, "audit")) {
        const count_str = args.next() orelse "100000";
        const count = std.fmt.parseInt(usize, count_str, 10) catch 100_000;

        std.debug.print("Zoisite: Hardware PMU Instruction-Retired Auditor on {s}...\n", .{@tagName(builtin.cpu.arch)});
        std.debug.print("Auditing computational kernel ({d} iterations)...\n", .{count});

        const report = auditor.FunctionAuditor.audit(@TypeOf(sampleMathKernel), sampleMathKernel, count, 150);

        std.debug.print(
            \\PMU Audit Report:
            \\  Architecture:        {s}
            \\  Sampled Iterations:  {d}
            \\  Total CPU Cycles:    {d}
            \\  Avg Cycles/Call:     {d:.2} cycles
            \\  Min Call Cycles:     {d} cycles
            \\  Max Call Cycles:     {d} cycles
            \\  Est. Instructions:   {d}
            \\  Cycles/Instruction:  {d:.3} CPI
            \\  Instructions/Cycle:  {d:.3} IPC
            \\
        , .{
            @tagName(builtin.cpu.arch),
            report.iterations,
            report.total_cycles,
            report.avg_cycles_per_call,
            report.min_cycles,
            report.max_cycles,
            report.estimated_instructions,
            report.cpi,
            report.ipc,
        });
    } else {
        printUsage();
    }
}

fn printUsage() void {
    std.debug.print(
        \\Zoisite: Hardware PMU & Instruction-Retired Auditor
        \\Usage:
        \\  zoisite audit [iterations]
        \\  zoisite --help
        \\
    , .{});
}

test {
    _ = @import("pmu.zig");
    _ = @import("auditor.zig");
}
