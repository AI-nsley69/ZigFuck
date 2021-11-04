const std = @import("std");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = &gpa.allocator;

    const src = try input(allocator);
    defer allocator.free(src);
    try interpret(allocator, src);
}

pub fn input(allocator: *std.mem.Allocator) ![]u8 {
    const output = std.io.getStdOut().writer();

    var args = std.process.args();
    std.debug.assert(args.skip());

    const file = try args.next(allocator) orelse {
        try output.writeAll("Have you given me no file?\n");
        return error.MissingArguments;
    };
    defer allocator.free(file);

    if (!std.mem.endsWith(u8, file, ".bf")) {
        try output.writeAll("Have you given me the wrong file?");
        return error.InvalidFilename;
    }
    var src = try std.fs.cwd().readFileAlloc(allocator, file, 10 << 20);

    return src;
}

pub fn interpret(allocator: *std.mem.Allocator, src: []u8) !void {
    const output = std.io.getStdOut().writer();
    const mem_cells = try allocator.alloc(u8, 1 << 16);
    defer allocator.free(mem_cells);
    std.mem.set(u8, mem_cells, 0);
    var stack = std.ArrayList(usize).init(allocator);
    defer stack.deinit();
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
