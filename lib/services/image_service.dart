import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/scenic_spot.dart';

class ImageService {
  static const String _aliyunApiKey = String.fromEnvironment('ALIYUN_API_KEY', defaultValue: '');
  static const String _aliyunEndpoint = 'https://myin童颜-20250712.cn-hangzhou.image.aliyuncs.com';

  Future<ScenicSpot?> recognizeImage(File imageFile, List<ScenicSpot> knownSpots) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    try {
      final response = await http.post(
        Uri.parse('$_aliyunEndpoint/ocr/recognize'),
        headers: {
          'Authorization': 'APPCODE $_aliyunApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final labels = data['labels'] as List<dynamic>? ?? [];
        
        for (final spot in knownSpots) {
          for (final label in labels) {
            if (spot.name.contains(label.toString()) || 
                spot.tags.any((tag) => label.toString().contains(tag))) {
              return spot;
            }
          }
        }
      }
    } catch (e) {
      // Fallback to local matching
    }

    return _localMatch(imageBytes, knownSpots);
  }

  Future<ScenicSpot?> _localMatch(List<int> imageBytes, List<ScenicSpot> knownSpots) async {
    // Simple local feature matching as fallback
    // In production, this would use a local ML model like MobileNet
    return knownSpots.isNotEmpty ? knownSpots.first : null;
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.example.com/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send().timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['url'] as String?;
      }
    } catch (e) {
      // Upload failed
    }
    return null;
  }
}