@echo off
chcp 65001 >nul

echo 开始构建优化的Debug APK...

REM 清理项目
flutter clean

REM 获取依赖
flutter pub get

REM 构建Debug APK
flutter build apk --debug

REM 检查构建结果
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo ✅ Debug APK构建成功！
    echo 📱 APK位置: build\app\outputs\flutter-apk\app-debug.apk
    
    REM 显示APK大小
    for %%A in ("build\app\outputs\flutter-apk\app-debug.apk") do echo 📊 APK大小: %%~zA bytes
    
    echo.
    echo 🎉 构建完成！您可以使用这个Debug APK进行测试和部署。
    echo 💡 注意：这是Debug版本，包含调试信息，文件较大。
    echo 🔧 如需Release版本，请解决AAPT2兼容性问题。
) else (
    echo ❌ Debug APK构建失败！
    pause
    exit /b 1
)

pause 