#!/bin/bash

# 构建优化的Debug APK脚本
echo "开始构建优化的Debug APK..."

# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 构建Debug APK
flutter build apk --debug

# 检查构建结果
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "✅ Debug APK构建成功！"
    echo "📱 APK位置: build/app/outputs/flutter-apk/app-debug.apk"
    echo "📊 APK大小: $(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)"
    
    # 显示APK信息
    echo ""
    echo "📋 APK信息:"
    aapt dump badging build/app/outputs/flutter-apk/app-debug.apk | grep -E "(package|sdkVersion|targetSdkVersion|application-label)"
    
    echo ""
    echo "🎉 构建完成！您可以使用这个Debug APK进行测试和部署。"
    echo "💡 注意：这是Debug版本，包含调试信息，文件较大。"
    echo "🔧 如需Release版本，请解决AAPT2兼容性问题。"
else
    echo "❌ Debug APK构建失败！"
    exit 1
fi 