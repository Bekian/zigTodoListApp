const std = @import("std");
const time = std.time;

// should be able to take the following commands:
// add <task string>
// list [--all] [--item <id>]{lists incomplete tasks by default}
// complete <id>
// delete <id>
// help command to list commands and a command as an argument for command useage

// Assumptions:
// - for the purposes of this cli a task cannot be marked as incomplete, or undo a completed status
// - the completeTask function expects an ID from the perspective as taking input from the user; it takes an ID of a task, not the index within the task list
// - the ID is roughly equal to the index of the task + 1, and is dynamically calculated

const Task = struct { ID: u8, TaskDescription: []const u8, Creation: i64, Completed: bool };

const processError = error{
    InvalidCharacter,
    Overflow,
    InvalidItemID,
    InvalidDescriptionLength,
    TaskIDOutOfBounds,
    ProcessingError,
    ConditionValueInvalid,
    NoItemIDProvided,
    InvalidFlagArgs,
    TooManyArgs,
};

// TODO: Review
// attempts to add a new task to the given task list
pub fn addTask(allocator: std.mem.Allocator, taskList: *std.ArrayList(Task), newTaskDescription: []const u8) !void {
    // ensure the description length is acceptable
    if (newTaskDescription.len <= 0) {
        return processError.InvalidDescriptionLength;
    }
    // this may be imperfect
    const newTaskID = getLastId(taskList.*) + 1;
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
        if (itemID.? > taskList.items.len or itemID.? < 1) {
            return processError.TaskIDOutOfBounds;
        } else {
            const task = taskList.items[itemID.? - 1];
            std.debug.print("Task:\n", .{});
            const formattedCreationDate = try convertTimestamp(task.Creation);
            std.debug.print("ID: {?}, Description: {s}, Creation: {s}, Completed: {any}\n", .{ itemID.?, task.TaskDescription, formattedCreationDate, task.Completed });
        }
    } else if (allFlag == true and itemID == null) { // case where all items are listed
        std.debug.print("Tasks:\n", .{});
        for (taskList.items) |task| {
            const formattedCreationDate = try convertTimestamp(task.Creation);
            std.debug.print("ID: {d}, autofix: {s}, Creation: {s}, Completed: {any}\n", .{ task.ID, task.TaskDescription, formattedCreationDate, task.Completed });
        }
    } else { // default case where only incomplete tasks are listed
        std.debug.print("Tasks:\n", .{});
        for (taskList.items) |task| {
            if (!(task.Completed)) {
                const formattedCreationDate = try convertTimestamp(task.Creation);
                std.debug.print("ID: {d}, Description: {s}, Creation: {s}, Completed: {any}\n", .{ task.ID, task.TaskDescription, formattedCreationDate, task.Completed });
            }
        }
    }
}

// TODO: Review
// marks a task of specified ID as complete
// if no error then success
pub fn completeTask(taskList: std.ArrayList(Task), taskID: u8) !void {
    // check if the provided ID is valid
    if (taskID > taskList.items.len) {
        return processError.TaskIDOutOfBounds;
    }
    taskList.items[taskID - 1].Completed = true;
}

// TODO: Review
// deletes a task from the provided list at the provided ID
pub fn deleteTask(allocator: std.mem.Allocator, taskList: *std.ArrayList(Task), taskID: u8) !void {
    // with calculated IDs we only need to check the bounds and not search within the arraylist for a task to delete
    if (taskID <= 0 or taskID > taskList.items.len) {
        return processError.TaskIDOutOfBounds;
    }
    const task = taskList.items[taskID - 1];
    _ = taskList.orderedRemove(taskID - 1);
    allocator.free(task.TaskDescription);
}

// TODO: WIP
// list available commands, shortcuts and basic usage
// allows for flags to be used to give more detail about specific commands
pub fn help(chosenCommand: ?u8) void {
    if (chosenCommand == null) {
        std.debug.print("Run command `help <command>` to list details about a command or `help` to list all commands\n", .{});
    } else if (chosenCommand == 0) {
        // list all commands
        std.debug.print("Commands:\n", .{});
        std.debug.print("add - add a new task to the list\n", .{});
        std.debug.print("list - list all tasks\n", .{});
        std.debug.print("complete - mark a task as complete\n", .{});
        std.debug.print("delete - delete a task\n", .{});
        std.debug.print("help - list all commands\n", .{});
    } else if (chosenCommand == 1) {
        // list add task command useage
        std.debug.print("add <task string> - add a new task to the list\n", .{});
    } else if (chosenCommand == 2) {
        // list list tasks command useage
        std.debug.print("list [--all] [--item <id>] lists incomplete tasks by default\n", .{});
    } else if (chosenCommand == 3) {
        // list complete task command useage
        std.debug.print("complete <id> - mark a task as complete\n", .{});
    } else if (chosenCommand == 4) {
        // list delete task command useage
        std.debug.print("delete <id> - delete a task\n", .{});
    } else {
        // see details about more how this should work in the main block
        std.debug.print("help <command> - list details about a command\n", .{});
    }
}

