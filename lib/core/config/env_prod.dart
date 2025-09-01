import 'env_config.dart';

// 生产环境配置
class ProdConfig {
  static Future<EnvConfig> get config async {
    return EnvConfig(
      apiBaseUrl: 'http://10.7.100.107',
      appName: '天津银行配送系统(生产环境)',
      enableLogging: true,
      environment: Environment.prod,
    );
  }
}