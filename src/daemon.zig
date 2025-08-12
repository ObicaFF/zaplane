const std = @import("std");
const log = std.log;
const Request = std.http.Server.Request;
const Connection = std.net.Server.Connection;

const MAX_BUF = 1024;

pub fn main() !void {
    const addr = try std.net.Address.parseIp("127.0.0.1", 8080);
    var listener = try std.net.Address.listen(addr, .{ .reuse_address = true });
    defer listener.deinit();

    log.info("Start HTTP server at {any}", .{addr});

    while (true) {
        const conn = listener.accept() catch |err| {
            log.err("failed to accept connection: {s}", .{@errorName(err)});
            continue;
        };

        accept(conn) catch |err| {
            log.err("connection error: {s}", .{@errorName(err)});
            conn.stream.close();
        };
    }
}

fn accept(conn: Connection) !void {
    defer conn.stream.close();

    var rbuf: [MAX_BUF]u8 = undefined;
    var wbuf: [MAX_BUF]u8 = undefined;
    var r = conn.stream.reader(&rbuf);
    var w = conn.stream.writer(&wbuf);
    var server = std.http.Server.init(r.interface(), &w.interface);

    while (true) {
        var request = server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => return err,
        };

        if (request.head.method == .GET and std.mem.eql(u8, request.head.target, "/ping")) {
            try respondText(&request, .ok, "pong\n");
        } else {
            try respondText(&request, .not_found, "not found\n");
        }
    }
}

fn respondText(req: *Request, status: std.http.Status, body: []const u8) !void {
    try req.respond(body, .{
        .status = status,
        .extra_headers = &.{.{ .name = "content-type", .value = "text/plain; charset=utf-8" }},
    });
}
