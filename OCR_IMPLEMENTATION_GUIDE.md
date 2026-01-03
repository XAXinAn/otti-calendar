# Flutter 集成原生 OCR 功能实现指南

本文档旨在指导开发者在 Flutter 项目中，通过集成 Android 原生 PaddleOCR 引擎，实现一个高性能、支持直接调用和悬浮窗模式的 OCR 功能。

## 1. 核心技术栈

- **Flutter**: 用于构建跨平台的用户界面。
- **Kotlin**: 用于编写 Android 原生模块。
- **PaddleOCR**: 使用 `paddleocr4android` 库，这是一个为 Android 优化的轻量级 OCR 推理引擎。
- **平台通道 (Platform Channels)**: 使用 `MethodChannel` 和 `EventChannel` 实现 Flutter 与 Kotlin 之间的双向通信。

---

## 2. 步骤一：配置 Android 原生环境

### 2.1 添加 Gradle 依赖

打开您的 Android 模块的 `build.gradle.kts` (或 `build.gradle`) 文件，在 `dependencies` 代码块中添加 `paddleocr4android` 库：

```kotlin
// android/app/build.gradle.kts

dependencies {
    // ... 其他依赖
    implementation("com.github.equationl.paddleocr4android:paddleocr4android:v1.2.9")
}
```

*(请将版本号替换为最新的稳定版)*

### 2.2 添加 OCR 模型资产

1.  在 `android/app/src/main/` 目录下创建 `assets` 文件夹（如果不存在）。
2.  在 `assets` 文件夹内创建 `models` 文件夹。
3.  从 PaddleOCR 官方仓库下载 PP-OCRv3/v4 的 **.nb** 格式移动端模型，并将以下文件放入 `models` 目录：
    - `det.nb` (检测模型)
    - `rec.nb` (识别模型)
    - `cls.nb` (方向分类模型)
    - `ppocr_keys_v1.txt` (字典文件)

---

## 3. 步骤二：编写原生 OCR 核心处理器

在您的 Android 项目的 Kotlin 源码目录下，创建一个名为 `PaddleOcrHandler.kt` 的文件。此类将封装所有 OCR 相关的操作。

```kotlin
// android/app/src/main/java/com/example/your_app/PaddleOcrHandler.kt

package com.example.your_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.equationl.paddleocr4android.OCR
import com.equationl.paddleocr4android.OcrConfig
import com.equationl.paddleocr4android.bean.OcrResult
import java.io.File

/**
 * 封装 PaddleOCR 引擎，提供初始化、识别、预热和释放资源的功能。
 */
class PaddleOcrHandler(private val context: Context) {
    @Volatile
    private var ocr: OCR? = null

    /**
     * 同步初始化 OCR 引擎，确保模型只加载一次。
     * 应用了性能优化指南中的推荐配置。
     */
    @Synchronized
    @Throws(Exception::class)
    private fun ensureInited() {
        if (ocr != null) return

        // 根据 OCR 性能优化指南配置引擎
        val config = OcrConfig().apply {
            modelPath = "models"
            clsModelFilename = "cls.nb"
            detModelFilename = "det.nb"
            recModelFilename = "rec.nb"
            labelPath = "models/ppocr_keys_v1.txt"
            isRunDet = true
            isRunCls = false // **优化点**: 如果不处理旋转文字，关闭可提速
            isRunRec = true
            cpuThreadNum = 4 // **优化点**: 推荐线程数
        }

        val paddleOcr = OCR(context)
        // 使用同步方法加载模型
        val initOk = when (val r = paddleOcr.initModelSync(config)) {
            is Result<*> -> {
                if (r.isFailure) throw (r.exceptionOrNull() ?: IllegalStateException("initModelSync failed"))
                (r.getOrNull() as? Boolean) == true
            }
            is Boolean -> r
            else -> false
        }
        if (!initOk) throw IllegalStateException("PaddleOCR 模型初始化失败")

        ocr = paddleOcr
    }

    /**
     * 从文件路径识别文本。
     * @param imagePath 图片的绝对路径。
     * @return 识别出的字符串。
     */
    @Throws(Exception::class)
    fun recognize(imagePath: String): String {
        ensureInited()
        val bitmap = decodeScaledBitmap(File(imagePath)) ?: throw IllegalStateException("无法读取或解码图片")
        return runOcr(bitmap)
    }

    /**
     * 从 Bitmap 对象识别文本。
     * @param bitmap 内存中的位图对象。
     * @return 识别出的字符串。
     */
    @Throws(Exception::class)
    fun recognize(bitmap: Bitmap): String {
        ensureInited()
        // **优化点**：悬浮窗场景传入的 Bitmap 可能需要先缩放
        return runOcr(bitmap)
    }

    private fun runOcr(bitmap: Bitmap): String {
        val result: OcrResult = when (val r = ocr?.runSync(bitmap)) {
            is Result<*> -> (r.getOrNull() as? OcrResult) ?: throw (r.exceptionOrNull() ?: IllegalStateException("OCR 识别失败"))
            is OcrResult -> r
            else -> throw IllegalStateException("OCR 引擎未初始化")
        }
        return result.simpleText
    }

    /**
     * **优化点**: 对图片进行缩放，避免将高分辨率大图送入引擎。
     * 长边建议缩放至 960px 或 1280px。
     */
    private fun decodeScaledBitmap(imageFile: File, maxDim: Int = 1280): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(imageFile.absolutePath, bounds)
        var sample = 1
        while (bounds.outWidth / sample > maxDim || bounds.outHeight / sample > maxDim) {
            sample *= 2
        }
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        return BitmapFactory.decodeFile(imageFile.absolutePath, opts)
    }

    /**
     * **优化点**: 预热模型，在后台线程调用以避免首次识别卡顿。
     */
    fun warmUp() {
        try {
            ensureInited()
        } catch (_: Exception) {
            // 预热失败是可接受的，不应崩溃
        }
    }
    
    /**
     * 释放 OCR 引擎占用的资源。
     */
    fun release() {
        ocr?.releaseModel()
        ocr = null
    }
}
```

