const std = @import("std");
const zaplane = @import("zaplane");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}
