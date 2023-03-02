const options = @import("options");
const bytecode = @import("bytecode.zig");
const Chunk = bytecode.Chunk;
const OpCode = bytecode.OpCode;

pub fn disassembleChunk(writer: anytype, chunk: *Chunk) !void {
    var offset: usize = 0;
    while (offset < chunk.codes.items.len) {
        offset = try disassembleInstruction(writer, chunk, offset);
    }
}

pub fn disassembleInstruction(writer: anytype, chunk: *Chunk, offset: usize) !usize {
    const code = @intToEnum(OpCode, chunk.codes.items[offset]);
    const line = try chunk.lines.get(offset);
    try writer.print("{} {} ", .{ offset, line });
    switch (code) {
        .op_constant => {
            const index = chunk.codes.items[offset + 1];
            try writer.print("OP_CONSTANT {} {}\n", .{ index, chunk.constants.items[index] });
            return offset + 2;
        },
        .op_return => {
            try writer.print("OP_RETURN\n", .{});
            return offset + 1;
        },
    }
}
