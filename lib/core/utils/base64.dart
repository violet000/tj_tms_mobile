class Base64 {
  static const String _base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  static const int _base64Pad = 61; // ASCII value of '='

  static String encode(List<int> bytes) {
    if (bytes.isEmpty) return '';
    
    int i = 0;
    int len = bytes.length;
    String result = '';
    
    while (i < len) {
      int b1 = bytes[i++] & 0xff;
      result += _base64Chars[b1 >> 2];
      
      if (i == len) {
        result += _base64Chars[(b1 & 0x3) << 4];
        result += '==';
        break;
      }
      
      int b2 = bytes[i++] & 0xff;
      result += _base64Chars[((b1 & 0x3) << 4) | (b2 >> 4)];
      
      if (i == len) {
        result += _base64Chars[(b2 & 0xf) << 2];
        result += '=';
        break;
      }
      
      int b3 = bytes[i++] & 0xff;
      result += _base64Chars[((b2 & 0xf) << 2) | (b3 >> 6)];
      result += _base64Chars[b3 & 0x3f];
    }
    
    return result;
  }

  static List<int> decode(String str) {
    if (str.isEmpty) return [];
    
    // Remove padding
    str = str.replaceAll('=', '');
    
    List<int> result = [];
    int i = 0;
    int len = str.length;
    
    while (i < len) {
      int c1 = _base64Chars.indexOf(str[i++]);
      if (c1 == -1) continue;
      
      if (i == len) {
        result.add(c1 << 2);
        break;
      }
      
      int c2 = _base64Chars.indexOf(str[i++]);
      if (c2 == -1) continue;
      
      result.add((c1 << 2) | (c2 >> 4));
      
      if (i == len) {
        result.add((c2 & 0xf) << 4);
        break;
      }
      
      int c3 = _base64Chars.indexOf(str[i++]);
      if (c3 == -1) continue;
      
      result.add(((c2 & 0xf) << 4) | (c3 >> 2));
      
      if (i == len) {
        result.add((c3 & 0x3) << 6);
        break;
      }
      
      int c4 = _base64Chars.indexOf(str[i++]);
      if (c4 == -1) continue;
      
      result.add(((c3 & 0x3) << 6) | c4);
    }
    
    return result;
  }
}

// 为了保持与原有代码的兼容性，添加全局函数
String base64Encode(List<int> bytes) {
  return Base64.encode(bytes);
}

List<int> base64Decode(String str) {
  return Base64.decode(str);
} 