const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ほかのプロジェクトから使うモジュール(build.zig.zon の依存にして b.dependency("ame_hand", ...).module("ame-hand"))
    const mod = b.addModule("ame-hand", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true, // カメラ(v4l2.zig)の open / ioctl
    });

    // 試し: カメラの前で手を動かすと、手の形と位置を表示する
    const demo = b.addExecutable(.{
        .name = "ame-hand-demo",
        .root_source_file = b.path("tools/demo.zig"),
        .target = target,
        .optimize = optimize,
    });
    demo.root_module.addImport("ame-hand", mod);
    demo.linkLibC();
    b.installArtifact(demo);

    const tests = b.addTest(.{ .root_source_file = b.path("src/root.zig"), .target = target, .optimize = optimize });
    tests.linkLibC();
    b.step("test", "テスト").dependOn(&b.addRunArtifact(tests).step);
}
