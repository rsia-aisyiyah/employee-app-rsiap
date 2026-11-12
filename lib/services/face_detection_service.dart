import 'dart:io';
import 'dart:ui' show Rect, Size;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FacePositionValidation {
  final bool isValid;
  final String instruction;

  const FacePositionValidation({
    required this.isValid,
    required this.instruction,
  });
}

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // For smile/eyes
      enableLandmarks: true, // For head position & facial landmarks validation
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<List<Face>> processImage(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  // --- POSITION & LANDMARKS VALIDATION ---
  FacePositionValidation validateFacePosition({
    required Face face,
    required Size imageSize,
    required Rect targetRect,
    String? livenessChallenge,
  }) {
    final faceRect = face.boundingBox;
    final double nx = faceRect.left / imageSize.width;
    final double ny = faceRect.top / imageSize.height;
    final double nw = faceRect.width / imageSize.width;
    final double nh = faceRect.height / imageSize.height;
    final Rect normalizedFace = Rect.fromLTWH(nx, ny, nw, nh);
    final faceCenter = normalizedFace.center;

    // 1. Cek ukuran proporsi wajah (jangan terlalu jauh atau terlalu dekat)
    if (nw < 0.26 || nh < 0.26) {
      return const FacePositionValidation(
        isValid: false,
        instruction: "Dekatkan wajah ke dalam bingkai",
      );
    }

    if (nw > 0.82 || nh > 0.85) {
      return const FacePositionValidation(
        isValid: false,
        instruction: "Mundurkan sedikit wajah Anda",
      );
    }

    // 2. Cek apakah titik tengah wajah berada di dalam area oval target
    if (!targetRect.contains(faceCenter)) {
      return const FacePositionValidation(
        isValid: false,
        instruction: "Posisikan wajah tepat di tengah bingkai",
      );
    }

    // 3. Validasi Facial Landmarks (Mata, Hidung, Mulut)
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];

    // Jika salah satu landmark penting belum masuk (misal hanya dahi atau dagu saja)
    if (leftEye == null || rightEye == null || noseBase == null || bottomMouth == null) {
      return const FacePositionValidation(
        isValid: false,
        instruction: "Posisikan seluruh wajah di dalam bingkai",
      );
    }

    // 4. Validasi koordinat landmark dalam area target
    final double normLeftEyeY = leftEye.position.y / imageSize.height;
    final double normRightEyeY = rightEye.position.y / imageSize.height;
    final double normNoseY = noseBase.position.y / imageSize.height;
    final double normMouthY = bottomMouth.position.y / imageSize.height;

    // Pastikan orientasi vertikal normal: Mata di atas, hidung di tengah, mulut di bawah
    if (normNoseY <= normLeftEyeY || normNoseY <= normRightEyeY || normMouthY <= normNoseY) {
      return const FacePositionValidation(
        isValid: false,
        instruction: "Hadapkan wajah lurus ke arah kamera",
      );
    }

    // Pastikan landmark mata dan mulut berada di dalam batas vertikal bingkai
    if (normLeftEyeY < targetRect.top - 0.05 || normRightEyeY < targetRect.top - 0.05) {
      return const FacePositionValidation(
        isValid: false,
        instruction: "Turunkan sedikit posisi kamera/wajah",
      );
    }

    if (normMouthY > targetRect.bottom + 0.05) {
      return const FacePositionValidation(
        isValid: false,
        instruction: "Naikkan sedikit posisi kamera/wajah",
      );
    }

    // Cek kemiringan kepala (tilt & yaw)
    if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 20) {
      return const FacePositionValidation(
        isValid: false,
        instruction: "Luruskan posisi kepala Anda",
      );
    }

    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 22) {
      return const FacePositionValidation(
        isValid: false,
        instruction: "Hadapkan wajah lurus ke depan",
      );
    }

    // 5. Semua validasi lolos -> Siap untuk liveness challenge!
    String instruction = "";
    if (livenessChallenge == 'blink') {
      instruction = "Silakan KEDIPKAN MATA";
    } else if (livenessChallenge == 'smile') {
      instruction = "Silakan TERSENYUM";
    } else {
      instruction = "Tahan posisi wajah...";
    }

    return FacePositionValidation(
      isValid: true,
      instruction: instruction,
    );
  }

  // --- LIVENESS CHECKS ---
  bool detectBlink(Face face) {
    if (face.leftEyeOpenProbability == null ||
        face.rightEyeOpenProbability == null) {
      return false;
    }
    return face.leftEyeOpenProbability! < 0.35 &&
        face.rightEyeOpenProbability! < 0.35;
  }

  bool detectSmile(Face face) {
    if (face.smilingProbability == null) return false;
    return face.smilingProbability! > 0.50;
  }

  bool detectLookLeft(Face face) {
    if (face.headEulerAngleY == null) return false;
    return face.headEulerAngleY! > 25;
  }

  bool detectLookRight(Face face) {
    if (face.headEulerAngleY == null) return false;
    return face.headEulerAngleY! < -25;
  }

  bool detectLookUp(Face face) {
    if (face.headEulerAngleX == null) return false;
    return face.headEulerAngleX! > 15;
  }

  // --- IMAGE COMPRESSION HELPER ---
  static Future<File> compressImage(File file, {int maxDimension = 640, int quality = 80}) async {
    try {
      final String inputPath = file.path;
      final tempDir = await getTemporaryDirectory();
      final String outputPath = p.join(
        tempDir.path,
        "face_opt_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      final resultPath = await compute(_compressImageIsolate, {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'maxDimension': maxDimension.toString(),
        'quality': quality.toString(),
      });

      return File(resultPath);
    } catch (e) {
      debugPrint("Face image compression fallback: $e");
      return file;
    }
  }

  static Future<String> _compressImageIsolate(Map<String, String> params) async {
    final inputFile = File(params['inputPath']!);
    final bytes = await inputFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return params['inputPath']!;

    final int maxDim = int.tryParse(params['maxDimension'] ?? '640') ?? 640;
    final int qual = int.tryParse(params['quality'] ?? '80') ?? 80;

    if (image.width > maxDim || image.height > maxDim) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? maxDim : null,
        height: image.height > image.width ? maxDim : null,
        interpolation: img.Interpolation.linear,
      );
    }

    final compressedBytes = img.encodeJpg(image, quality: qual);
    final outputFile = File(params['outputPath']!);
    await outputFile.writeAsBytes(compressedBytes);
    return outputFile.path;
  }

  void dispose() {
    _faceDetector.close();
  }
}
