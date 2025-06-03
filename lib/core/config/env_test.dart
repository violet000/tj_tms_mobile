import 'env_config.dart';

// 测试环境配置
class TestConfig {
  static EnvConfig get config => EnvConfig(
        apiBaseUrl: 'https://test-api.example.com',
        appName: 'TMS Mobile Test',
        enableLogging: true,
        environment: Environment.test,
      );
} 