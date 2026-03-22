const js = @import("../js/js.zig");

pub fn registerTypes() []const type {
    return &.{ Chrome, ChromeRuntime, ChromeApp };
}

const Chrome = @This();

_runtime: ChromeRuntime = .{},
_app: ChromeApp = .{},

pub fn getRuntime(self: *Chrome) *ChromeRuntime {
    return &self._runtime;
}

pub fn getApp(self: *Chrome) *ChromeApp {
    return &self._app;
}

pub fn loadTimes(_: *const Chrome) void {}
pub fn csi(_: *const Chrome) void {}

pub const JsApi = struct {
    pub const bridge = js.Bridge(Chrome);

    pub const Meta = struct {
        pub const name = "Chrome";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const runtime = bridge.accessor(Chrome.getRuntime, null, .{});
    pub const app = bridge.accessor(Chrome.getApp, null, .{});
    pub const loadTimes = bridge.function(Chrome.loadTimes, .{});
    pub const csi = bridge.function(Chrome.csi, .{});
};

const ChromeRuntime = struct {
    _pad: bool = false,

    pub fn connect(_: *const ChromeRuntime) void {}
    pub fn sendMessage(_: *const ChromeRuntime) void {}

    pub const JsApi = struct {
        pub const bridge = js.Bridge(ChromeRuntime);
        pub const Meta = struct {
            pub const name = "ChromeRuntime";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };
        pub const connect = bridge.function(ChromeRuntime.connect, .{});
        pub const sendMessage = bridge.function(ChromeRuntime.sendMessage, .{});
    };
};

const ChromeApp = struct {
    _pad: bool = false,

    pub const JsApi = struct {
        pub const bridge = js.Bridge(ChromeApp);
        pub const Meta = struct {
            pub const name = "ChromeApp";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };
        pub const isInstalled = bridge.property(false, .{ .template = false });
    };
};
