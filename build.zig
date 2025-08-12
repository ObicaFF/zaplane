const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zaplane", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "zaplane",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zaplane", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "version", "0.1.0");
    const build_options_mod = build_options.createModule();

    setupDaemon(b, optimize, target, mod, build_options_mod);
    setupCli(b, optimize, target, mod, build_options_mod);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}

fn setupDaemon(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
    mod: *std.Build.Module,
    build_options_mod: *std.Build.Module,
) void {
    const daemon = b.addExecutable(.{
        .name = "zaplane-daemon",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/daemon.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zaplane", .module = mod },
                .{ .name = "build_options", .module = build_options_mod },
            },
        }),
    });
    b.installArtifact(daemon);

    const daemon_step = b.step("daemon", "Run the daemon");
    const daemon_run = b.addRunArtifact(daemon);
    daemon_step.dependOn(&daemon_run.step);
    daemon_run.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        daemon_run.addArgs(args);
    }
}

fn setupCli(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
    mod: *std.Build.Module,
    build_options_mod: *std.Build.Module,
) void {
    const cli = b.addExecutable(.{
        .name = "zaplane-cli",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cli.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zaplane", .module = mod },
                .{ .name = "build_options", .module = build_options_mod },
            },
        }),
    });
    b.installArtifact(cli);

    const cli_step = b.step("cli", "Run the CLI");
    const cli_run = b.addRunArtifact(cli);
    cli_step.dependOn(&cli_run.step);
    cli_run.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        cli_run.addArgs(args);
    }
}
