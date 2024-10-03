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
                // std.debug.print("Local nodes size: {}\n", .{local_nodes.len});
                try nodes.append(alloc, Node{ .tag = .loop, .value = .{ .loop = &local_nodes } });
                i = end;
            },
            else => {},
        }
        i += 1;
    }

    return nodes;
}

pub fn deinitNodes(alloc: std.mem.Allocator, nodes: *Nodes) void {
    // const new_nodes = nodes.*;
    std.debug.print("Nodes: {}\n", .{nodes.len});
    const tags = nodes.items(.tag);
    for (tags, 0..) |tag, index| {
        if (tag != .loop) continue;
        // std.debug.print("Len: {}, index: {}\n", .{ nodes.len, index });
        const node = nodes.get(index);
        deinitNodes(alloc, node.value.loop);
    }
    nodes.deinit(alloc);
}

test "Test parser" {
    const alloc = testing.allocator;

    const source: []const u8 = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++. bla bla bla";

    var nodes = try parse(alloc, source);
    // defer nodes.deinit(alloc);
    defer deinitNodes(alloc, &nodes);

    std.debug.print("Len of nodes: {}\n", .{nodes.len});
    try testing.expect(nodes.len == 66);
    // try testing.expect(loop_nodes.items.len == 37);
    // try testing.expect(nodes.len + loop_nodes.items.len == 103);
}
