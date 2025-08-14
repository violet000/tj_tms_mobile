import 'env_config.dart';

// 测试环境配置
class TestConfig {
  static EnvConfig get config => EnvConfig(
        apiBaseUrl: 'http://10.7.100.30',
        appName: '天津银行配送系统(测试环境)',
        enableLogging: true,
        environment: Environment.test,
      );
} 