import 'dart:typed_data';
import 'base64.dart';

class SM4Context {
  int mode = 1;
  bool isPadding = true;
  List<int> sk = List<int>.filled(32, 0);
}

class SM4 {
  static const int SM4_ENCRYPT = 1;
  static const int SM4_DECRYPT = 0;

  static const List<int> SboxTable = [
    0xd6, 0x90, 0xe9, 0xfe, 0xcc, 0xe1, 0x3d, 0xb7, 0x16, 0xb6, 0x14, 0xc2, 0x28, 0xfb, 0x2c, 0x05,
    0x2b, 0x67, 0x9a, 0x76, 0x2a, 0xbe, 0x04, 0xc3, 0xaa, 0x44, 0x13, 0x26, 0x49, 0x86, 0x06, 0x99,
    0x9c, 0x42, 0x50, 0xf4, 0x91, 0xef, 0x98, 0x7a, 0x33, 0x54, 0x0b, 0x43, 0xed, 0xcf, 0xac, 0x62,
    0xe4, 0xb3, 0x1c, 0xa9, 0xc9, 0x08, 0xe8, 0x95, 0x80, 0xdf, 0x94, 0xfa, 0x75, 0x8f, 0x3f, 0xa6,
    0x47, 0x07, 0xa7, 0xfc, 0xf3, 0x73, 0x17, 0xba, 0x83, 0x59, 0x3c, 0x19, 0xe6, 0x85, 0x4f, 0xa8,
    0x68, 0x6b, 0x81, 0xb2, 0x71, 0x64, 0xda, 0x8b, 0xf8, 0xeb, 0x0f, 0x4b, 0x70, 0x56, 0x9d, 0x35,
    0x1e, 0x24, 0x0e, 0x5e, 0x63, 0x58, 0xd1, 0xa2, 0x25, 0x22, 0x7c, 0x3b, 0x01, 0x21, 0x78, 0x87,
    0xd4, 0x00, 0x46, 0x57, 0x9f, 0xd3, 0x27, 0x52, 0x4c, 0x36, 0x02, 0xe7, 0xa0, 0xc4, 0xc8, 0x9e,
    0xea, 0xbf, 0x8a, 0xd2, 0x40, 0xc7, 0x38, 0xb5, 0xa3, 0xf7, 0xf2, 0xce, 0xf9, 0x61, 0x15, 0xa1,
    0xe0, 0xae, 0x5d, 0xa4, 0x9b, 0x34, 0x1a, 0x55, 0xad, 0x93, 0x32, 0x30, 0xf5, 0x8c, 0xb1, 0xe3,
    0x1d, 0xf6, 0xe2, 0x2e, 0x82, 0x66, 0xca, 0x60, 0xc0, 0x29, 0x23, 0xab, 0x0d, 0x53, 0x4e, 0x6f,
    0xd5, 0xdb, 0x37, 0x45, 0xde, 0xfd, 0x8e, 0x2f, 0x03, 0xff, 0x6a, 0x72, 0x6d, 0x6c, 0x5b, 0x51,
    0x8d, 0x1b, 0xaf, 0x92, 0xbb, 0xdd, 0xbc, 0x7f, 0x11, 0xd9, 0x5c, 0x41, 0x1f, 0x10, 0x5a, 0xd8,
    0x0a, 0xc1, 0x31, 0x88, 0xa5, 0xcd, 0x7b, 0xbd, 0x2d, 0x74, 0xd0, 0x12, 0xb8, 0xe5, 0xb4, 0xb0,
    0x89, 0x69, 0x97, 0x4a, 0x0c, 0x96, 0x77, 0x7e, 0x65, 0xb9, 0xf1, 0x09, 0xc5, 0x6e, 0xc6, 0x84,
    0x18, 0xf0, 0x7d, 0xec, 0x3a, 0xdc, 0x4d, 0x20, 0x79, 0xee, 0x5f, 0x3e, 0xd7, 0xcb, 0x39, 0x48
  ];

  static const List<int> FK = [0xa3b1bac6, 0x56aa3350, 0x677d9197, 0xb27022dc];

