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
    try testing.expect(tokens.len == 106);
}

const Node = struct {
    token: Token,
    value: u32,
};

// export fn parse(alloc: *std.mem.Allocator, tokens: std.ArrayList(Token)) std.ArrayList(Node) {
//     const nodes = std.MultiArrayList(Node);

//     var i: u32 = 0;
//     while (i < tokens.items.len) {}
// }
