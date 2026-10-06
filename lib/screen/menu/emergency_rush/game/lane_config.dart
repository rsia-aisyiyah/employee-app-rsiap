enum Lane {
  left,
  center,
  right;

  Lane get toLeft {
    if (this == Lane.right) return Lane.center;
    if (this == Lane.center) return Lane.left;
    return Lane.left;
  }

  Lane get toRight {
    if (this == Lane.left) return Lane.center;
    if (this == Lane.center) return Lane.right;
    return Lane.right;
  }
}

class RoadConfig {
  static const int laneCount = 3;

  /// Calculate lane center X given total screen width
  static double getLaneCenterX({
    required Lane lane,
    required double roadWidth,
    required double roadStartX,
  }) {
    final laneWidth = roadWidth / laneCount;
    return roadStartX + (lane.index * laneWidth) + (laneWidth / 2);
  }

  /// Get lane width given total road width
  static double getLaneWidth(double roadWidth) {
    return roadWidth / laneCount;
  }
}
