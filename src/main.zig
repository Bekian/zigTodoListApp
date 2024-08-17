const std = @import("std");
const time = std.time;

// should be able to take the following commands:
// add <task string arg>
// list <optional all> {lists incomplete tasks by default}
// complete <id>
// delete <id>
// help command to list commands and a command as an argument for command useage

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

// converts a time.timestamp() i64 to a human readable string
pub fn convertTimestamp(timestamp: i64) ![]const u8 {
    const eSeconds = time.epoch.EpochSeconds{ .secs = @intCast(timestamp) };
    // convert the timestamp to a readable format
    const eDayCreationTime = time.epoch.EpochSeconds.getEpochDay(eSeconds).calculateYearDay();
    const creationMonth = try findMonth(eDayCreationTime.calculateMonthDay().month);
    const creationDay = eDayCreationTime.calculateMonthDay().day_index;
    const creationYear = eDayCreationTime.year;
    var formattingBuffer: [20]u8 = undefined;
    return try std.fmt.bufPrint(&formattingBuffer, "{s} {d} {d}", .{ creationMonth, creationDay, creationYear });
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
    // TODO: this should be moved to a higher scope postion
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

    // get unix timestamp in seconds
    const creationTimeStamp = time.timestamp();
    // this timestamp is used to show to the user, we write the above timestamp to the file
    const formattedTimeStamp = convertTimestamp(creationTimeStamp);

    // get the ID of the new item

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
            try stdout.print("Task: {s}! at time {s}\n", .{ user_input, formattedTimeStamp });

            // trim any trailing newline
            const trimmed_output = std.mem.trimRight(u8, user_input, "\r\n");
            var newLineBuffer: [150]u8 = undefined; // trying this length and i'll adjust the size if necessary
            // get ID
            const newTaskLine = try std.fmt.bufPrint(&newLineBuffer, "{s}\t\t{d}", .{ trimmed_output, creationTimeStamp });

            // write the trimmed output to the file
            try out_stream.print("\n{s}", .{newTaskLine});
        } else {
            // if the user didnt provide a task, then inform the user of this.
            std.debug.print("No task provided, try again.", .{});
            // TODO: invalidCommand should be ran after this, here or repl
        }
    }
    // flush the writer (the writer is like a cache that must be cleared)
    try buf_writer.flush();
}

// switchcase to return the string name of a month
pub fn findMonth(month: std.time.epoch.Month) ![]const u8 {
    switch (month) {
        .jan => {
            return "January";
        },
        .feb => {
            return "February";
        },
        .mar => {
            return "March";
        },
        .apr => {
            return "April";
        },
        .may => {
            return "May";
        },
        .jun => {
            return "June";
        },
        .jul => {
            return "July";
        },
        .aug => {
            return "August";
        },
        .sep => {
            return "September";
        },
        .oct => {
            return "October";
        },
        .nov => {
            return "November";
        },
        .dec => {
            return "December";
        },
    }
}

// this will be ran when an invalid command is ran
pub fn invalidCommand() void {}

// Gets the last ID in the file as a string
pub fn getLastId(tasks: []Task) ![]const u8 {
    _ = tasks; // autofix

}

pub fn main() !void {
    // TODO: init
    // first open the file
    // read the items and translate them into task structs
    // call the getLastId function or equivalent
    // determie if the user used a repl or a command

    // command: TODO: determine what command was entered
    // parse the argument if any, and compute the result

    // repl: TODO: begin loop
    // set exit condition, ex: `exit`, `quit` etc.
    // send prompt, ex: `>>>` or `task >>>`
    // use stdin and stdout and take input and write to terminal
    // process input command
    // if no command then tell user help and exit commands
    // repeat loop

    // TODO: finish doc'ing out the scaffold for how the app flow should work and execute
    // try addTask("src/data.csv");
    // try listTasks("src/data.csv");
    var args = std.process.args();
    _ = args.skip(); // Skip the program name
    // const list = std.flag.Int("list", .{ .help = "List the created tasks", .useage = "`list` - lists uncomplete tasks by default.\n`list --all` - lists all tasks." });

    // _ = try std.flag.parse(std.process.args());
    // std.debug.print("List: {}\n", .{list.value});

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "list")) { // if arg list
            // could do func to handle list or handle
            while (args.next()) |innerArg1| {
                if (std.mem.eql(u8, innerArg1[0..2], "--")) {
                    // determine command arg here, `all` or `item`
                    if (std.mem.eql(u8, innerArg1[2..6], "all")) {
                        // list all here
                    } else if (std.mem.eql(u8, innerArg1[2..7], "item")) {
                        while (args.next()) |innerArg2| {
                            _ = innerArg2; // autofix
                            // attempt to use arg to find a specific item in the array
                        }
                    }
                }
            }
        }
    }
}
