/// 活体检测配置
class LivenessConfig {
  /// SDK算法授权码
  static const String license = "your_license_here";
  
  /// SDK包名授权码
  static const String packageLicense = "your_package_license_here";
  
  /// 服务器地址（用于后端检测）
  static const String serverUrl = "https://your-server.com";
  
  /// 服务器用户名
  static const String serverUsername = "username";
  
  /// 服务器密码
  static const String serverPassword = "password";
  
  /// 检测动作数量
  static const int actionCount = 2;
  
  /// 是否随机选取动作
  static const bool randomAction = true;
  
  /// 准备阶段超时时间（秒）
  static const int prepareStageTimeout = 0;
  
  /// 检测阶段超时时间（秒）
  static const int actionStageTimeout = 8;
  
  /// 是否播放提示语音
  static const bool playSound = true;
  
  /// 是否显示准备页面
  static const bool showReadyPage = true;
  
  /// 是否显示检测成功页面
  static const bool showSuccessResultPage = true;
  
  /// 是否显示检测失败页面
  static const bool showFailResultPage = true;
  
  /// 最佳人脸压缩比例
  static const int imageCompressionRatio = 90;
  
  /// 摄像头选择（前置/后置）
  static const int cameraFacing = 1; // 1: 前置, 0: 后置
  
  /// 炫光设置
  static const int flashType = 1; // 1: 开启, 0: 关闭
  
  /// 防Hack方式
  static const int hackMode = 1; // 1: 后端防Hack, 0: 前端防Hack

  /// 是否显示蒙版图
  static const bool showMaskImage = false;

  /// 蒙版图资源id（Android原生资源）
  static const int maskImageResourceId = 0;

  /// 是否打开动作不一致检测
  static const bool openActionDetectConsistent = true;

  /// 动作不一致是否中断
  static const bool actionInconsistentInterrupt = true;

  /// 是否显示切换摄像头按钮
  static const bool showSwitchCamera = false;
} 