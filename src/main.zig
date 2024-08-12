const std = @import("std");

// should be able to take the following commands:
// add <task string arg>
// list <optional all> {lists incomplete tasks by default}
// complete <id>
// delete <id>

pub fn listTasks() !void {
    // open csv
    const file = try std.fs.cwd().openFile("src/data.csv", .{});
    defer file.close();

    // reader
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    // read and process the lines using the above reader
    var buf: [1024]u8 = undefined;
    std.debug.print("\n", .{});
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // split line into fields
        var iter = std.mem.splitSequence(u8, line, ",");
        while (iter.next()) |field| {
            if (field.len >= 20) {
                std.debug.print("{s}\t", .{field});
            } else if (field.len > 15) {
                std.debug.print("{s}\t", .{field});
            } else if (field.len > 5) {
                std.debug.print("{s}\t\t", .{field});
            } else {
                std.debug.print("{s}\t\t", .{field});
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    try listTasks();
}
