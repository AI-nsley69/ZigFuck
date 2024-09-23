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

const NodeTag = enum {
    add,
    move,
    out,
    in,
    loop,
};

const Node = struct {
    action: NodeTag,
    value: union {
        add: i9,
        move: i32,
        none: i0,
        loop: *const Nodes,
    },
};

const Nodes = std.MultiArrayList(Node);

pub fn parse(alloc: std.mem.Allocator, tokens: []const Token) !Nodes {
    var nodes = Nodes{};
    defer alloc.free(nodes);

    var i: u32 = 0;
    while (i < tokens.len) {
        var current = tokens[i];

        switch (current) {
            .add, .subtract => {
                var node = Node{
                    .action = .add,
                    .value = .{ .add = 0 },
                };
                i += 1;
                while (i < tokens.len) {
                    current = tokens[i];
                    if (current == .add) {
                        node.value.add +%= 1;
                    } else if (current == .subtract) {
                        node.value.add -%= 1;
                    } else {
                        break;
                    }
                    i += 1;
                }

                try nodes.append(alloc, node);
            },
            .move_l, .move_r => {
                var node = Node{
                    .action = .add,
                    .value = .{ .move = 0 },
                };
                i += 1;
                while (i < tokens.len) {
                    current = tokens[i];
                    if (current == .move_r) {
                        node.value.move +%= 1;
                    } else if (current == .move_l) {
                        node.value.move -%= 1;
                    } else {
                        break;
                    }
                    i += 1;
                }

                try nodes.append(alloc, node);
            },
            .in => try nodes.append(alloc, Node{
                .action = .in,
                .value = .{ .none = 0 },
            }),
            .out => try nodes.append(alloc, Node{
                .action = .out,
                .value = .{ .none = 0 },
            }),
            .start_loop => {
                var loop_tokens = std.ArrayList(Token).init(alloc);
                defer loop_tokens.deinit();
                i += 1;
                var depth: u8 = 1;
                while (depth != 0) {
                    current = tokens[i];
                    if (current == .start_loop) {
                        depth += 1;
                    }
                    if (current == .end_loop) {
                        depth -= 1;
                    }

                    try loop_tokens.append(current);
                }

                const loop_tokens_slice = try loop_tokens.toOwnedSlice();
                const loop_nodes = try parse(alloc, loop_tokens_slice);
                try nodes.append(alloc, Node{ .action = .loop, .value = .{
                    .loop = &loop_nodes,
                } });
            },
            else => break,
        }
    }

    return nodes;
}

test "Test parser" {
    const alloc = testing.allocator;

    const source: []const u8 = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++. bla bla bla";
    const tokens = try tokenize(alloc, source);
    defer alloc.free(tokens);

    var nodes = try parse(alloc, tokens);
    defer nodes.deinit(alloc);

    try testing.expect(nodes.len == 31);
}
