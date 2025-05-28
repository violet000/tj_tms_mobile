/// 密码加密工具类
///
/// @author zhangxiao
/// @Created time  2021-06-02
/// @Modified time 2021-06-02
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'sm4_util.dart';

/// 加密方式枚举类
const Map<String, String> ENCRYPT_ENUM = {
  'MD5_SALT': 'MD5_SALT',
  'SM4_SALT': 'SM4_SALT',
  'SHA256': 'SHA256',
};

/// 密码加密
/// [password] 密码
/// [type] 加密方式
String passwordEncrypt(String password, [String type = '']) {
  if (password.isEmpty) {
    return '';
  }

  String cipherText = ''; // 密文
  
  if (type == ENCRYPT_ENUM['MD5_SALT']) {
    var bytes = utf8.encode(password + 'messi');
    var digest = md5.convert(bytes);
    cipherText = digest.toString();
  } else if (type == ENCRYPT_ENUM['SHA256']) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    cipherText = digest.toString();
  } else { // 默认加密方式 -- 系统用户使用此种加密方式 -- SM4加盐加密
    cipherText = SM4Util().encryptData_ECB(password);
  }
  
  return cipherText;
} 