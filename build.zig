const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("sliderule", .{
        .source_file = std.Build.FileSource.relative("sliderule.zig"),
    });

    const lib = b.addStaticLibrary(.{
        .name = "sliderule",
        .root_source_file = std.Build.FileSource.relative("sliderule.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const tests = b.addTest(.{ .root_source_file = std.Build.FileSource.relative("sliderule.zig") });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "run tests");
    test_step.dependOn(&run_tests.step);
}
