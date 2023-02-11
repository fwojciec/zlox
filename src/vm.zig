const std = @import("std");
const bytecode = @import("./bytecode.zig");
const Value = @import("./value.zig").Value;

pub const InterpretResult = enum {
    interpret_ok,
    interpret_compile_error,
    interpret_runtime_error,
};

pub fn interpret(chunk: *bytecode.Chunk) !InterpretResult {
    var ip: usize = 0;
    while (true) {
        const code = @intToEnum(bytecode.OpCode, chunk.codes.items[ip]);
        ip += 1;
        switch (code) {
            .op_constant => {
                const idx = chunk.codes.items[ip];
                const constant: Value = chunk.constants.items[idx];
                std.debug.print("{}\n", .{constant});
                ip += 1;
            },
            .op_return => return .interpret_ok,
        }
    }
}
