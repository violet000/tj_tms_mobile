import 'env_config.dart';
// import '../utils/asset_loader.dart';

// 开发环境配置
class DevConfig {
  // static Future<Map<String, dynamic>> get locationConfig => AssetLoader.loadLocationConfig();
  
  static Future<EnvConfig> get config async {
    // final locationData = await locationConfig;
    // print('locationData: $locationData');
    return EnvConfig(
      apiBaseUrl: 'http://10.7.100.132',
      appName: '天津银行配送系统(开发环境)',
      enableLogging: true,
      environment: Environment.dev,
    );
  }
}