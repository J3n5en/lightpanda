const js = @import("../js/js.zig");

const NetworkInformation = @This();

_pad: bool = false,

pub const JsApi = struct {
    pub const bridge = js.Bridge(NetworkInformation);

    pub const Meta = struct {
        pub const name = "NetworkInformation";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const effectiveType = bridge.property("4g", .{ .template = false });
    pub const rtt = bridge.property(50, .{ .template = false });
    pub const downlink = bridge.property(@as(f64, 10.0), .{ .template = false });
    pub const saveData = bridge.property(false, .{ .template = false });
};
