const std = @import("std");
const testing = std.testing;

const Token = enum { add, subtract, move_r, move_l, out, in, start_loop, end_loop };

pub fn tokenize(alloc: std.mem.Allocator, source: []const u8) ![]const Token {
    var tokens = std.ArrayList(Token).init(alloc);
    defer tokens.deinit();

    for (source) |c| {
        try switch (c) {
            '+' => tokens.append(Token.add),
            '-' => tokens.append(Token.subtract),
            '>' => tokens.append(Token.move_r),
            '<' => tokens.append(Token.move_l),
            '.' => tokens.append(Token.out),
            ',' => tokens.append(Token.in),
            '[' => tokens.append(Token.start_loop),
            ']' => tokens.append(Token.end_loop),
            else => continue,
        };
    }

    return try tokens.toOwnedSlice();
}

test "Tokenize basic source" {
    const source: []const u8 = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++. bla bla bla";
    const tokens = try tokenize(testing.allocator, source);
    defer testing.allocator.free(tokens);
    try testing.expect(tokens.len == 106);
}

const Node = struct {
    tag: enum {
        add,
        move,
        out,
        in,
        loop,
    },
    value: union {
        add: i9,
        move: i32,
        none: void,
        loop: usize,
    },
};

pub const Nodes = std.MultiArrayList(Node);
pub const LoopNodes = std.ArrayList(Nodes.Slice);

pub fn parse(alloc: std.mem.Allocator, tokens: []const Token, loop_nodes: *LoopNodes) !Nodes {
    var nodes = Nodes{};

    var i: u32 = 0;
    while (i < tokens.len) {
        const token = tokens[i];
        switch (token) {
            .add => try nodes.append(alloc, Node{ .tag = .add, .value = .{ .add = 1 } }),
            .subtract => try nodes.append(alloc, Node{ .tag = .add, .value = .{ .add = -1 } }),
            .move_r => try nodes.append(alloc, Node{ .tag = .move, .value = .{ .move = 1 } }),
            .move_l => try nodes.append(alloc, Node{ .tag = .move, .value = .{ .move = -1 } }),
            .in => try nodes.append(alloc, Node{ .tag = .in, .value = .{ .none = @as(void, undefined) } }),
            .out => try nodes.append(alloc, Node{ .tag = .out, .value = .{ .none = @as(void, undefined) } }),
            .start_loop => {
                const start = i + 1;
                var end = start;
                var depth: u32 = 1;
                while (depth > 0 and end < tokens.len) {
                    const current = tokens[end];
                    if (current == .start_loop) {
                        depth += 1;
                    }
                    if (current == .end_loop) {
                        depth -= 1;
                    }
                    end += 1;
                }

                var local_nodes = try parse(alloc, tokens[start .. end - 1], loop_nodes);
                try loop_nodes.append(local_nodes.toOwnedSlice());
                try nodes.append(alloc, Node{ .tag = .loop, .value = .{ .loop = loop_nodes.items.len - 1 } });
                i = end + 1;
            },
            else => continue,
        }
        i += 1;
    }

    return nodes;
}

test "Test parser" {
    const alloc = testing.allocator;

    const source: []const u8 = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++. bla bla bla";
    const tokens = try tokenize(alloc, source);
    defer alloc.free(tokens);

    var loop_nodes = LoopNodes.init(alloc);
    defer {
        for (loop_nodes.items) |loop| {
            alloc.free(loop);
        }

        loop_nodes.deinit();
    }

    var nodes = try parse(alloc, tokens, &loop_nodes);
    defer nodes.deinit(alloc);

    std.debug.print("Len of nodes: {}\n", .{nodes.len});
    try testing.expect(nodes.len == 64);
}
