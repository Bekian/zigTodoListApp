const std = @import("std");
const time = std.time;

// should be able to take the following commands:
// add <task string>
// list [--all] [--item <id>]{lists incomplete tasks by default}
// complete <id>
// delete <id>
// help command to list commands and a command as an argument for command useage

// Assumptions:
// - for the purposes of this cli a task cannot be marked as incomplete, or undo a completion status
// - the completeTask function expects an ID from the perspective as taking input from the user; it takes an ID of a task, not the index within the task list

const Task = struct { ID: u8, TaskDescription: []const u8, Creation: i64, Completed: bool };

// TODO: Review
// attempts to add a new task to the given task list
pub fn addTask(allocator: std.mem.Allocator, taskList: *std.ArrayList(Task), newTaskDescription: []const u8) !void {
    // ensure the description length is acceptable
    if (newTaskDescription.len <= 0) {
        return error.InvalidDescriptionLength;
    }
    // create a new task ID based on the current highest task ID
    const newTaskID = try getLastId(taskList.*) + 1;
    // get a new timestamp
    const newTaskCreation = time.timestamp();
    // then using that information and the provided description create a new task
    const newTask = Task{ .ID = newTaskID, .TaskDescription = try allocator.dupe(u8, newTaskDescription), .Creation = newTaskCreation, .Completed = false };
    // append the new task to the task list
    try taskList.append(newTask);
}

// TODO: Review
// currently lists all tasks by default
// lists tasks in the provided task list
// ignore allFlag value if itemID is given
pub fn listTasks(taskList: std.ArrayList(Task), allFlag: ?bool, itemID: ?u8) !void {
    if (itemID != null) { // case where a single task is listed
        const task = taskList.items[itemID.? - 1];
        std.debug.print("Task:\n", .{});
        const formattedCreationDate = try convertTimestamp(task.Creation);
        std.debug.print("ID: {}, Description: {s}, Creation: {s}, Completed: {}\n", .{ task.ID, task.TaskDescription, formattedCreationDate, task.Completed });
    } else if (allFlag == true and itemID == null) { // case where all items are listed
        std.debug.print("Tasks:\n", .{});
        for (taskList.items) |task| {
            const formattedCreationDate = try convertTimestamp(task.Creation);
            std.debug.print("ID: {}, Description: {s}, Creation: {s}, Completed: {}\n", .{ task.ID, task.TaskDescription, formattedCreationDate, task.Completed });
        }
    } else { // case where all incomplete tasks are listed
        std.debug.print("Tasks:\n", .{});
        for (taskList.items) |task| {
            if (!(task.Completed)) {
                const formattedCreationDate = try convertTimestamp(task.Creation);
                std.debug.print("ID: {}, Description: {s}, Creation: {s}, Completed: {}\n", .{ task.ID, task.TaskDescription, formattedCreationDate, task.Completed });
            }
        }
    }
}

// TODO: Review
// marks a task of specified ID as complete
// if no error then success
pub fn completeTask(taskList: std.ArrayList(Task), taskID: u8) !void {
    // check if the provided ID is valid
    if (taskList.items.len <= taskID) {
        return error.TaskIDOutOfBounds;
    }
    taskList.items[taskID - 1].Completed = true;
}

// TODO: Review if necessary
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
pub fn getLastId(taskList: std.ArrayList(Task)) !u8 {
    return taskList.getLast().ID;
}

