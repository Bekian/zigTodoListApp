const std = @import("std");
const time = std.time;

// should be able to take the following commands:
// add <task string arg>
// list <optional all> {lists incomplete tasks by default}
// complete <id>
// delete <id>

const Task = struct { ID: u8, TaskDescription: []u8, Creation: std.time.Timer, Completed: bool };

pub fn printWord(word: []const u8) !void {
    if (word.len >= 20) {
        std.debug.print("{s}\t", .{word});
    } else if (word.len > 14) {
        std.debug.print("{s}\t", .{word});
    } else if (word.len > 9) {
        std.debug.print("{s}\t\t", .{word});
    } else {
        std.debug.print("{s}\t\t\t", .{word});
    }
}

pub fn listTasks(file: []const u8) !void {
    // open csv
    const currentfile = try std.fs.cwd().openFile(file, .{});
    defer currentfile.close();

    // reader
    var buf_reader = std.io.bufferedReader(currentfile.reader());
    var in_stream = buf_reader.reader();

    // read and process the lines using the above reader
    var buf: [1024]u8 = undefined;
    std.debug.print("\n", .{});
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // split line into fields
        var iter = std.mem.splitSequence(u8, line, ",");
        while (iter.next()) |field| {
            try printWord(field);
        }
        std.debug.print("\n", .{});
    }
}

pub fn addTask(file: []const u8) !void {
    // open csv with the mode set to read_write
    const currentfile = try std.fs.cwd().openFile(file, .{ .mode = .read_write });
    // defer closing
    defer currentfile.close();
    // jump to the end of the file
    try currentfile.seekFromEnd(0);
    // create a buffered writer for the current file (to write to the file)
    var buf_writer = std.io.bufferedWriter(currentfile.writer());
    // get the generic writer from buffered writer (idk why we need to do this)
    var out_stream = buf_writer.writer();

    // get a timestamp and make it human readable
    // get unix timestamp in seconds
    const creationTimeStamp = time.timestamp();
    const eSeconds = time.epoch.EpochSeconds{ .secs = @intCast(creationTimeStamp) };
    // convert the timestamp to a readable format
    const eDayCreationTime = time.epoch.EpochSeconds.getEpochDay(eSeconds).calculateYearDay();
    const creationMonth = findMonth(eDayCreationTime.calculateMonthDay().month);
    _ = creationMonth; // autofix
    // TODO: also get the dayindex from eDayCreationTime.calculateMonthDay().month.day_index and year from eDayCreationtime.year

    // create a stdin reader and writer to read and write to and from the terminal
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    // message displayed when taking the users' input
    try stdout.print("Enter your new task: ", .{});
    // buffer of 100u8s for our buffer reader
    var buffer: [100]u8 = undefined;
    // attempt to read the user input
    if (try stdin.readUntilDelimiterOrEof(&buffer, '\n')) |user_input| {
        // only write to the file if the user entered something
        if (user_input.len >= 1) {
            // write a validation message to the user with their task
            try stdout.print("Task: {s}!\n", .{user_input});

            // trim any trailing newline
            const trimmed_output = std.mem.trimRight(u8, user_input, "\r\n");
            var newLineBuffer: [150]u8 = undefined; // trying this length and i'll adjust the size if necessary
            const newTaskLine = try std.fmt.bufPrint(&newLineBuffer, "{s}\t\t{any}!", .{ trimmed_output, eDayCreationTime.calculateMonthDay() });

            // write the trimmed output to the file
            try out_stream.print("\n{s}", .{newTaskLine});
        } else {
            // if the user didnt provide a task, then inform the user of this.
            std.debug.print("No task provided, try again.", .{});
        }
    }
    // flush the writer (the writer is like a cache that must be cleared)
    try buf_writer.flush();
}

pub fn findMonth(month: std.time.epoch.Month) ![]u8 {
    _ = month; // autofix
    // switchcase to return the []u8 array of a month
}

pub fn main() !void {
    try addTask("src/data.csv");
    try listTasks("src/data.csv");
}
