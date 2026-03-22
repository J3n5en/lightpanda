const js = @import("../js/js.zig");

const SpeechSynthesis = @This();

_pad: bool = false,

pub fn getVoices(_: *const SpeechSynthesis) [0]void {
    return .{};
}

pub fn speak(_: *const SpeechSynthesis) void {}
pub fn cancel(_: *const SpeechSynthesis) void {}
pub fn pause(_: *const SpeechSynthesis) void {}
pub fn resume_(_: *const SpeechSynthesis) void {}

pub const JsApi = struct {
    pub const bridge = js.Bridge(SpeechSynthesis);

    pub const Meta = struct {
        pub const name = "SpeechSynthesis";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const pending = bridge.property(false, .{ .template = false });
    pub const speaking = bridge.property(false, .{ .template = false });
    pub const paused = bridge.property(false, .{ .template = false });
    pub const getVoices = bridge.function(SpeechSynthesis.getVoices, .{});
    pub const speak = bridge.function(SpeechSynthesis.speak, .{});
    pub const cancel = bridge.function(SpeechSynthesis.cancel, .{});
    pub const pause = bridge.function(SpeechSynthesis.pause, .{});
    pub const @"resume" = bridge.function(SpeechSynthesis.resume_, .{});
};
