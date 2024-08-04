const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const heap = std.heap;

pub fn main() !void {
    // Creates an instance of general purpose allocator which is a heap allocator.
    // Defer ensures the allocator is deinitalized when the main function exits.
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // `allocator` provides access to the allocator for memory mamagement
    const allocator = gpa.allocator();

    // Opens the file in the current working directory
    // `try` handels potential errors
    const file = try fs.cwd().openFile("tests/zig-zen.txt", .{});
    defer file.close(); // Closes file when main exits

    // Wraps the file reader in a buffered reader to imporve performance
    // by reading large chunks of data at once.
    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    // Line is an arraylist used to dynamically store bytes of each line
    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    // Writer is a writer for the line buffer
    const writer = line.writer();

    // line_no is a counter for the current line number
    var line_no: usize = 0;

    // Reads from the file unitl it encounters a newline character. Each line is stored in the line buffer
    while (reader.streamUntilDelimiter(writer, '\n', null)) {
        defer line.clearRetainingCapacity(); // Clears the buffer for the next line whilst retaining it's allocated capacity
        line_no += 1;
        print("{d}--{s}\n", .{ line_no, line.items });
    } else |err| switch (err) {
        error.EndOfStream => { // If the error is end of stream it means the end of the file was reached.
            if (line.items.len > 0) {
                line_no += 1;
                print("{d}--{s}\n", .{ line_no, line.items }); // If there are remaining items in the buffer it prints them.
            }
        },
        else => return err, // Any other errors are returend to propagate them up the call stack
    }

    print("Total lines: {d}\n", .{line_no});
}
