import 'package:flutter/foundation.dart';
import 'env_config.dart';
import 'env_dev.dart';
import 'env_test.dart';
import 'env_prod.dart';

class Env {
  static void init() {
    // 根据编译模式自动判断环境
    if (kDebugMode) {
      // 在调试模式下，默认使用开发环境
      DevConfig.config;
    } else if (kProfileMode) {
      // 在性能分析模式下，使用测试环境
      TestConfig.config;
    } else {
      // 在发布模式下，使用生产环境
      ProdConfig.config;
    }
  }

  static EnvConfig get config => EnvConfig.instance;
  
  static bool get isDevelopment => EnvConfig.isDevelopment();
  static bool get isTest => EnvConfig.isTest();
  static bool get isProduction => EnvConfig.isProduction();
} 