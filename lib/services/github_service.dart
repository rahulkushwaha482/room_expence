import 'dart:convert';
import 'package:dio/dio.dart';
import '../config.dart';

class GithubService {
  final Dio dio = Dio();

  GithubService() {
    dio.options.headers['Accept'] = 'application/vnd.github+json';
    if (GITHUB_TOKEN.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $GITHUB_TOKEN';
    }
  }

  // Fetch raw JSON from raw.githubusercontent (fast, no auth)
  Future<Map<String, dynamic>> fetchRawJson() async {
    final rawUrl = 'https://raw.githubusercontent.com/$GITHUB_OWNER/$GITHUB_REPO/main/$GITHUB_PATH';
    final res = await dio.get(rawUrl);
    if (res.data is String) {
      // Sometimes raw returns text
      return jsonDecode(res.data as String) as Map<String, dynamic>;
    }
    return res.data as Map<String, dynamic>;
  }

  // Get file metadata (to obtain sha)
  Future<String> getFileSha() async {
    final url = 'https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/$GITHUB_PATH';
    final res = await dio.get(url);
    return res.data['sha'] as String;
  }

  Future<bool> updateFile(Map<String, dynamic> newJson, {String commitMessage = 'Update data.json from app'}) async {
    final sha = await getFileSha();
    final content = base64Encode(utf8.encode(jsonEncode(newJson)));

    final url = 'https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/$GITHUB_PATH';

    final res = await dio.put(url, data: {
      'message': commitMessage,
      'content': content,
      'sha': sha,
    });

    return res.statusCode == 200 || res.statusCode == 201;
  }
}
