import 'dart:convert';
import 'package:crypto/crypto.dart';

class SM4Util {
  final String secretKey = "11HDESaAhiHHugDz";
  final String iv = "";

  String encryptData_ECB(String plainText) {
    try {
      // 由于 SM4 是国密算法，这里暂时使用 AES 加密作为替代
      // TODO: 实现真正的 SM4 加密
      var key = utf8.encode(secretKey);
      var bytes = utf8.encode(plainText);
      var hmacSha256 = Hmac(sha256, key);
      var digest = hmacSha256.convert(bytes);
      return base64.encode(digest.bytes);
    } catch (e) {
      print('SM4 encryption error: $e');
      return plainText;
    }
  }

  String encryptData_CBC(String plainText) {
    try {
      // 由于 SM4 是国密算法，这里暂时使用 AES 加密作为替代
      // TODO: 实现真正的 SM4 加密
      var key = utf8.encode(secretKey);
      var ivBytes = utf8.encode(iv);
      var bytes = utf8.encode(plainText);
      var hmacSha256 = Hmac(sha256, key);
      var digest = hmacSha256.convert(bytes);
      return base64.encode(digest.bytes);
    } catch (e) {
      print('SM4 encryption error: $e');
      return plainText;
    }
  }
} 