  static const List<int> CK = [
    0x00070e15, 0x1c232a31, 0x383f464d, 0x545b6269,
    0x70777e85, 0x8c939aa1, 0xa8afb6bd, 0xc4cbd2d9,
    0xe0e7eef5, 0xfc030a11, 0x181f262d, 0x343b4249,
    0x50575e65, 0x6c737a81, 0x888f969d, 0xa4abb2b9,
    0xc0c7ced5, 0xdce3eaf1, 0xf8ff060d, 0x141b2229,
    0x30373e45, 0x4c535a61, 0x686f767d, 0x848b9299,
    0xa0a7aeb5, 0xbcc3cad1, 0xd8dfe6ed, 0xf4fb0209,
    0x10171e25, 0x2c333a41, 0x484f565d, 0x646b7279
  ];

  int getULongBE(List<int> b, int i) {
    return ((b[i] & 0xff) << 24) |
        ((b[i + 1] & 0xff) << 16) |
        ((b[i + 2] & 0xff) << 8) |
        (b[i + 3] & 0xff) & 0xffffffff;
  }

  void putULongBE(int n, List<int> b, int i) {
    int t1 = (0xFF & (n >> 24));
    int t2 = (0xFF & (n >> 16));
    int t3 = (0xFF & (n >> 8));
    int t4 = (0xFF & (n));
    b[i] = t1 > 128 ? t1 - 256 : t1;
    b[i + 1] = t2 > 128 ? t2 - 256 : t2;
    b[i + 2] = t3 > 128 ? t3 - 256 : t3;
    b[i + 3] = t4 > 128 ? t4 - 256 : t4;
  }

  int shl(int x, int n) {
    return (x & 0xFFFFFFFF) << n;
  }

  int rotl(int x, int n) {
    return shl(x, n) | (x >> (32 - n));
  }

  int sm4Lt(int ka) {
    int bb = 0;
    int c = 0;
    List<int> a = List<int>.filled(4, 0);
    List<int> b = List<int>.filled(4, 0);
    putULongBE(ka, a, 0);
    b[0] = sm4Sbox(a[0]);
    b[1] = sm4Sbox(a[1]);
    b[2] = sm4Sbox(a[2]);
    b[3] = sm4Sbox(a[3]);
    bb = getULongBE(b, 0);
    c = bb ^ rotl(bb, 2) ^ rotl(bb, 10) ^ rotl(bb, 18) ^ rotl(bb, 24);
    return c;
  }

  int sm4F(int x0, int x1, int x2, int x3, int rk) {
    return x0 ^ sm4Lt(x1 ^ x2 ^ x3 ^ rk);
  }

  int sm4CalciRK(int ka) {
    int bb = 0;
    int rk = 0;
    List<int> a = List<int>.filled(4, 0);
    List<int> b = List<int>.filled(4, 0);
    putULongBE(ka, a, 0);
    b[0] = sm4Sbox(a[0]);
    b[1] = sm4Sbox(a[1]);
    b[2] = sm4Sbox(a[2]);
    b[3] = sm4Sbox(a[3]);
    bb = getULongBE(b, 0);
    rk = bb ^ rotl(bb, 13) ^ rotl(bb, 23);
    return rk;
  }

  int sm4Sbox(int inch) {
    int i = inch & 0xFF;
    int retVal = SboxTable[i];
    return retVal > 128 ? retVal - 256 : retVal;
  }

  bool sm4SetkeyEnc(SM4Context ctx, List<int> key) {
    if (ctx == null) {
      throw Exception("ctx is null!");
    }
    if (key == null || key.length != 16) {
      throw Exception("key error!");
    }
    ctx.mode = SM4_ENCRYPT;
    sm4Setkey(ctx.sk, key);
    return true;
  }

  void sm4Setkey(List<int> SK, List<int> key) {
    List<int> MK = List<int>.filled(4, 0);
    List<int> k = List<int>.filled(36, 0);
    MK[0] = getULongBE(key, 0);
    MK[1] = getULongBE(key, 4);
    MK[2] = getULongBE(key, 8);
    MK[3] = getULongBE(key, 12);
    k[0] = MK[0] ^ FK[0];
    k[1] = MK[1] ^ FK[1];
    k[2] = MK[2] ^ FK[2];
    k[3] = MK[3] ^ FK[3];
    for (int i = 0; i < 32; i++) {
      k[(i + 4)] = (k[i] ^ sm4CalciRK(k[(i + 1)] ^ k[(i + 2)] ^ k[(i + 3)] ^ CK[i]));
      SK[i] = k[(i + 4)];
    }
  }