// this will be ran when an invalid command is ran
pub fn invalidCommand(inputCommand: []const u8) !void {
    std.debug.print("ERROR: command `{s}` not found, type `help` for a list of commands\n", .{inputCommand});
    help(0);
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

// gets the last ID in the file as a string
pub fn getLastId(taskList: std.ArrayList(Task)) u8 {
    return taskList.getLast().ID;
}

// turns a string `True` or `False` into a bool
pub fn parseBool(inputString: []const u8) !bool {
    // should NOT equal anything else besides these 2 values
    if (std.mem.eql(u8, inputString, "True")) {
        return true;
    } else if (std.mem.eql(u8, inputString, "False")) {
        return false;
    } else {
        // if the value is not one of these then theres a parsing error
        // tell user then crash
        std.debug.print("\n PROCCESSING ERROR: condition value invalid. Verify your source file is the correct structure.", .{});
        return processError.ConditionValueInvalid;
    }
}

// turns a bool into a string `True` or `False`
// assume input is valid
pub fn unparseBool(inputBool: bool) []const u8 {
    if (inputBool) {
        return "True";
    } else {
        return "False";
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
    // return the formatted string
    return try std.fmt.bufPrint(&formattingBuffer, "{s} {d} {d}", .{ creationMonth, creationDay, creationYear });
}

// TODO: Look for optimizations
pub fn parseTasks(allocator: std.mem.Allocator, fileName: std.fs.File) !std.ArrayList(Task) {
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
                return processError.ProcessingError;
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
            return processError.ProcessingError;
        }
        // parse the string values into the correct types
        const taskId = try std.fmt.parseInt(u8, taskRow[0], 10);
        const description = taskRow[1];
        const creationTime = try std.fmt.parseInt(i64, taskRow[2], 10);
        const initialCompletionStatus = try parseBool(taskRow[3]);
        // use the parsed values to create a new task
        const newTask = Task{ .ID = taskId, .TaskDescription = try allocator.dupe(u8, description), .Creation = creationTime, .Completed = initialCompletionStatus };
        // append the new task to the task array
        try taskArray.append(newTask);
    }
    return taskArray;
}

// parse the arguments
pub fn parseArgs(args: [][:0]const u8, allocator: std.mem.Allocator, taskList: *std.ArrayList(Task)) !bool {
    // if there are args
    if (args.len > 0) {
        // get the first arg
        const arg = args[1];
        // log the command used
        std.debug.print("Args used: `{s}`\n", .{args[1..args.len]}); // keep until feature complete
        // parse which arg was used
        // TODO: review
        if (std.mem.eql(u8, arg, "add")) {
            // get the task description from the remaining args, everything after add until the end of the array
            // and join them into a single string
            const taskDescription = try std.mem.join(allocator, " ", args[2..args.len]);
            // attempt to add a task
            addTask(allocator, @constCast(taskList), taskDescription) catch |err| {
                return err;
            };
        } else if (std.mem.eql(u8, arg, "list")) {
            // TODO: list command complete
            if (args.len < 3) {
                // if no flags then list incomplete tasks by default
                try listTasks(taskList.*, false, null);
                return false;
            } else if (args.len >= 5) {
                // here the user has entered too many args
                return processError.TooManyArgs;
            }
            // otherwise check which flags are used
            const arg2 = args[2];
            // if the all flag is used then list all tasks
            if (std.mem.eql(u8, arg2, "--all") or std.mem.eql(u8, arg2, "-a")) {
                try listTasks(taskList.*, true, null);
            } else if (std.mem.eql(u8, arg2, "--item") or std.mem.eql(u8, arg2, "-i")) {
                // then check if the item id flag is used
                // first validate the args length and ensure there is an item id provided
                if (args.len < 4) {
                    return processError.NoItemIDProvided;
                }
                // then try to parse the item id from the args
                const arg3 = args[3];
                const itemID = std.fmt.parseInt(u8, arg3, 10) catch |err| {
                    return err;
                };
                // then try to list the task with the provided item id
                listTasks(taskList.*, false, itemID) catch |err| {
                    return err;
                };
            } else {
                // here we've already validated any correct flag arguments, so the user must have entered an invalid flag
                // a common approach here would be to just run the list command without flags
                // but i'd like to provide "realistic" behavior and enforce syntax rules
                return processError.InvalidFlagArgs;
            }
        } else if (std.mem.eql(u8, arg, "complete")) {
            // TODO: complete command complete
            // provide proper error messages if the args aren't correct
            if (args.len < 3) {
                return processError.NoItemIDProvided;
            } else if (args.len > 3) {
                return processError.TooManyArgs;
            }
            // from here we can assume the args amount is correct
            // we just need to attempt to parse the item id and complete the task
            const arg2 = args[2];
            const itemID = std.fmt.parseInt(u8, arg2, 10) catch |err| {
                return err;
            };
            completeTask(taskList.*, itemID) catch |err| {
                return err;
            };
        } else if (std.mem.eql(u8, arg, "delete")) {
            if (args.len > 1) {
                const arg2 = try std.fmt.parseInt(u8, args[2], 10);
                std.debug.print("arg2: {any}\n", .{arg2});
                try deleteTask(allocator, taskList, arg2);
            } else {
                return processError.NoItemIDProvided;
            }
        } else if (std.mem.eql(u8, arg, "help")) {
            if (args.len > 1) {
                const arg2 = args[1];
                help(try std.fmt.parseInt(u8, arg2, 10));
            } else {
                help(0);
            }
        } else {
            try invalidCommand(arg);
        }
        return false;
    } else {
        // here run repl
        std.debug.print("No args!\n", .{});
        return true;
    }
}

