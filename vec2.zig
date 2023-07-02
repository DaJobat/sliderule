const std = @import("std");
const math = std.math;
const testing = std.testing;
const assert = std.debug.assert;
const Random = std.rand.Random;

pub fn Vec2(comptime Number: type) type {
    const NumberTypeInfo = @typeInfo(Number);
    return switch (NumberTypeInfo) {
        .Int, .ComptimeInt => Vector2Base(Number, IntExtension),
        .Float, .ComptimeFloat => Vector2Base(Number, FloatExtension),
        else => @compileError("invalid type " ++ @typeName(Number) ++ ", Vec2 must be Int or Float"),
    };
}

fn IntExtension(comptime Self: type) type {
    return struct {
        pub inline fn rand(r: std.rand.Random) Self {
            return .{
                .x = r.int(Self.NumberType),
                .y = r.int(Self.NumberType),
            };
        }

        pub inline fn randRange(r: Random, min: Self, max: Self) Self {
            assert(min.x < max.x);
            assert(min.y < max.y);
            return .{
                .x = r.intRangeLessThan(Self.NumberType, min.x, max.x),
                .y = r.intRangeLessThan(Self.NumberType, min.y, max.y),
            };
        }

        pub fn toFloat(vec: Self, comptime T: type) Vec2(T) {
            return Vec2(T){ .x = @floatFromInt(vec.x), .y = @floatFromInt(vec.y) };
        }
    };
}

fn FloatExtension(comptime Self: type) type {
    return struct {
        pub inline fn rand(r: std.rand.Random) Self {
            return .{
                .x = r.float(Self.NumberType) * math.floatMax(Self.NumberType),
                .y = r.float(Self.NumberType) * math.floatMax(Self.NumberType),
            };
        }

        pub inline fn randRange(r: Random, min: Self, max: Self) Self {
            assert(min.x < max.x);
            assert(min.y < max.y);
            return .{
                .x = min.x + (r.float(Self.NumberType) * (max.x - min.x)),
                .y = min.y + (r.float(Self.NumberType) * (max.y - min.y)),
            };
        }

        pub const ModF = struct { fpart: Self, ipart: Self };
        pub inline fn modf(v: Self) ModF {
            const mod_x = math.modf(v.x);
            const mod_y = math.modf(v.y);
            return .{
                .fpart = Self.init(mod_x.fpart, mod_y.fpart),
                .ipart = Self.init(mod_x.ipart, mod_y.ipart),
            };
        }

        pub inline fn floor(v1: Self) Self {
            return .{
                .x = @floor(v1.x),
                .y = @floor(v1.y),
            };
        }

        pub fn toInt(vec: Self, comptime T: type) Vec2(T) {
            return Vec2(T){ .x = @intFromFloat(vec.x), .y = @intFromFloat(vec.y) };
        }
    };
}

