const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // opens the src directory handling errors with try
    var iter_dir = try fs.cwd().openDir("src", .{ .iterate = true });
    defer iter_dir.close(); // Ensures the direcotry is closed when the function returns.

    // Initalizes a directory walker using the allocator
    var walker = try iter_dir.walk(allocator);
    defer walker.deinit(); // Ensurs the walker is deinitialized when done

    const now = std.time.nanoTimestamp(); // Current time in nanoseconds

    while (try walker.next()) |entry| {
        if (entry.kind != .file) {
            continue;
        }

        // Gets file statistics handling erros with try
        const stat = try iter_dir.statFile(entry.path);

        // get last modified time of file
        const last_modified = stat.mtime;

        // checks if modified in last 24 hours
        const duration = now - last_modified;
        if (duration < std.time.ns_per_hour * 24) {
            print("Last modified: {d} seconds ago, size:{d} bytes, filename: {s}\n", .{
                @divTrunc(duration, std.time.ns_per_s), // Converts nanoseconds to seconds
                stat.size,
                entry.path,
            });
        }
    }
}
