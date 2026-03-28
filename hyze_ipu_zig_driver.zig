const std = @import("std");
const c = @cImport({
    @cInclude("pci/pci.h");
    @cInclude("sys/mman.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
    @cInclude("string.h");
});

const allocator = std.heap.page_allocator;

const HyzeIpuError = error{ PciNotFound, BarMapFailed, FpgaResetFailed };

const HyzeIpu = struct {
    dev: ?*c.pci_dev,
    bar0: ?[*]u8,
    bar_size: usize,

    pub fn init(allocator: std.mem.Allocator) !HyzeIpu {
        _ = allocator; // Unused but comptime req

        // Init libpci
        _ = c.pci_init(null);
        const dev = c.pci_get_dev(null, 0, 0, 0, 0x10ee, 0x7021); // Xilinx VID:PID
        if (dev == null) return HyzeIpuError.PciNotFound;

        c.pci_access_dev(dev.?);

        const bar_size = @intCast(c.pci_bar_size(dev.?.*, 0));
        const fd = c.open("/dev/mem", c.O_RDWR | c.O_SYNC);
        if (fd == -1) return HyzeIpuError.BarMapFailed;

        const bar0 = c.mmap(null, bar_size, c.PROT_READ | c.PROT_WRITE,
                           c.MAP_SHARED, fd, c.pci_resource_address(dev.?, 0));
        c.close(fd);

        // Reset FPGA
        @as(*volatile u32, @ptrCast(@alignCast(bar0.? + 0x1000))).* = 0xDEADBEEF;
        std.time.sleep(10_000_000); // 10ms

        std.debug.print("Hyze IPU Zig: {d}KB BAR0\\n", .{bar_size / 1024});
        return .{ .dev = dev, .bar0 = @as([*]u8, @ptrCast(bar0)), .bar_size = bar_size };
    }

    pub fn deinit(self: *HyzeIpu) void {
        if (self.bar0) |_| c.munmap(self.bar0.?[0..self.bar_size].ptr, self.bar_size);
        if (self.dev) |_| c.pci_cleanup_dev(self.dev.?);
    }

    pub fn infer(self: *HyzeIpu, pixels: []const u8) u8 {
        const t0 = std.time.nanoTimestamp();

        // DMA write 784 pixels (zero-copy comptime size)
        const pixel_slice = pixels[0..784];
        @memcpy(self.bar0.?[0..784], pixel_slice);

        // Trigger (comptime aligned write)
        @as(*volatile u32, @ptrCast(@alignCast(self.bar0.? + 0xFFF0))).* = 1;

        // Poll DONE (500MHz tight loop)
        while ((@as(*volatile u32, @ptrCast(@alignCast(self.bar0.? + 0xFFF4))).* & 1) == 0) {}

        // Read result
        const class_id: u8 = @as(*volatile u8, @ptrCast(@alignCast(self.bar0.? + 0xFFF8))).* & 0x0F;

        const t1 = std.time.nanoTimestamp();
        const us: f64 = @as(f64, @floatFromInt(t1 - t0)) / 1e3;
        std.debug.print("Zig IPU: digit={} ({d:.1}μs)\\n", .{ class_id, us });

        return class_id;
    }

    // Comptime-optimized benchmark
    pub fn benchmark(comptime iters: usize) void {
        var pixels = [_]u8{128} ** 784;
        var total_ns: u64 = 0;

        inline for (0..iters) |i| {
            const t0 = std.time.nanoTimestamp();
            _ = self.infer(&pixels);
            total_ns += @intCast(std.time.nanoTimestamp() - t0);
        }

        std.debug.print("{d} iters: {d:.1}μs avg, {d} TOPS\\n",
                       .{ iters, @as(f64, @floatFromInt(total_ns)) / @as(f64, @floatFromInt(iters * 1000)), 
                          @as(f64, @floatFromInt(iters * 784 * 8)) / @as(f64, @floatFromInt(total_ns)) * 1e9 });
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var ipu = try HyzeIpu.init(allocator);
    defer ipu.deinit();

    var test_pixels = [_]u8{85} ** 784;
    const digit = ipu.infer(&test_pixels);
    std.debug.print("Predicted: {d}\\n", .{digit});

    // Benchmark 10k infers
    ipu.benchmark(10000);
}
