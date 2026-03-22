const js = @import("../js/js.zig");

const Notification = @This();

_pad: bool = false,

pub const JsApi = struct {
    pub const bridge = js.Bridge(Notification);

    pub const Meta = struct {
        pub const name = "Notification";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const permission = bridge.property("default", .{ .template = false });
};
