import 'package:flutter/services.dart';

/// 活体检测配置
class LiveDetectionConfig {
    /// 会话ID（必填，需从服务器获取）
    final String sessionId;
    
    /// 动作序列（必填，需从服务器获取）
    final String actionSet;
    
    /// 场景ID（可选，不传则使用默认值 "300"）
    final String? sceneId;
    
    /// 流程ID（可选，不传则自动生成）
    final String? flowId;
    
    /// SDK参数（可选）
    final String? sdkParam;
    
    /// 授权码（可选，不传则使用默认授权码）
    final String? licence;

    LiveDetectionConfig({
      required this.sessionId,
      required this.actionSet,
      this.sceneId,
      this.flowId,
      this.sdkParam,
      this.licence,
    });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'actionSet': actionSet,
      if (sceneId != null) 'sceneId': sceneId,
      if (flowId != null) 'flowId': flowId,
      if (sdkParam != null) 'sdkParam': sdkParam,
      if (licence != null) 'licence': licence,
    };
  }
}

/// 活体检测结果
class LiveDetectionResult {
    /// 是否成功
    final bool success;
    
    /// 消息
    final String message;
    
    /// 数据
    final Map<String, dynamic>? data;

    LiveDetectionResult({
      required this.success,
      required this.message,
      this.data,
    });

  factory LiveDetectionResult.fromMap(Map<dynamic, dynamic> map) {
    // 安全地转换 data 字段
    Map<String, dynamic>? dataMap;
    final dynamic dataValue = map['data'];
    if (dataValue != null && dataValue is Map) {
      // 将 Map<dynamic, dynamic> 转换为 Map<String, dynamic>
      dataMap = Map<String, dynamic>.from(dataValue as Map);
    }
    
    return LiveDetectionResult(
      success: map['success'] as bool? ?? false,
      message: map['message'] as String? ?? '',
      data: dataMap,
    );
  }

  /// 获取错误代码
  int? get errorCode => data?['errorCode'] as int?;

  /// 获取错误消息
  String? get errorMsg => data?['errorMsg'] as String?;

  /// 是否取消
  bool get isCancelled => data?['cancelled'] as bool? ?? false;

  /// 获取hackParams（用于后端验证）
  String? get hackParams => data?['hackParams'] as String?;

  /// 获取加密工作密钥
  String? get encryptWorkKey => data?['encryptWorkKey'] as String?;

  /// 获取公钥索引
  String? get publicKeyIndex => data?['publicKeyIndex'] as String?;

  /// 获取摘要
  String? get summary => data?['summary'] as String?;

  /// 获取最佳人脸图片（Base64编码）
  String? get bestFace => data?['bestFace'] as String?;

  /// 获取裁剪后的最佳人脸图片（Base64编码）
  String? get clipedBestFace => data?['clipedBestFace'] as String?;
}

/// 云之盾活体人脸检测插件
/// 用于调用原生活体检测功能
class CloudwalkFacePlugin {
  static const MethodChannel _channel = MethodChannel('com.zijin.tj_tms_mobile/cloudwalk_face');

  /// 设置配置
  /// 
  /// [config] 配置参数
  static Future<bool> setConfig(LiveDetectionConfig config) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        'setConfig',
        <String, dynamic>{'config': config.toMap()},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('设置活体检测配置失败: ${e.message}');
      return false;
    }
  }

  /// 启动活体检测
  /// SDK会自动获取所需的参数（sessionId、actionSet等）
  /// 
  /// 返回检测结果
  static Future<LiveDetectionResult> startLiveDetection() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'startLiveDetection',
      );
      
      if (result != null) {
        return LiveDetectionResult.fromMap(result);
      } else {
        return LiveDetectionResult(
          success: false,
          message: '未返回结果',
        );
      }
    } on PlatformException catch (e) {
      print('启动活体检测失败: ${e.message}');
      return LiveDetectionResult(
        success: false,
        message: e.message ?? '启动活体检测失败',
        data: <String, dynamic>{
          'errorCode': e.code,
          'errorMsg': e.message,
        },
      );
    } catch (e) {
      print('启动活体检测异常: $e');
      return LiveDetectionResult(
        success: false,
        message: e.toString(),
      );
    }
  }
}

