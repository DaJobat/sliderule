const std = @import("std");

pub fn build(b: *std.Build) void {
    const lib = b.addModule("sliderule", .{
        .source_file = std.Build.FileSource.relative("sliderule.zig"),
    });

    const tests = b.addTest(.{ .root_source_file = lib.source_file });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "run tests");
    test_step.dependOn(&run_tests.step);
}
