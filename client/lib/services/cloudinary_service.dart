import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudinary_api/src/request/model/uploader_params.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/uploader/uploader_response.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryService {
  CloudinaryService._();

  static final Cloudinary _cloudinary = Cloudinary.fromStringUrl(
    CloudinaryConfig.cloudinaryUrl,
  )..config.urlConfig.secure = true;

  static Future<String> uploadProfileImage(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final uploader = _cloudinary.uploader();

    final response = await uploader.upload(
      file,
      params: UploadParams(
        unsigned: true,
        uploadPreset: CloudinaryConfig.uploadPreset,
        folder: CloudinaryConfig.profileFolder,
        resourceType: 'image',
      ),
      progressCallback: (count, total) {
        if (total > 0 && onProgress != null) {
          onProgress(count / total);
        }
      },
    );

    if (response == null) {
      throw Exception('Aucune réponse reçue du service Cloudinary.');
    }

    _assertSuccess(response);

    final secureUrl = response.data?.secureUrl ?? response.data?.url;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary n\'a pas renvoyé d\'URL sécurisée.');
    }

    return secureUrl;
  }

  static Future<String> uploadProfileImageBytes(
    Uint8List bytes, {
    String? fileName,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.05);

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = CloudinaryConfig.profileFolder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename:
              fileName ?? 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Téléversement Cloudinary échoué (code: ${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl =
        decoded['secure_url']?.toString() ?? decoded['url']?.toString();

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary n\'a pas renvoyé d\'URL sécurisée.');
    }

    onProgress?.call(1.0);
    return secureUrl;
  }

  static void _assertSuccess(UploaderResponse response) {
    if (response.error != null) {
      throw Exception(response.error?.message ?? 'Erreur Cloudinary.');
    }

    final statusCode = response.responseCode;
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Téléversement Cloudinary échoué (code: $statusCode).');
    }
  }
}
