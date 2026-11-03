# ame-hand

カメラの映像から **手の関節 21 点** と **手の形(ジェスチャー)** を求める、Zig だけで書いたライブラリです。
[ame-shell](https://github.com/TatsuyaM2667/ame-shell) のハンド操作(手の動きでカーソル・ワークスペース・ウィンドウを操作する機能)から切り出しました。

C++・Python・OpenCV・TensorFlow Lite のランタイムは使いません。モデルの読み込みから推論まで自作です。

## 中身

| モジュール | やること |
|---|---|
| `tflite` | TFLite のモデル(FlatBuffers)を読む |
| `nn` | 小さな推論エンジン(CPU・NHWC・float32)。重みを読み込み時に並べ直し、`@Vector(8)` とスレッドで計算する |
| `track` | MediaPipe の手のモデル 2 つ(手のひらの検出 192×192 → 関節 224×224)をつなぎ、コマごとに手を追う。見つかった後は検出を飛ばすので軽い |
| `gesture` | 関節から手の形(指さし・つまむ・開く・握る・本数)、カーソルの位置、つまみ具合を出す。One Euro filter とヒステリシスでぶれを抑える |
| `zip` | モデル(`.task` は無圧縮の zip)から中身を取り出す |
| `v4l2` | カメラ(Linux の V4L2、FreeBSD の webcamd)。YUYV と白黒(赤外線カメラ)を読む |

## 使い方

`build.zig.zon` に依存として加えます。

```sh
zig fetch --save git+https://github.com/TatsuyaM2667/ame-hand
```

```zig
// build.zig
const hand = b.dependency("ame_hand", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("ame-hand", hand.module("ame-hand"));
```

```zig
const hand = @import("ame-hand");
var det = try hand.nn.Net.init(a, det_bytes, 2);
var lmk = try hand.nn.Net.init(a, lmk_bytes, 2);
var tr = hand.track.Tracker.init(&det, &lmk);
tr.det_signed = false;
if (try tr.step(img)) |h| {
    const f = analyzer.step(h.pts, w, h_px, t); // f.gesture, f.cx, f.cy, f.pinch ...
}
```

全体の流れは `tools/demo.zig` にあります。

## 試す

```sh
zig build -Doptimize=ReleaseFast
curl -LO https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task
./zig-out/bin/ame-hand-demo hand_landmarker.task          # カメラは自動で選ぶ
./zig-out/bin/ame-hand-demo hand_landmarker.task /dev/video0
zig build test
```

Zig 0.13。Linux と FreeBSD(webcamd)で動きます。

## モデル

MediaPipe の Hand Landmarker(Apache-2.0)を使います。このリポジトリには含めていません。上の URL から取ってきてください。

## ライセンス

GPL-3.0(`LICENSE`)。