pub fn main() !void {
    // Init
    // open csv with the mode set to read_write
    const currentfile = try std.fs.cwd().openFile("src/data.csv", .{ .mode = .read_write });
    defer currentfile.close();
    // get an allocator for resizing the tasklist
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // process the tasks using the provided allocator and csv file into a task arraylist
    var taskList = try parseTasks(allocator, currentfile);
    defer taskList.deinit();

    // this only adds a task it doesnt save the new task to the file
    // try addTask(allocator, &taskList, "test");
    // get last task ID number
    // const lastID = getLastId(taskList);
    // mark the first task as complete
    // try completeTask(taskList, 1);

    // deletes a single task
    // try deleteTask(allocator, &taskList, 2);

    // display all the tasks
    // list all tasks
    // try listTasks(taskList, true, null);
    // list only incomplete tasks
    // try listTasks(taskList, false, null);
    // list item with ID 1
    // try listTasks(taskList, false, 1);
    // test ignore true flag with task with ID 1
    // try listTasks(taskList, true, 1);

    // command: TODO: determine what command was entered
    // parse the argument if any, and compute the result
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    // std.debug.print("Args: {s}\n", .{args}); // keep until feature complete

    // repl picked if there is no args
    // args[0] is the program name so we need at least 2 total args
    if (args.len < 2) {
        // std.debug.print("Repl picked!\n", .{}); // keep until feature complete
        // repl: TODO: begin loop √
        // set exit condition, ex: `exit`, `quit` etc. √
        // send prompt, ex: `>>>` √
        // use stdin and stdout and take input and write to terminal √
        // process input command WIP
        // if no command then tell user help and exit commands
        // repeat loop
        var repl_running = true;
        const stdin = std.io.getStdIn().reader();

        while (repl_running) {
            std.debug.print(">>> ", .{});
            var input_buffer: [1024]u8 = undefined;
            const input = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');

            if (input) |command| {
                const trimmed_command = std.mem.trim(u8, command, &std.ascii.whitespace);
                if (std.mem.eql(u8, trimmed_command, "exit") or std.mem.eql(u8, trimmed_command, "quit")) {
                    repl_running = false;
                } else if (trimmed_command.len == 0) {
                    std.debug.print("Enter a command. Type 'help' for available commands or 'exit' to quit.\n", .{});
                } else {
                    // process the command
                    std.debug.print("Received command: {s}\n", .{trimmed_command});
                    _ = parseArgs(args, allocator, &taskList) catch |err| {
                        std.debug.print("error caught: {any}\n", .{err});
                        switch (err) {
                            error.InvalidCharacter => {
                                std.debug.print("Provided ItemID is NaN, try again\nItemID provided: {s}\n", .{args[3]});
                            },
                            error.Overflow => {
                                std.debug.print("Provided ItemID is outside the range of u8, try again\nItemID provided: {s}\n", .{args[3]});
                            },
                            processError.InvalidItemID => {
                                std.debug.print("Invalid item ID, itemID provided: {s}\n", .{args[3]});
                            },
                            processError.InvalidDescriptionLength => {
                                std.debug.print("Invalid description length: {any}\n", .{err});
                            },
                            processError.TaskIDOutOfBounds => {
                                std.debug.print("Task ID out of bounds: {any}\n", .{err});
                            },
                            processError.NoItemIDProvided => {
                                std.debug.print("No item ID provided: {any}\n", .{err});
                            },
                            processError.InvalidFlagArgs => {
                                std.debug.print("Invalid flag arguments: {any}\n", .{err});
                            },
                            processError.TooManyArgs => {
                                std.debug.print("Too many flags provided: {any}\n", .{err});
                            },
                            else => {
                                std.debug.print("ERROR: {any}\n", .{err});
                            },
                        }
                        // turn off repl and log help cmd
                        repl_running = false;
                        help(null);
                    };
                }
            } else {
                repl_running = false; // Exit on EOF
            }
        }
    } else {
        // std.debug.print("repl not picked!\n", .{}); // keep until feature complete
        // here run commands
        _ = parseArgs(args, allocator, &taskList) catch |err| {
            // std.debug.print("error caught: {any}\n", .{err}); // keep until feature complete
            std.debug.print("ERROR: ", .{});
            switch (err) {
                error.InvalidCharacter => {
                    std.debug.print("Provided ItemID is NaN, try again\nItemID provided: {s}\n", .{args[2]});
                },
                error.Overflow => {
                    std.debug.print("Provided ItemID is outside the range of u8, try again\nItemID provided: {s}\n", .{args[3]});
                },
                processError.InvalidItemID => {
                    std.debug.print("Invalid item ID, itemID provided: {s}\n", .{args[3]});
                },
                processError.InvalidDescriptionLength => {
                    std.debug.print("Invalid description length: {any}\n", .{err});
                },
                processError.TaskIDOutOfBounds => {
                    std.debug.print("Task ID out of bounds: {any}\n", .{err});
                },
                processError.NoItemIDProvided => {
                    std.debug.print("No item ID provided: {any}\n", .{err});
                },
                processError.InvalidFlagArgs => {
                    std.debug.print("Invalid flag arguments: {any}\n", .{err});
                },
                processError.TooManyArgs => {
                    std.debug.print("Too many flags provided: {any}\n", .{err});
                },
                else => {
                    std.debug.print("ERROR: {any}\n", .{err});
                },
            }
            // log help cmd
            help(null);
        };
    }

    // now we need to overwrite the file with the new task list
    // first we need to convert the task list to a string
    var taskListString = std.ArrayList(u8).init(allocator);
    defer taskListString.deinit();
    // first append the header
    try taskListString.appendSlice("ID,Task,Date,Completed\n");
    for (taskList.items) |task| {
        // append each part of the task to the string in order
        const idStr = try std.fmt.allocPrint(allocator, "{d}", .{task.ID});
        defer allocator.free(idStr);
        try taskListString.appendSlice(idStr);

        try taskListString.appendSlice(",");

        try taskListString.appendSlice(task.TaskDescription);

        try taskListString.appendSlice(",");

        const creationStr = try std.fmt.allocPrint(allocator, "{d}", .{task.Creation});
        defer allocator.free(creationStr);
        try taskListString.appendSlice(creationStr);

        try taskListString.appendSlice(",");
        // print the completed status of the task and the unparsed version of it
        std.debug.print("task.Completed: {any} ", .{task.Completed});
        std.debug.print("unparsed: {s}\n", .{unparseBool(task.Completed)});

        const completedStr = try std.fmt.allocPrint(allocator, "{s}", .{unparseBool(task.Completed)});
        defer allocator.free(completedStr);
        try taskListString.appendSlice(completedStr);

        // dont add a new line at the end of the file
        std.debug.print("task.ID: {d}, taskList.items.len: {d}\n", .{ task.ID, (taskList.items.len) }); // keep until feature complete
        if (task.ID != taskList.items.len) {
            try taskListString.appendSlice("\n");
        }
    }
    // seek to the beginning of the file and write the new task list
    try currentfile.seekTo(0);
    // then write the string to the file
    // try currentfile.writer().writeAll(taskListString.items); //TODO: leave until deleting is fixed
    // debug print the task list string and task list
    std.debug.print("taskListString: {s}\n", .{taskListString.items});
    // std.debug.print("taskList: {s}\n", .{taskList.items});
    try listTasks(taskList, true, null);

    // free the memory of the task descriptions
    for (taskList.items) |task| {
        allocator.free(task.TaskDescription);
    }
}
