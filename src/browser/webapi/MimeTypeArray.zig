const js = @import("../js/js.zig");

pub fn registerTypes() []const type {
    return &.{ MimeTypeArray, MimeType };
}

const MimeTypeArray = @This();

_pad: bool = false,

pub fn getAtIndex(_: *const MimeTypeArray, index: usize) ?*MimeType {
    _ = index;
    return null;
}

pub fn getByName(_: *const MimeTypeArray, name: []const u8) ?*MimeType {
    _ = name;
    return null;
}

const MimeType = struct {
    pub const JsApi = struct {
        pub const bridge = js.Bridge(MimeType);
        pub const Meta = struct {
            pub const name = "MimeType";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
            pub const empty_with_no_proto = true;
        };
    };
};

pub const JsApi = struct {
    pub const bridge = js.Bridge(MimeTypeArray);

    pub const Meta = struct {
        pub const name = "MimeTypeArray";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
        pub const empty_with_no_proto = true;
    };

    pub const length = bridge.property(0, .{ .template = false });
    pub const @"[int]" = bridge.indexed(MimeTypeArray.getAtIndex, null, .{ .null_as_undefined = true });
    pub const @"[str]" = bridge.namedIndexed(MimeTypeArray.getByName, null, null, .{ .null_as_undefined = true });
    pub const item = bridge.function(_item, .{});
    fn _item(self: *const MimeTypeArray, index: i32) ?*MimeType {
        if (index < 0) return null;
        return self.getAtIndex(@intCast(index));
    }
    pub const namedItem = bridge.function(MimeTypeArray.getByName, .{});
};
