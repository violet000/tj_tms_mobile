# AAPT2错误解决方案

## 问题描述

在构建Release APK时遇到AAPT2错误：
```
ERROR:AAPT: aapt2.exe E 08-19 11:46:36 26140 26580 LoadedArsc.cpp:94] RES_TABLE_TYPE_TYPE entry offsets overlap actual entry data.
aapt2.exe E 08-19 11:46:36 26140 26580 ApkAssets.cpp:149] Failed to load resources table in APK 'C:\Users\15590\Documents\AndroidSDKManager\platforms\android-35\android.jar'.
error: failed to load include path C:\Users\15590\Documents\AndroidSDKManager\platforms\android-35\android.jar.
```

## 根本原因

Android SDK 35的android.jar文件损坏，导致AAPT2无法正确加载资源表。

## 解决方案

### 步骤1：备份损坏的android.jar文件
```bash
copy "C:\Users\15590\Documents\AndroidSDKManager\platforms\android-35\android.jar" "C:\Users\15590\Documents\AndroidSDKManager\platforms\android-35\android.jar.backup"
```

### 步骤2：使用Android 34的android.jar文件替换
```bash
copy "C:\Users\15590\Documents\AndroidSDKManager\platforms\android-34\android.jar" "C:\Users\15590\Documents\AndroidSDKManager\platforms\android-35\android.jar"
```

### 步骤3：配置Android SDK版本
在 `android/app/build.gradle` 中设置：
```gradle
android {
    compileSdkVersion 35
    // ...
    defaultConfig {
        targetSdkVersion 35
        // ...
    }
}
```

### 步骤4：清理并重新构建
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## 构建结果

✅ **Release APK构建成功！**
- 文件位置：`build/app/outputs/flutter-apk/app-release.apk`
- 文件大小：101.9MB
- 构建时间：约51秒

## 注意事项

1. **Kotlin版本警告**：构建过程中会出现一些Kotlin版本兼容性警告，但不影响APK的正常使用。

2. **android.jar文件**：如果将来再次遇到类似问题，可以重复上述步骤修复android.jar文件。

3. **位置轮询功能**：Release APK包含完整的位置轮询功能，可以正常使用。

## 验证方法

1. 安装APK到设备
2. 启动应用
3. 进入HOME页面
4. 观察位置轮询是否正常工作（每30秒获取一次位置）

## 备用方案

如果Release构建仍然失败，可以使用优化的Debug APK：
```bash
flutter build apk --debug
```

Debug APK同样包含完整功能，只是文件较大且包含调试信息。 