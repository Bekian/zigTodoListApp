// this is an attempt to minify the main.zig file, keeping as much of the functionality while reducing the amount of logic and code as much as possible
// currently 151 lines of code without comments as of writing. ill do this again when the app is `finished` and attempt to reduce code size.
const std = @import("std");
const time = std.time;

const Task = struct { ID: u8, TaskDescription: []const u8, Creation: i64, Completed: bool };

pub fn addTask(allocator: std.mem.Allocator, taskList: *std.ArrayList(Task), newTaskDescription: []const u8) !void {
    if (newTaskDescription.len <= 0) {
        return error.InvalidDescriptionLength;
    }
    const newTaskID = try getLastId(taskList.*) + 1;
    const newTaskCreation = time.timestamp();
    const newTask = Task{ .ID = newTaskID, .TaskDescription = try allocator.dupe(u8, newTaskDescription), .Creation = newTaskCreation, .Completed = false };
    try taskList.append(newTask);
}

pub fn listTasks(taskList: std.ArrayList(Task)) !void {
    std.debug.print("Tasks:\n", .{});
    for (taskList.items) |task| {
        const formattedCreationDate = try convertTimestamp(task.Creation);
        std.debug.print("ID: {}, Description: {s}, Creation: {s}, Completed: {}\n", .{ task.ID, task.TaskDescription, formattedCreationDate, task.Completed });
    }
}

pub fn completeTask(taskList: std.ArrayList(Task), taskID: u8) !void {
    if (taskList.items.len <= taskID) {
        return error.TaskIDOutOfBounds;
    }
    taskList.items[taskID - 1].Completed = true;
}

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

pub fn getLastId(taskList: std.ArrayList(Task)) !u8 {
    return taskList.getLast().ID;
}

pub fn checkBool(inputString: []const u8) !bool {
    if (std.mem.eql(u8, inputString, "True")) {
        return true;
    } else if (std.mem.eql(u8, inputString, "False")) {
        return false;
    } else {
        std.debug.print("\n PROCCESSING ERROR: condition value invalid. Verify your source file is the correct structure.", .{});
        return error.ConditionValueInvalid;
    }
}

pub fn convertTimestamp(timestamp: i64) ![]const u8 {
    const eSeconds = time.epoch.EpochSeconds{ .secs = @intCast(timestamp) };
    const eDayCreationTime = time.epoch.EpochSeconds.getEpochDay(eSeconds).calculateYearDay();
    const creationMonth = try findMonth(eDayCreationTime.calculateMonthDay().month);
    const creationDay = eDayCreationTime.calculateMonthDay().day_index;
    const creationYear = eDayCreationTime.year;
    var formattingBuffer: [20]u8 = undefined;
    return try std.fmt.bufPrint(&formattingBuffer, "{s} {d} {d}", .{ creationMonth, creationDay, creationYear });
}

pub fn processTasks(allocator: std.mem.Allocator, fileName: std.fs.File) !std.ArrayList(Task) {
    var buf_reader = std.io.bufferedReader(fileName.reader());
    var in_stream = buf_reader.reader();
    var taskArray = std.ArrayList(Task).init(allocator);
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.splitSequence(u8, line, ",");
        var taskRow: [4][]const u8 = undefined;
        var i: usize = 0;
        while (iter.next()) |word| {
            if ((std.mem.eql(u8, word, "ID")) or (std.mem.eql(u8, word, "Task")) or (std.mem.eql(u8, word, "Date")) or (std.mem.eql(u8, word, "Completed"))) {
                continue;
            }
            if (i >= 4) {
                std.debug.print("\n PROCCESSING ERROR: index out of range. Verify your source file is the correct structure.", .{});
                return error.ProcessingError;
            }
            taskRow[i] = word;
            i += 1;
        }
        if (i == 0) {
            continue;
        } else if (i != 4) {
            std.debug.print("\n PROCCESSING ERROR: not enough fields. Verify your source file is the correct structure.", .{});
            return error.ProcessingError;
        }
        const taskId = try std.fmt.parseInt(u8, taskRow[0], 10);
        const description = taskRow[1];
        const creationTime = try std.fmt.parseInt(i64, taskRow[2], 10);
        const initialCompletionStatus = try checkBool(taskRow[3]);
        const newTask = Task{ .ID = taskId, .TaskDescription = try allocator.dupe(u8, description), .Creation = creationTime, .Completed = initialCompletionStatus };
        try taskArray.append(newTask);
    }
    return taskArray;
}

pub fn main() !void {
    const currentfile = try std.fs.cwd().openFile("src/data.csv", .{ .mode = .read_write });
    defer currentfile.close();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var taskList = try processTasks(allocator, currentfile);
    defer taskList.deinit();
    var args = std.process.args();
    _ = args.skip(); // skip executable name
    if (args.next()) |arg| {
        std.debug.print("arg print: {s}\n", .{arg});
    } else {
        std.debug.print("No args!\n", .{});
    }
    for (taskList.items) |task| {
        allocator.free(task.TaskDescription);
    }
}
