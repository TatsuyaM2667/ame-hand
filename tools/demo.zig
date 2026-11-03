// ame-hand-demo: カメラの前で手を動かすと、手の形と位置を端末に表示する試し。
//   ame-hand-demo <hand_landmarker.task> [/dev/videoN]
// モデルは curl -LO <MODEL_URL>(src/root.zig)で取ってくる。
const std = @import("std");
const hand = @import("ame-hand");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const args = try std.process.argsAlloc(a);
    if (args.len < 2) {
        std.debug.print("使い方: ame-hand-demo <hand_landmarker.task> [/dev/videoN]\nモデル: {s}\n", .{hand.MODEL_URL});
        return;
    }
    const bytes = try std.fs.cwd().readFileAlloc(a, args[1], 64 << 20);
    var det_b: []const u8 = undefined;
    var lmk_b: []const u8 = undefined;
    if (!hand.zip.unzipStored(bytes, "hand_detector.tflite", &det_b) or
        !hand.zip.unzipStored(bytes, "hand_landmarks_detector.tflite", &lmk_b)) return error.BadModel;
    var det = try hand.nn.Net.init(a, det_b, 2);
    defer det.deinit();
    var lmk = try hand.nn.Net.init(a, lmk_b, 2);
    defer lmk.deinit();
    var tr = hand.track.Tracker.init(&det, &lmk);
    tr.det_signed = false;

    var cam = try openCamera(if (args.len > 2) args[2] else null);
    defer cam.close();
    std.debug.print("カメラ {d}x{d}。Ctrl+C で終わる\n", .{ cam.w, cam.h });
    const rgb = try a.alloc(u8, cam.w * cam.h * 3);
    var an = hand.gesture.Analyzer{};
    var lut: [256]u8 = undefined;
    var had = false;
    while (true) {
        var pfd = [_]std.posix.pollfd{.{ .fd = cam.fd, .events = std.posix.POLL.IN, .revents = 0 }};
        _ = try std.posix.poll(&pfd, 500);
        if (!cam.grab(rgb, true)) continue;
        // 暗い映像は持ち上げる
        var sum: u64 = 0;
        var i: usize = 0;
        while (i < rgb.len) : (i += 3 * 37) sum += rgb[i];
        const mean = @as(f32, @floatFromInt(sum)) / @as(f32, @floatFromInt(rgb.len / (3 * 37) + 1));
        if (hand.gesture.brightLut(mean, &lut)) for (rgb) |*px| {
            px.* = lut[px.*];
        };
        const img = hand.track.Image{ .rgb = rgb, .w = cam.w, .h = cam.h };
        if (try tr.step(img)) |h| {
            if (!had) an.reset();
            had = true;
            const t = @as(f32, @floatFromInt(std.time.milliTimestamp())) / 1000;
            const f = an.step(h.pts, @floatFromInt(cam.w), @floatFromInt(cam.h), t);
            std.debug.print("\r{s:<7} 指 {d}  位置 ({d:.2}, {d:.2})  つまみ {d:.2}   ", .{ @tagName(f.gesture), f.fingers, f.cx, f.cy, f.pinch });
        } else if (had) {
            had = false;
            std.debug.print("\r(手が見えません)                                   ", .{});
        }
    }
}

fn openCamera(dev: ?[]const u8) !hand.v4l2.Camera {
    var buf: [64]u8 = undefined;
    if (dev) |d| return hand.v4l2.Camera.open((try std.fmt.bufPrintZ(&buf, "{s}", .{d})).ptr, 640, 480, 30);
    for (0..10) |i| {
        const p = try std.fmt.bufPrintZ(&buf, "/dev/video{d}", .{i});
        if (hand.v4l2.Camera.open(p.ptr, 640, 480, 30)) |c| return c else |_| {}
    }
    return error.NoCamera;
}
