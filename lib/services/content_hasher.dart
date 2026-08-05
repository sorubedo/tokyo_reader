import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 内容哈希器：用于计算书籍正文的内容指纹。
abstract interface class ContentHasher {
  Future<String> hash(String content);
}

/// 使用 SHA-256 计算正文哈希。
class Sha256ContentHasher implements ContentHasher {
  const Sha256ContentHasher();

  @override
  Future<String> hash(String content) async {
    return sha256.convert(utf8.encode(content)).toString();
  }
}
