// ame-hand: カメラの映像から手の関節 21 点と手の形(ジェスチャー)を求めるライブラリ。Zig だけで書いた。
//
//   tflite  … TFLite のモデル(FlatBuffers)を読む
//   nn      … 小さな推論エンジン(CPU、NHWC・float32、@Vector とスレッドで速く)
//   track   … MediaPipe の手のモデル 2 つ(手のひらの検出 → 関節 21 点)をつないで、コマごとに手を追う
//   gesture … 関節から手の形・カーソルの位置・つまみ具合を出す(One Euro filter でならす)
//   zip     … モデル(.task は無圧縮の zip)から中身を取り出す
//   v4l2    … カメラ(Linux の V4L2 と FreeBSD の webcamd)。YUYV と白黒(赤外線カメラ)
//
// 使い方は tools/demo.zig。モデルは MODEL_URL から取ってくる(Apache-2.0、このリポジトリには含めない)。
pub const tflite = @import("tflite.zig");
pub const nn = @import("nn.zig");
pub const track = @import("track.zig");
pub const gesture = @import("gesture.zig");
pub const zip = @import("zip.zig");
pub const v4l2 = @import("v4l2.zig");

/// MediaPipe の手のモデル(手のひらの検出と関節の 2 つが入った .task)
pub const MODEL_URL = "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task";

test {
    _ = tflite;
    _ = nn;
    _ = track;
    _ = gesture;
    _ = zip;
    _ = v4l2;
}
