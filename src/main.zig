const std = @import("std");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = &gpa.allocator;

    const src = try std.fs.cwd().readFileAlloc(allocator, "code.bf", 10 << 20);
    defer allocator.free(src);

    try interpret(allocator, src);
}

pub fn interpret(allocator: *std.mem.Allocator, src: []u8) !void {
    const output = std.io.getStdOut().writer();
    const mem_cells = try allocator.alloc(u8, 1 << 16);
    defer allocator.free(mem_cells);
    std.mem.set(u8, mem_cells, 0);
    var ptr: u16 = 0;
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
            '[' => {
                if (mem_cells[ptr] == 0) {
                    var depth: usize = 0;
                    while (i < src.len) : (i += 1) {
                        switch (src[i]) {
                            '[' => depth += 1,
                            ']' => if (depth == 0) {
                                break;
                            } else {
                                depth -= 1;
                            },
                            else => {},
                        }
                    }
                }
            },
            ']' => {
                if (mem_cells[ptr] != 0) {
                    var depth: i16 = -1;
                    while (true) : (i -= 1) {
                        switch (src[i]) {
                            ']' => depth += 1,
                            '[' => if (depth == 0) {
                                break;
                            } else {
                                depth -= 1;
                            },
                            else => {},
                        }
                        if (i == 0) break;
                    }
                }
            },
            else => {},
        }
    }
}
