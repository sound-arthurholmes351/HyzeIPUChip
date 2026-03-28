const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "hyze_ipu_zig",
        .root_source_file = .{ .path = "hyze_ipu_zig_driver.zig" },
        .target = target,
        .optimize = optimize,
    });

    // PCIe libpci (C interop)
    exe.linkLibC();
    exe.linkSystemLibrary("pci");
    exe.addIncludePath(.{ .path = "/usr/include/pci" });

    b.installArtifact(exe);
}
