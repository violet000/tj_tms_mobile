# tj_tms_mobile

天津银行(外勤手持机)移动应用

## 项目概述

- 插件集成：集成C71手持机厂商的DeviceAPI_ver20250209_release.aar包
- 应用框架：Flutter 3.4.0 + Dart + Android SDK

## 插件环境
- 插件需要使用flutter_bmflocation插件，放入的目录层级和当前项目一个层级，从Git上进行拉取，

## 环境要求

### 1. Java环境
```
java --version
java 11 2018-09-25
Java(TM) SE Runtime Environment 18.9 (build 11+28)
Java HotSpot(TM) 64-Bit Server VM 18.9 (build 11+28, mixed mode)
```

### 2. Gradle环境
```
Gradle 7.3.3
Build time:   2021-12-22 12:37:54 UTC
Revision:     6f556c80f945dc54b50e0be633da6c62dbe8dc71
Kotlin:       1.5.31
Groovy:       3.0.9
Ant:          Apache Ant(TM) version 1.10.11
JVM:          11 (Oracle Corporation 11+28)
OS:           Windows 10 10.0 amd64
```

### 3. Flutter环境
```
Flutter (Channel dev, 3.4.0-17.2.pre)
• Flutter version 3.4.0-17.2.pre on channel dev
• Framework revision d6260f127f
• Engine revision 3950c6140a
• Dart version 2.19.0
• DevTools version 2.16.0
```

### 4. Android环境
```
Android toolchain - develop for Android devices (Android SDK version 35.0.1)
• Android SDK at C:\Users\15590\Documents\AndroidSDKManager
• Platform android-35, build-tools 35.0.1
```

## 环境配置

### 1. Android配置修改

#### 1.1 修改 android/build.gradle

将 repositories 配置修改为：
```gradle
repositories {
    maven { url 'https://maven.aliyun.com/repository/google' }
    maven { url 'https://maven.aliyun.com/repository/public' }
    maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
    maven { url 'https://mirrors.tuna.tsinghua.edu.cn/flutter/download.flutter.io' }
    google()
    mavenCentral()
}
```

将 dependencies 配置修改为：
```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:7.3.0'
    classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
}
```

#### 1.2 修改 android/gradle.properties

```properties
org.gradle.java.home=C:\\Users\\15590\\Documents\\JDK11
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
systemProp.http.ssl.allowAll=true
systemProp.https.ssl.allowAll=true
org.gradle.welcome=never
org.gradle.unsafe.configuration=true
org.gradle.internal.http.connectionTimeout=120000
org.gradle.internal.http.socketTimeout=120000
org.gradle.internal.http.ssl.allowAll=true
org.gradle.internal.http.ssl.verify=false
```

#### 1.3 修改 gradle/wrapper/gradle-wrapper.properties

```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://mirrors.aliyun.com/macports/distfiles/gradle/gradle-7.4-all.zip
```

## APK打包配置

### 1. 签名配置

#### 1.1 创建 key.properties 文件
```properties
storePassword=itms_chengdu
keyPassword=itms_chengdu
keyAlias=key
storeFile=./key.jks
```

#### 1.2 修改 android/app/build.gradle

在 android { 之前添加：
```gradle
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
```

在 android { 中添加：
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    debug {
        signingConfig signingConfigs.release
        minifyEnabled false
        shrinkResources false
    }

    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        zipAlignEnabled true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 2. 打包步骤

1. 将 key.jks 文件放置在 android/app 目录下
2. 执行打包命令：
```
flutter build apk --release
```

生成的APK文件将位于：`build/app/outputs/flutter-apk/app-release.apk`

## 注意事项

1. 确保所有环境变量正确配置
2. 签名文件（key.jks）请妥善保管
3. 不要将签名相关文件提交到版本控制系统
4. 建议在 .gitignore 中添加：
```
**/android/key.properties
**/android/app/key.jks
```

### 注意事项：
# 1.修改app的icon图标
- 先确认flutter_icons下的图标路径是否正确，然后再执行flutter pub run flutter_launcher_icons:main命令去替换图标

# 2.修改启动屏splash图片
- 先确认flutter_native_splash下的启动屏的路径，然后使用flutter pub run flutter_native_splash:create去替换启动屏图片

### config目录下为项目的环境配置目录
- 开发环境：使用 flutter run 或 IDE 的调试模式
- 测试环境：使用 flutter run --profile
- 生产环境：使用 flutter run --release 或构建发布版本