// turns a string `True` or `False` into a bool
pub fn checkBool(inputString: []const u8) !bool {
    // Should NOT equal anything else besides these 2 values
    if (std.mem.eql(u8, inputString, "True")) {
        return true;
    } else if (std.mem.eql(u8, inputString, "False")) {
        return false;
    } else {
        // if the value is not one of these then theres a parsing error
        // tell user then crash
        std.debug.print("\n PROCCESSING ERROR: condition value invalid. Verify your source file is the correct structure.", .{});
        return error.ConditionValueInvalid;
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

// TODO: Look for optimizations
pub fn processTasks(allocator: std.mem.Allocator, fileName: std.fs.File) !std.ArrayList(Task) {
    // reader
    var buf_reader = std.io.bufferedReader(fileName.reader());
    var in_stream = buf_reader.reader();

    var taskArray = std.ArrayList(Task).init(allocator);

    // read and process the lines using the above reader
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // split line into fields
        var iter = std.mem.splitSequence(u8, line, ",");
        // task made of strings
        var taskRow: [4][]const u8 = undefined;
        var i: usize = 0;
        while (iter.next()) |word| {
            // std.debug.print("{d}, {s}\n", .{ i, word }); // debug line, leave until feature complete
            // continue if header
            if ((std.mem.eql(u8, word, "ID")) or (std.mem.eql(u8, word, "Task")) or (std.mem.eql(u8, word, "Date")) or (std.mem.eql(u8, word, "Completed"))) {
                continue;
            }
            // check index out of range
            if (i >= 4) {
                std.debug.print("\n PROCCESSING ERROR: index out of range. Verify your source file is the correct structure.", .{});
                return error.ProcessingError;
            }
            taskRow[i] = word;
            i += 1;
        }
        // validate task row length
        if (i == 0) {
            // this should occur for the header row
            continue;
        } else if (i != 4) {
            // the row length should always be equal to 4
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
    // TODO: init
    // first open the file √
    // read the items and translate them into task structs √
    // call the getLastId function or equivalent √
    // determine if the user used a repl or a command √

    // open csv with the mode set to read_write
    const currentfile = try std.fs.cwd().openFile("src/data.csv", .{ .mode = .read_write });
    defer currentfile.close();
    // get an allocator for resizing the tasklist
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var taskList = try processTasks(allocator, currentfile);
    defer taskList.deinit();

    // this only adds a task it doesnt save the new task to the file
    // try addTask(allocator, &taskList, "test");
    // get last task ID number
    // const lastID = try getLastId(taskList);
    // mark the first task as complete
    // try completeTask(taskList, 1);

    // display all the tasks
    // list all tasks
    try listTasks(taskList, true, null);
    // list only incomplete tasks
    // try listTasks(taskList, false, null);
    // list item with ID 1
    // try listTasks(taskList, false, 1);
    // test ignore true flag with task with ID 1
    // try listTasks(taskList, true, 1);

    // command: TODO: determine what command was entered
    // parse the argument if any, and compute the result
    var args = std.process.args();
    _ = args.skip(); // skip executable name
    if (args.next()) |arg| {
        // here process args
        std.debug.print("arg print: {s}\n", .{arg});
    } else {
        // here run repl
        std.debug.print("No args!\n", .{});
    }

    // repl: TODO: begin loop
    // set exit condition, ex: `exit`, `quit` etc.
    // send prompt, ex: `>>>`
    // use stdin and stdout and take input and write to terminal
    // process input command
    // if no command then tell user help and exit commands
    // repeat loop

    // TODO: finish doc'ing out the scaffold for how the app flow should work and execute
    // try addTask("src/data.csv");
    // try listTasks("src/data.csv");

    // const list = std.flag.Int("list", .{ .help = "List the created tasks", .useage = "`list` - lists uncomplete tasks by default.\n`list --all` - lists all tasks." });

    // _ = try std.flag.parse(std.process.args());
    // std.debug.print("List: {}\n", .{list.value});

    // while (args.next()) |arg| {
    //     if (std.mem.eql(u8, arg, "list")) { // if arg == list
    //         // could do func to handle list or handle
    //         if (args.next()) {
    //             while (args.next()) |innerArg1| {
    //                 if (std.mem.eql(u8, innerArg1[0..2], "--")) { //TODO: this could be standardized for every command argument
    //                     // determine command arg here, `all` or `item`
    //                     if (std.mem.eql(u8, innerArg1[2..6], "all")) {
    //                         //TODO: list all here
    //                     } else if (std.mem.eql(u8, innerArg1[2..7], "item")) {
    //                         while (args.next()) |innerArg2| {
    //                             std.debug.print("{s}", .{innerArg2});
    //                             //TODO: attempt to use arg to find a specific item in the array
    //                             //TODO: something like: const item = findItem(taskArray, innerArg2)
    //                         }
    //                     } else {
    //                         //TODO: here the user entered `--` but no valid command, throw `help list`
    //                     }
    //                 }
    //             }
    //         } else {
    //             //TODO: here no arguements were provided so we just list the incomplete items
    //         }
    //     } else if (std.mem.eql(u8, arg, "add")) { // if arg == add
    //         //TODO: check if theres an additional arg and make a new task and add that to the array
    //         //TODO: otherwise throw `help add`
    //     } else if (std.mem.eql(u8, arg, "delete")) { // if arg == delete
    //         //TODO: check if theres an additional arg and check if its a valid ID then delete from the array
    //         //TODO: if an ID is provided and its invalid throw invalid ID message
    //         //TODO: otherwise no ID provided, throw `help delete`
    //     } else if (std.mem.eql(u8, arg, "complete")) { // if arg == complete
    //         //TODO: check if theres an additional arg and check if its a valid ID then change the bool flag to true
    //         //TODO: if an ID is provided and its invalid throw invalid ID message
    //         //TODO: otherwise no ID provided, throw `help delete`
    //     } else if (std.mem.eql(u8, arg, "help")) { // if arg == help
    //         //TODO: check if theres an additional arg
    //         if (args.next()) {
    //             // TODO:check which subcommand is listed, similar to the checking on the higher scope of this check
    //             // TODO:then throw each commands help message
    //             // TODO: otherwise throw command not found and simple help useage
    //         } else {
    //             //TODO: list basic help command
    //         }
    //     } else {
    //         // TODO: list basic help command
    //     }
    // }

    for (taskList.items) |task| {
        allocator.free(task.TaskDescription);
    }
}
