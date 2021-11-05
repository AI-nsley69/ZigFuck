const std = @import("std");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = &gpa.allocator;
    // Get the source code and pass it to the interpreter
    const src = try input(allocator);
    defer allocator.free(src);
    try interpret(allocator, src);
}

pub fn input(allocator: *std.mem.Allocator) ![]u8 {
    // Writer for output
    const output = std.io.getStdOut().writer();
    // Process args
    var args = std.process.args();
    std.debug.assert(args.skip());
    // Try to get the next argument, if it's missing, throw an error because there's no file to interpret
    const file = try args.next(allocator) orelse {
        try output.writeAll("Have you given me no file?\nSeems like you forgot to specify what file!\n");
        return error.MissingArguments;
    };
    defer allocator.free(file);
    // Check if the file ends with .bf, if not, throw an error and let the user know.
    if (!std.mem.endsWith(u8, file, ".bf")) {
        try output.writeAll("Have you given me the wrong file?\nI only accept the bf file extension!\n");
        return error.InvalidFilename;
    }
    var src = try std.fs.cwd().readFileAlloc(allocator, file, 10 << 20);

    return src;
}

pub fn interpret(allocator: *std.mem.Allocator, src: []u8) !void {
    const output = std.io.getStdOut().writer();
    // Setup memory cells, then set all cells to 0
    const mem_cells = try allocator.alloc(u8, 1 << 16);
    defer allocator.free(mem_cells);
    std.mem.set(u8, mem_cells, 0);
    // Create a stack for [] characters
    var stack = std.ArrayList(usize).init(allocator);
    defer stack.deinit();
    // Setup data pointer (ptr) and code pointer (i)
    var ptr: u16 = 5;
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        switch (src[i]) {
            '>' => {
                ptr +%= 1;
            },
            '<' => {
                ptr -%= 1;
            },
            '+' => {
                mem_cells[ptr] +%= 1;
            },
            '-' => {
                mem_cells[ptr] -%= 1;
            },
            '.' => {
                try output.writeByte(mem_cells[ptr]);
            },
            ',' => {
                mem_cells[ptr] = try std.io.getStdIn().reader().readByte();
            },
            '[' => if (mem_cells[ptr] != 0) {
                try stack.append(i);
            } else {
                var depth: usize = 0;
                while (i < src.len) : (i += 1) {
                    switch (src[i]) {
                        '[' => depth += 1,
                        ']' => if (depth == 1) {
                            break;
                        } else {
                            depth -= 1;
                        },
                        else => {},
                    }
                }
            },
            ']' => if (mem_cells[ptr] != 0) {
                i = stack.items[stack.items.len - 1];
            } else {
                _ = stack.pop();
            },
            else => {},
        }
    }
}
