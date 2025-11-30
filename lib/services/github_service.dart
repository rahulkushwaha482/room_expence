import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config.dart';

class GithubService {
  final Dio dio = Dio();
  final String branch;
  final String? token;

  GithubService({this.branch = "development"}) : token = dotenv.env['GITHUB_TOKEN'] {
    dio.options.headers['Accept'] = 'application/vnd.github+json';
    if (token != null && token!.isNotEmpty) {
      dio.options.headers['Authorization'] = 'token $token';
    }
  }

  /// Fetch JSON from public repo (raw.githubusercontent) - no auth
  Future<Map<String, dynamic>> fetchRawJson() async {
    final url =
        'https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/$GITHUB_PATH?ref=$branch';

    final res = await dio.get(url);

    final contentBase64 = res.data['content'] as String?;

    if (contentBase64 == null || contentBase64.trim().isEmpty) {
      throw Exception("GitHub file is empty or contains only whitespace");
    }

    // Normalize: remove line breaks and ensure proper padding
    final normalized = base64.normalize(contentBase64.replaceAll('\n', ''));

    final decoded = utf8.decode(base64Decode(normalized));

    try {
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Invalid JSON in GitHub file: $e\nDecoded content:\n$decoded");
    }
  }



  /// Fetch JSON from GitHub API (for authenticated operations)
  Future<Map<String, dynamic>> fetchJsonFromApi() async {
    final url =
        'https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/$GITHUB_PATH?ref=$branch';
    final res = await dio.get(url);

    final encodedContent = res.data['content'] as String;
    final decodedContent = utf8.decode(base64Decode(encodedContent));
    return jsonDecode(decodedContent) as Map<String, dynamic>;
  }

  /// Get file SHA from GitHub API (needed for updating)
  Future<String> getFileSha() async {
    final url =
        'https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/$GITHUB_PATH?ref=$branch';
    final res = await dio.get(url);
    return res.data['sha'] as String;
  }

  /// Update file on GitHub (requires token)
  Future<bool> updateFile(
      Map<String, dynamic> newJson, {
        String commitMessage = 'Update data.json from app',
      }) async {
    if (token == null || token!.isEmpty) {
      throw Exception("GitHub token is required to update the file");
    }

    final sha = await getFileSha();
    final encodedContent = base64Encode(utf8.encode(jsonEncode(newJson)));

    final url =
        'https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/contents/$GITHUB_PATH';

    final res = await dio.put(url, data: {
      "message": commitMessage,
      "content": encodedContent,
      "branch": branch,
      "sha": sha,
    });

    return res.statusCode == 200 || res.statusCode == 201;
  }
}