  List<int>? padding(List<int>? input, int mode) {
    if (input == null) {
      return null;
    }
    List<int>? ret;
    if (mode == SM4_ENCRYPT) {
      int p = 16 - input.length % 16;
      ret = List<int>.from(input);
      for (int i = 0; i < p; i++) {
        ret.add(p);
      }
    } else {
      int p = input[input.length - 1];
      ret = input.sublist(0, input.length - p);
    }
    return ret;
  }

  void sm4OneRound(List<int> sk, List<int> input, List<int> output) {
    int i = 0;
    List<int> ulbuf = List<int>.filled(36, 0);
    ulbuf[0] = getULongBE(input, 0);
    ulbuf[1] = getULongBE(input, 4);
    ulbuf[2] = getULongBE(input, 8);
    ulbuf[3] = getULongBE(input, 12);
    while (i < 32) {
      ulbuf[(i + 4)] = sm4F(ulbuf[i], ulbuf[(i + 1)], ulbuf[(i + 2)], ulbuf[(i + 3)], sk[i]);
      i++;
    }
    putULongBE(ulbuf[35], output, 0);
    putULongBE(ulbuf[34], output, 4);
    putULongBE(ulbuf[33], output, 8);
    putULongBE(ulbuf[32], output, 12);
  }

  List<int> sm4CryptEcb(SM4Context ctx, List<int> input) {
    if (input == null) {
      throw Exception("input is null!");
    }
    if ((ctx.isPadding) && (ctx.mode == SM4_ENCRYPT)) {
      input = padding(input, SM4_ENCRYPT)!;
    }

    int i = 0;
    int length = input.length;
    List<int> bous = [];
    while (length > 0) {
      List<int> out = List<int>.filled(16, 0);
      List<int> ins = input.sublist(i * 16, (16 * (i + 1)));
      sm4OneRound(ctx.sk, ins, out);
      bous = [...bous, ...out];
      i++;
      length -= 16;
    }

    List<int> output = bous;
    if (ctx.isPadding && ctx.mode == SM4_DECRYPT) {
      output = padding(output, SM4_DECRYPT)!;
    }
    for (int i = 0; i < output.length; i++) {
      if (output[i] < 0) {
        output[i] = output[i] + 256;
      }
    }
    return output;
  }

  List<int> sm4CryptCbc(SM4Context ctx, List<int> iv, List<int> input) {
    if (iv == null || iv.length != 16) {
      throw Exception("iv error!");
    }

    if (input == null) {
      throw Exception("input is null!");
    }

    if (ctx.isPadding && ctx.mode == SM4_ENCRYPT) {
      input = padding(input, SM4_ENCRYPT)!;
    }

    int i = 0;
    int length = input.length;
    List<int> bous = [];
    if (ctx.mode == SM4_ENCRYPT) {
      int k = 0;
      while (length > 0) {
        List<int> out = List<int>.filled(16, 0);
        List<int> out1 = List<int>.filled(16, 0);
        List<int> ins = input.sublist(k * 16, (16 * (k + 1)));

        for (i = 0; i < 16; i++) {
          out[i] = (ins[i] ^ iv[i]);
        }
        sm4OneRound(ctx.sk, out, out1);
        iv = out1.sublist(0, 16);
        bous.addAll(out1);
        k++;
        length -= 16;
      }
    } else {
      List<int> temp = [];
      int k = 0;
      while (length > 0) {
        List<int> out = List<int>.filled(16, 0);
        List<int> out1 = List<int>.filled(16, 0);
        List<int> ins = input.sublist(k * 16, (16 * (k + 1)));
        temp = ins.sublist(0, 16);
        sm4OneRound(ctx.sk, ins, out);
        for (i = 0; i < 16; i++) {
          out1[i] = (out[i] ^ iv[i]);
        }
        iv = temp.sublist(0, 16);
        bous.addAll(out1);
        k++;
        length -= 16;
      }
    }

    List<int> output = bous;
    if (ctx.isPadding && ctx.mode == SM4_DECRYPT) {
      output = padding(output, SM4_DECRYPT)!;
    }

    for (int i = 0; i < output.length; i++) {
      if (output[i] < 0) {
        output[i] = output[i] + 256;
      }
    }
    return output;
  }
}

