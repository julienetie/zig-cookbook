const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const filename = "/tmp/zig-cookbook-01-02.txt";

pub fn main() !void {

    // Windows check
    // Checks if operating system is windows and if so prints a message and exists
    // because memory mapping (mmap) is not supported on windows in this example.
    if (.windows == @import("builtin").os.tag) {
        print("MMap is not supported in Windows\n", .{});
        return;
    }

    // Cratees or opens the file in the current working directory
    // .read: The file is opened with read permissions
    // .truncate: The file is truncated (empitied) if it alaredy exist
    // .exclusive Ensure the file is created by this program if set to true
    const file = try fs.cwd().createFile(filename, .{
        .read = true,
        .truncate = true,
        .exclusive = false,
    });
    defer file.close();

    const content_to_write = "hello zig cookbook";

    // Sets the file size to the length of the string
    try file.setEndPos(content_to_write.len);

    // rerieves metadata of the file
    const md = try file.metadata();

    // Checks if file size matches length of content to write
    try std.testing.expectEqual(md.size(), content_to_write.len);

    // - ptr: maps the file in memory
    // - content_to_write.len
    // - std.posix...: Read and write permissions
    // - .{ .TYP = .SHARED }: Shared mapping type
    // - file.handle: the file discriptor
    // - 0: Offset in the file to start mapping
    const ptr = try std.posix.mmap(
        null,
        content_to_write.len,
        std.posix.PROT.READ | std.posix.PROT.WRITE,
        .{ .TYPE = .SHARED },
        file.handle,
        0,
    );

    // Ensure the memory is unmapped with defer
    defer std.posix.munmap(ptr);

    // Copies the content of content_to_write into the memory mapped area
    std.mem.copyForwards(u8, ptr, content_to_write);

    try std.testing.expectEqualStrings(content_to_write, ptr);
}
