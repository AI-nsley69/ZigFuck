const std = @import("std");
const testing = std.testing;

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
        loop: *Nodes,
    },
};

pub const Nodes = std.MultiArrayList(Node);

pub fn parse(alloc: std.mem.Allocator, tokens: []const u8) !Nodes {
    var nodes = Nodes{};

    var i: u32 = 0;
    while (i < tokens.len) {
        const token = tokens[i];
        switch (token) {
            '+' => try nodes.append(alloc, Node{ .tag = .add, .value = .{ .add = 1 } }),
            '-' => try nodes.append(alloc, Node{ .tag = .add, .value = .{ .add = -1 } }),
            '>' => try nodes.append(alloc, Node{ .tag = .move, .value = .{ .move = 1 } }),
            '<' => try nodes.append(alloc, Node{ .tag = .move, .value = .{ .move = -1 } }),
            ',' => try nodes.append(alloc, Node{ .tag = .in, .value = .{ .none = @as(void, undefined) } }),
            '.' => try nodes.append(alloc, Node{ .tag = .out, .value = .{ .none = @as(void, undefined) } }),
            '[' => {
                const start = i + 1;
                var end = start;
                var depth: u32 = 1;
                while (depth > 0 and end < tokens.len) : (end += 1) {
                    const current = tokens[end];
                    if (current == '[') {
                        depth += 1;
                    }
                    if (current == ']') {
                        depth -= 1;
                        if (depth == 0) break;
                    }
                }

                var local_nodes = try parse(alloc, tokens[start..end]);
                try nodes.append(alloc, Node{ .tag = .loop, .value = .{ .loop = &local_nodes } });
                i = end;
            },
            else => {},
        }
        i += 1;
    }

    return nodes;
}

test "Test parser" {
    const alloc = testing.allocator;

    const source: []const u8 = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++. bla bla bla";

    var nodes = try parse(alloc, source);
    defer {
        var i: u32 = 0;
        while (i < nodes.len) : (i += 1) {
            const item = nodes.get(i);
            if (item.tag != .loop) continue;
            item.value.loop.deinit(alloc);
        }
        nodes.deinit(alloc);
    }

    std.debug.print("Len of nodes: {}\n", .{nodes.len});
    try testing.expect(nodes.len == 66);
    // try testing.expect(loop_nodes.items.len == 37);
    // try testing.expect(nodes.len + loop_nodes.items.len == 103);
}