class SM4Util {
  String secretKey = "11HDESaAhiHHugDz";
  String iv = "";
  bool hexString = false;

  String encryptDataECB(String plainText) {
    try {
      SM4 sm4 = SM4();
      SM4Context ctx = SM4Context();
      ctx.isPadding = true;
      ctx.mode = SM4.SM4_ENCRYPT;
      List<int> keyBytes = stringToByte(secretKey);
      sm4.sm4SetkeyEnc(ctx, keyBytes);
      List<int> encrypted = sm4.sm4CryptEcb(ctx, stringToByte(plainText));
      String cipherText = base64Encode(encrypted);
      if (cipherText.isNotEmpty) {
        cipherText = cipherText.replaceAll(RegExp(r'(\s*|\t|\r|\n)'), '');
      }
      return cipherText;
    } catch (e) {
      print('Error: $e');
      return '';
    }
  }

  String encryptDataCBC(String plainText) {
    try {
      SM4 sm4 = SM4();
      SM4Context ctx = SM4Context();
      ctx.isPadding = true;
      ctx.mode = SM4.SM4_ENCRYPT;

      List<int> keyBytes = stringToByte(secretKey);
      List<int> ivBytes = stringToByte(iv);

      sm4.sm4SetkeyEnc(ctx, keyBytes);
      List<int> encrypted = sm4.sm4CryptCbc(ctx, ivBytes, stringToByte(plainText));
      String cipherText = base64Encode(encrypted);
      if (cipherText.isNotEmpty) {
        cipherText = cipherText.replaceAll(RegExp(r'(\s*|\t|\r|\n)'), '');
      }
      return cipherText;
    } catch (e) {
      print('Error: $e');
      return '';
    }
  }

  List<int> stringToByte(String str) {
    List<int> bytes = [];
    int len = str.length;
    for (int i = 0; i < len; i++) {
      int c = str.codeUnitAt(i);
      if (c >= 0x010000 && c <= 0x10FFFF) {
        bytes.add(((c >> 18) & 0x07) | 0xF0);
        bytes.add(((c >> 12) & 0x3F) | 0x80);
        bytes.add(((c >> 6) & 0x3F) | 0x80);
        bytes.add((c & 0x3F) | 0x80);
      } else if (c >= 0x000800 && c <= 0x00FFFF) {
        bytes.add(((c >> 12) & 0x0F) | 0xE0);
        bytes.add(((c >> 6) & 0x3F) | 0x80);
        bytes.add((c & 0x3F) | 0x80);
      } else if (c >= 0x000080 && c <= 0x0007FF) {
        bytes.add(((c >> 6) & 0x1F) | 0xC0);
        bytes.add((c & 0x3F) | 0x80);
      } else {
        bytes.add(c & 0xFF);
      }
    }
    return bytes;
  }

  String byteToString(List<int> arr) {
    String str = '';
    for (int i = 0; i < arr.length; i++) {
      String one = arr[i].toRadixString(2);
      RegExpMatch? v = RegExp(r'^1+?(?=0)').firstMatch(one);
      if (v != null && one.length == 8) {
        int bytesLength = v.group(0)!.length;
        String store = arr[i].toRadixString(2).substring(7 - bytesLength);
        for (int st = 1; st < bytesLength; st++) {
          store += arr[st + i].toRadixString(2).substring(2);
        }
        str += String.fromCharCode(int.parse(store, radix: 2));
        i += bytesLength - 1;
      } else {
        str += String.fromCharCode(arr[i]);
      }
    }
    return str;
  }
}

void main() {
  final sm4Util = SM4Util();
  print(sm4Util.encryptDataECB('kkshan1'));
}