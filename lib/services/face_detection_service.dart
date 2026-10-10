import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // For smile/eyes
      enableLandmarks: true, // For head position
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<List<Face>> processImage(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  // --- LIVENESS CHECKS ---

  bool detectBlink(Face face) {
    if (face.leftEyeOpenProbability == null ||
        face.rightEyeOpenProbability == null) {
      return false;
    }

    // Both eyes closed < 0.35 (tolerant to glasses, glare, and Asian eye shape)
    return face.leftEyeOpenProbability! < 0.35 &&
        face.rightEyeOpenProbability! < 0.35;
  }

  bool detectSmile(Face face) {
    if (face.smilingProbability == null) return false;
    // Lowered slightly from 0.7 to 0.55 for natural subtle smile
    return face.smilingProbability! > 0.55;
  }

  bool detectLookLeft(Face face) {
    if (face.headEulerAngleY == null) return false;
    // Looking left usually means positive angle > 20 degrees
    // Note: Depends on camera mirroring. Let's assume standard front camera.
    // Actually standard front camera often mirrors.
    // Let's allow a range. Typically > 15-20 degrees.
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

  void dispose() {
    _faceDetector.close();
  }
}