---

## 4. 步骤三：建立 Flutter 与原生的通信桥梁

修改 `MainActivity.kt` 文件，设置平台通道，并处理来自 Flutter 的调用。

```kotlin
// android/app/src/main/java/com/example/your_app/MainActivity.kt

package com.example.your_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val OCR_CHANNEL = "paddle_ocr"
    }

    // **优化点**: 使用独立线程池处理耗时的 OCR 任务
    private val ocrExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val ocrHandler by lazy { PaddleOcrHandler(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // **优化点**: 在引擎配置时异步预热 OCR
        ocrExecutor.execute { ocrHandler.warmUp() }

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // 设置 MethodChannel 用于直接识别
        MethodChannel(messenger, OCR_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "recognize") {
                val imagePath: String = call.argument("imagePath")!!
                
                ocrExecutor.execute {
                    try {
                        val text = ocrHandler.recognize(imagePath)
                        // 将结果切回主线程返回给 Flutter
                        runOnUiThread { result.success(text) }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("OCR_FAILED", e.message, null)
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
        
        // 此处可以继续添加悬浮窗相关的 Channel，见高级功能部分
    }

    override fun onDestroy() {
        super.onDestroy()
        // 释放资源
        ocrExecutor.shutdown()
        ocrHandler.release()
    }
}
```

*(为简化，此处仅包含直接识别的通道。悬浮窗部分将在高级功能中详述。)*

---

## 5. 步骤四：创建 Flutter 端的服务

在您的 Flutter 项目的 `lib` 目录下，创建一个 `ocr_service.dart` 文件，用于封装平台通道的调用。

```dart
// lib/services/ocr_service.dart

import 'package:flutter/services.dart';

class OcrService {
  const OcrService();

  // 与 MainActivity 中定义的 Channel 名称保持一致
  static const MethodChannel _channel = MethodChannel('paddle_ocr');

  /// 调用原生代码识别图片中的文字。
  /// [imagePath] 是图片在设备上的绝对路径。
  Future<String> recognize(String imagePath) async {
    try {
      final String? text = await _channel.invokeMethod<String>(
        'recognize',
        {'imagePath': imagePath},
      );
      return text ?? '';
    } on PlatformException catch (e) {
      // 可以根据需要将错误信息暴露给上层 UI
      throw Exception('OCR 识别失败: ${e.message}');
    }
  }
}
```

---

## 6. 步骤五：在 Flutter 页面中使用

现在，您可以在任何 Flutter 页面中使用 `OcrService` 来执行 OCR。通常与 `image_picker` 库结合使用。

```dart
// 示例: 在一个 StatefulWidget 中使用

import 'package:image_picker/image_picker.dart';
import 'package:your_app/services/ocr_service.dart';

class OcrScreen extends StatefulWidget {
  // ...
}

class _OcrScreenState extends State<OcrScreen> {
  final OcrService _ocrService = const OcrService();
  final ImagePicker _picker = ImagePicker();
  String _recognizedText = '...';

  Future<void> _pickAndRecognize() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _recognizedText = '正在识别...';
    });

    try {
      final text = await _ocrService.recognize(image.path);
      setState(() {
        _recognizedText = text.isEmpty ? '未识别到文字' : text;
      });
    } catch (e) {
      setState(() {
        _recognizedText = '识别出错: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR 示例')),
      body: Center(child: Text(_recognizedText)),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndRecognize,
        child: const Icon(Icons.image),
      ),
    );
  }
}
```

---

## 高级功能：实现悬浮窗 OCR

悬浮窗 OCR 需要额外处理 Android 的 `Service`、`MediaProjection` (屏幕捕捉) 和悬浮窗权限。这是一个简化的实现思路：

1.  **原生端**:
    -   创建一个 `FloatingOcrService.kt` (继承自 `android.app.Service`)，用于管理悬浮球和屏幕捕捉。
    -   在 `MainActivity.kt` 中添加用于启动/停止此服务的 `MethodChannel` (`floating_ocr`) 和用于双向通信的 `EventChannel` (`floating_ocr_events`)。
    -   启动服务前，必须通过 `Intent` 请求 `MediaProjection` 权限和 `Settings.canDrawOverlays` 悬浮窗权限。
    -   服务启动后，使用 `MediaProjection` 配合 `ImageReader` 来获取屏幕截图的 `Bitmap`。
    -   将获取的 `Bitmap` 交给 `PaddleOcrHandler` 实例进行识别。
    -   通过 `EventChannel` 将识别结果或状态（如 `ready`, `error`）发送回 Flutter。
    -   别忘了在 `AndroidManifest.xml` 中注册此 `Service`。

2.  **Flutter 端**:
    -   在 `OcrService.dart` 中添加 `startFloatingOcr()`、`stopFloatingOcr()` 方法和 `floatingEvents()` 事件流，分别对应原生端添加的通道。
    -   UI 层调用 `startFloatingOcr()` 触发原生权限请求和后台服务启动，并监听 `floatingEvents()` 来接收识别结果。

这个高级功能涉及更多原生 Android 开发知识，但遵循此架构可以确保功能的健壮性和可维护性。
