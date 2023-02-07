const std = @import("std");
const bytecode = @import("bytecode.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var chunk = bytecode.Chunk.init(allocator);
    var constant = try chunk.addConstant(1.2);
    try chunk.writeOpCode(bytecode.OpCode.op_constant, 123);
    try chunk.write(constant, 123);
    try chunk.writeOpCode(bytecode.OpCode.op_return, 123);
    try bytecode.disassemble(std.io.getStdOut().writer(), &chunk);
    chunk.deinit();
}

test {
    std.testing.refAllDecls(@This());
}
