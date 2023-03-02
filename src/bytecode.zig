const std = @import("std");
const debug = @import("./debug.zig");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Value = @import("./value.zig").Value;

pub const ByteCodeError = error{
    ChunkOverflow,
    OutOfMemory,
    PageNotFound,
};

pub const OpCode = enum(u8) {
    op_constant,
    op_return,
};

pub const Chunk = struct {
    codes: ArrayList(u8),
    constants: ArrayList(Value),
    lines: Lines,

    pub fn init(allocator: Allocator) Chunk {
        return Chunk{
            .codes = ArrayList(u8).init(allocator),
            .constants = ArrayList(Value).init(allocator),
            .lines = Lines.init(allocator),
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.codes.deinit();
        self.constants.deinit();
        self.lines.deinit();
    }

    pub fn write(self: *Chunk, byte: u8, line: u16) ByteCodeError!void {
        try self.codes.append(byte);
        try self.lines.append(line);
    }

    pub fn writeOpCode(self: *Chunk, code: OpCode, line: u16) ByteCodeError!void {
        try self.write(@enumToInt(code), line);
    }

    pub fn addConstant(self: *Chunk, value: Value) ByteCodeError!u8 {
        if (self.constants.items.len >= std.math.maxInt(u8)) {
            return ByteCodeError.ChunkOverflow;
        }
        const index = @intCast(u8, self.constants.items.len);
        try self.constants.append(value);
        return index;
    }
};

const Lines = struct {
    // [line][count]...
    data: ArrayList(u16),

    pub fn init(allocator: Allocator) Lines {
        return Lines{
            .data = ArrayList(u16).init(allocator),
        };
    }

    pub fn append(self: *Lines, line: u16) ByteCodeError!void {
        const len = self.data.items.len;
        if (len > 0) {
            const cur = self.data.items[len - 2];
            if (cur == line) {
                self.data.items[len - 1] += 1;
                return;
            }
        }
        try self.data.append(line);
        try self.data.append(1);
    }

    pub fn get(self: *Lines, index: usize) ByteCodeError!u16 {
        const len = self.data.items.len;
        if (len < 2) {
            return ByteCodeError.PageNotFound;
        }
        var offset: usize = 0;
        var count: usize = 0;
        var cur: u16 = 0;

        while (offset < self.data.items.len) {
            cur = self.data.items[offset];
            count += self.data.items[offset + 1];
            if (count > index) {
                return cur;
            }
            offset += 2;
        }
        return ByteCodeError.PageNotFound;
    }

    pub fn deinit(self: *Lines) void {
        self.data.deinit();
    }
};

test "lines" {
    var lines = Lines.init(std.testing.allocator);
    defer lines.deinit();

    try lines.append(123);
    try lines.append(123);
    try lines.append(124);
    try lines.append(125);

    const result_0 = try lines.get(0);
    const result_1 = try lines.get(1);
    const result_2 = try lines.get(2);
    const result_3 = try lines.get(3);

    try std.testing.expectEqual(@as(u16, 123), result_0);
    try std.testing.expectEqual(@as(u16, 123), result_1);
    try std.testing.expectEqual(@as(u16, 124), result_2);
    try std.testing.expectEqual(@as(u16, 125), result_3);
}

test "chunk" {
    var chunk = Chunk.init(std.testing.allocator);
    defer chunk.deinit();

    // op_constant 1.2
    try chunk.writeOpCode(OpCode.op_constant, 123);
    var constant = try chunk.addConstant(1.2);
    try chunk.write(constant, 123);

    // op_return
    try chunk.writeOpCode(OpCode.op_return, 124);

    var result = ArrayList(u8).init(std.testing.allocator);
    defer result.deinit();

    try debug.disassembleChunk(result.writer(), &chunk);
    const expected =
        \\0 123 OP_CONSTANT 0 1.2e+00
        \\2 124 OP_RETURN
        \\
    ;
    try std.testing.expectEqualStrings(expected, result.items);
}
