const std = @import("std");
const pmu = @import("pmu.zig");

pub const AuditReport = struct {
    iterations: usize,
    total_cycles: u64,
    avg_cycles_per_call: f64,
    min_cycles: u64,
    max_cycles: u64,
    estimated_instructions: u64,
    cpi: f64,
    ipc: f64,
};

pub const FunctionAuditor = struct {
    pub fn audit(comptime TargetFn: type, target: TargetFn, iterations: usize, instructions_per_call: u64) AuditReport {
        var total_cycles: u64 = 0;
        var min_c: u64 = std.math.maxInt(u64);
        var max_c: u64 = 0;

        // Warmup
        for (0..100) |_| {
            target();
        }

        for (0..iterations) |_| {
            pmu.PmuReader.serialize();
            const start = pmu.PmuReader.readCycles();

            target();

            pmu.PmuReader.serialize();
            const end = pmu.PmuReader.readCycles();

            const elapsed = if (end >= start) end - start else 0;
            total_cycles += elapsed;
            if (elapsed < min_c) min_c = elapsed;
            if (elapsed > max_c) max_c = elapsed;
        }

        const avg_c = if (iterations > 0)
            @as(f64, @floatFromInt(total_cycles)) / @as(f64, @floatFromInt(iterations))
        else
            0.0;
        const total_inst = iterations * instructions_per_call;
        const cpi = if (total_inst > 0)
            @as(f64, @floatFromInt(total_cycles)) / @as(f64, @floatFromInt(total_inst))
        else
            0.0;
        const ipc = if (cpi > 0.0) 1.0 / cpi else 0.0;

        return AuditReport{
            .iterations = iterations,
            .total_cycles = total_cycles,
            .avg_cycles_per_call = avg_c,
            .min_cycles = min_c,
            .max_cycles = max_c,
            .estimated_instructions = total_inst,
            .cpi = cpi,
            .ipc = ipc,
        };
    }
};

fn dummyWork() void {
    var x: u64 = 1;
    for (0..10) |i| {
        x = x *% 3 +% i;
    }
    std.mem.doNotOptimizeAway(x);
}

test "FunctionAuditor Execution and Statistics" {
    const report = FunctionAuditor.audit(@TypeOf(dummyWork), dummyWork, 1000, 30);
    try std.testing.expectEqual(@as(usize, 1000), report.iterations);
    try std.testing.expect(report.total_cycles > 0);
    try std.testing.expect(report.avg_cycles_per_call > 0.0);
    try std.testing.expect(report.cpi >= 0.0);
    try std.testing.expect(report.ipc >= 0.0);
}