fn Vector2Base(comptime Number: type, comptime Extension: fn (type) type) type {
    return struct {
        const Vector2 = @This();
        pub usingnamespace Extension(Vector2);
        pub const NumberType = Number;

        pub const Zero = Vector2{ .x = 0, .y = 0 };
        x: NumberType = 0,
        y: NumberType = 0,

        pub inline fn init(x: NumberType, y: NumberType) Vector2 {
            return .{ .x = x, .y = y };
        }

        pub const add = addV;
        pub inline fn addS(v1: Vector2, num: NumberType) Vector2 {
            return .{ .x = v1.x + num, .y = v1.y + num };
        }

        pub inline fn addV(v1: Vector2, v2: Vector2) Vector2 {
            return .{ .x = v1.x + v2.x, .y = v1.y + v2.y };
        }

        pub const sub = subV;
        pub inline fn subS(v1: Vector2, num: NumberType) Vector2 {
            return .{ .x = v1.x - num, .y = v1.y - num };
        }

        pub inline fn subV(v1: Vector2, v2: Vector2) Vector2 {
            return .{ .x = v1.x - v2.x, .y = v1.y - v2.y };
        }

        pub inline fn scaleS(v: Vector2, factor: f32) Vector2 {
            return .{ .x = v.x * factor, .y = v.y * factor };
        }

        pub inline fn scaleV(v1: Vector2, factor: Vector2) Vector2 {
            return .{ .x = v1.x * factor.x, .y = v1.y * factor.y };
        }
        pub const mul = scaleV;

        pub inline fn div(v1: Vector2, v2: Vector2) Vector2 {
            return .{ .x = v1.x / v2.x, .y = v1.y / v2.y };
        }

        pub inline fn dot(v1: Vector2, v2: Vector2) Number {
            return (v1.x * v2.x) + (v1.y * v2.y);
        }

        pub inline fn cross(v1: Vector2, v2: Vector2) Number {
            return (v1.x * v2.y) - (v2.x * v1.y);
        }

        pub inline fn distance(v1: Vector2, v2: Vector2) Number {
            return v1.sub(v2).len();
        }

        pub inline fn len(v1: Vector2) Number {
            return math.sqrt(v1.lenSq());
        }

        pub inline fn lenSq(v1: Vector2) Number {
            return v1.dot(v1);
        }

        pub inline fn projectOnto(v1: Vector2, v2: Vector2) Vector2 {
            return v1.scaleS(v1.dot(v2) / v2.dot(v2));
        }

        pub inline fn insideRect(v: Vector2, origin: Vector2, size: Vector2) bool {
            return v.x >= origin.x and v.y >= origin.y and v.x < origin.x + size.x and v.y < origin.y + size.y;
        }

        pub inline fn insideCircle(v: Vector2, origin: Vector2, radius: Number) bool {
            return v.sub(origin).lenSq() < (radius * radius);
        }

        /// Comparison functions for sorting
        pub fn asc(comptime field: std.meta.FieldEnum(Vector2)) fn (void, Vector2, Vector2) bool {
            return struct {
                pub fn inner(_: void, a: Vector2, b: Vector2) bool {
                    return @field(a, @tagName(field)) < @field(b, @tagName(field));
                }
            }.inner;
        }

        /// Comparison functions for sorting
        pub fn desc(comptime field: std.meta.FieldEnum(Vector2)) fn (void, Vector2, Vector2) bool {
            return struct {
                pub fn inner(_: void, a: Vector2, b: Vector2) bool {
                    return @field(a, @tagName(field)) > @field(b, @tagName(field));
                }
            }.inner;
        }

        pub fn format(vec: Vector2, comptime layout: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = layout;
            _ = options;
            return writer.print("[{d:.3},{d:.3}]", .{ vec.x, vec.y });
        }

        pub fn toArray(vec: Vector2) [2]Number {
            return .{ vec.x, vec.y };
        }
    };
}

pub fn sincos(comptime T: type, angle: T) Vec2(T) {
    switch (T) {
        .Float => {},
        else => @compileError("sincos: invalid type: " ++ @typeName(T) ++ ", must be called with a float type"),
    }
    return .{
        .x = @cos(angle),
        .y = @sin(angle),
    };
}

test {
    const IVec = Vec2(i32);
    try testing.expectEqual(IVec.init(12, 8), (IVec{ .x = 5, .y = 3 }).add(.{ .x = 7, .y = 5 }));

    const FVec = Vec2(f32);
    try testing.expectEqual(
        FVec.init(10 + @as(f32, 20), 0.2 + @as(f32, 3)),
        FVec.init(10, 0.2).add(FVec.init(20, 3)),
    );
    try testing.expectEqual(
        FVec.init(-10 - @as(f32, 20), -3.2 - @as(f32, 3)),
        FVec.init(-10, -3.2).sub(FVec.init(20, 3)),
    );

    try testing.expectEqual(FVec.init(10, 20), FVec.init(1, 2).scaleS(10));
    try testing.expectEqual(@as(f32, 16), FVec.init(0, 4).dot(FVec.init(0, 4)));

    const mod_exp = (FVec.ModF{ .fpart = .{ .x = 0.2, .y = 0.8 }, .ipart = .{ .x = 10, .y = 2 } });
    const mod_out = (FVec{ .x = 10.2, .y = 2.8 }).modf();
    try testing.expectApproxEqAbs(mod_exp.fpart.x, mod_out.fpart.x, 0.002);
    try testing.expectApproxEqAbs(mod_exp.fpart.y, mod_out.fpart.y, 0.002);
    try testing.expectApproxEqAbs(mod_exp.ipart.x, mod_out.ipart.x, 0.002);
    try testing.expectApproxEqAbs(mod_exp.ipart.y, mod_out.ipart.y, 0.002);
}

test "sort" {
    const Vector2 = Vec2(f32);
    var prng = std.rand.DefaultPrng.init(0);
    const random = prng.random();
    const ally = testing.allocator;
    var vecs = try ally.alloc(Vector2, 10_000);
    defer ally.free(vecs);
    for (vecs, 0..) |_, i| {
        vecs[i] = Vector2.rand(random);
    }

    std.sort.heap(Vector2, vecs, {}, Vector2.asc(.x));
}
