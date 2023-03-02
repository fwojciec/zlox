const std = @import("std");
const options = @import("options");
const bytecode = @import("./bytecode.zig");
const debug = @import("./debug.zig");
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
        if (options.debug) {
            _ = try debug.disassembleInstruction(std.io.getStdOut().writer(), chunk, ip);
        }
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
