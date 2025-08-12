const std = @import("std");
const build_options = @import("build_options");

pub const Command = enum { init, watch, help, version };

pub fn main() !void {
    var gpa_imp: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const gpa = gpa_imp.allocator();

    const args = std.process.argsAlloc(gpa) catch oom();
    defer std.process.argsFree(gpa, args);

    const cmd = std.meta.stringToEnum(Command, args[1]) orelse {
        std.debug.print("unrecognized subcommand: '{s}'\n\n", .{args[1]});
        fatalHelp();
    };

    _ = switch (cmd) {
        .help => fatalHelp(),
        .version => print(.{build_options.version}),
    };
}

fn oom() noreturn {
    fatal("oom\n", .{});
}

fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print(fmt, args);
    std.process.exit(1);
}

fn fatalHelp() noreturn {
    fatal(
        \\ Commands:
        \\  install 
        \\  Watch
        \\  Help
        \\  Version
    , .{});
}

fn print(msg: []const u8) noreturn {
    std.debug.print("{s}\n", .{msg});
    std.process.exit(0);
}
