import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:shift_happens/utils/constants.dart';

/// Simula un corredor / túnel en perspectiva que avanza hacia el jugador.
///
/// No usa modelos 3D: la sensación de profundidad se logra dibujando formas
/// geométricas cuyas coordenadas se interpolan linealmente entre un punto de
/// fuga (lejos) y el borde inferior de la pantalla (cerca del jugador).
///
/// El scroll es vertical (los elementos avanzan de arriba hacia abajo) y su
/// velocidad aumenta progresivamente con el tiempo. Los colores cambian según
/// la realidad activa.
class ScrollingBackground extends PositionComponent {
  ScrollingBackground();

  // -------------------------------------------------------------------------
  // Parámetros de scroll y perspectiva
  // -------------------------------------------------------------------------
  static const double _baseSpeed = 1.2; // progreso por segundo
  static const double _acceleration = 0.4; // aumento de velocidad por segundo
  static const double _maxSpeed = 6.0;
  static const double _spawnInterval = 0.12; // segundos entre segmentos

  double _speed = _baseSpeed;
  double _time = 0.0;
  double _spawnTimer = 0.0;

  final List<_Segment> _segments = [];

  // Geometría de perspectiva (se reconstruye al cargar)
  late Vector2 _vanishingPoint;
  late double _bottomY;
  late double _centerX;
  late double _vanishingHalfWidth;
  late double _bottomHalfWidth;

  // Colores según la realidad actual
  late Color _backgroundColor;
  late Color _groundColor;
  late Color _segmentColor;

  Reality _currentReality = Reality.realityA;

  // -------------------------------------------------------------------------
  // Ciclo de vida
  // -------------------------------------------------------------------------
  @override
  void onLoad() {
    super.onLoad();
    size = game!.size;
    _rebuildGeometry();
    _updateColors();
  }

  void _rebuildGeometry() {
    _centerX = size.x / 2;
    _bottomY = size.y;
    _vanishingPoint = Vector2(_centerX, size.y * 0.22);
    _vanishingHalfWidth = 8.0; // calzada casi nula en el horizonte
    _bottomHalfWidth = size.x * 0.42; // ancho de la calzada junto al jugador
  }

  void _updateColors() {
    final palette = realityPalettes[_currentReality];
    if (palette == null) return;
    _backgroundColor = palette.background;
    _groundColor = palette.ground;
    _segmentColor = palette.obstacle;
  }

  // -------------------------------------------------------------------------
  // API pública
  // -------------------------------------------------------------------------

  /// Establece la realidad activa y actualiza los colores del fondo.
  void setReality(Reality reality) {
    if (_currentReality == reality) return;
    _currentReality = reality;
    _updateColors();
  }

  /// Ajusta la velocidad de scroll (llamado desde [SpawnManager] o el juego).
  void setSpeed(double speed) {
    _speed = speed.clamp(0.0, _maxSpeed);
  }

  /// Devuelve la velocidad actual de scroll.
  double get speed => _speed;

  /// Reinicia el fondo: velocidad base, tiempo y segmentos vacíos.
  void reset() {
    _time = 0.0;
    _speed = _baseSpeed;
    _spawnTimer = 0.0;
    _segments.clear();
  }

  // -------------------------------------------------------------------------
  // Update / Render
  // -------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);

    // Aumentar velocidad progresivamente con el tiempo
    _time += dt;
    _speed = (_baseSpeed + _acceleration * _time).clamp(0.0, _maxSpeed);

    // Spawn de nuevos segmentos en el horizonte (progreso 0)
    _spawnTimer += dt;
    while (_spawnTimer >= _spawnInterval) {
      _spawnTimer -= _spawnInterval;
      _segments.add(_Segment(progress: 0.0));
    }

    // Avanzar segmentos hacia el jugador (progreso 0 -> 1)
    for (final segment in _segments) {
      segment.progress += _speed * dt;
    }

    // Eliminar segmentos que ya pasaron al jugador
    _segments.removeWhere((s) => s.progress >= 1.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fondo plano
    final bgPaint = Paint()..color = _backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // Suelo / calzada: trapecio entre el horizonte y el borde inferior
    final groundPaint = Paint()..color = _groundColor;
    final groundPath = Path()
      ..moveTo(_vanishingPoint.x - _vanishingHalfWidth, _vanishingPoint.y)
      ..lineTo(_vanishingPoint.x + _vanishingHalfWidth, _vanishingPoint.y)
      ..lineTo(_centerX + _bottomHalfWidth, _bottomY)
      ..lineTo(_centerX - _bottomHalfWidth, _bottomY)
      ..close();
    canvas.drawPath(groundPath, groundPaint);

    // Líneas del borde de la calzada (convergentes al punto de fuga)
    final edgePaint = Paint()
      ..color = _groundColor.withOpacity(0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Vector2(_centerX - _bottomHalfWidth, _bottomY),
      Vector2(_vanishingPoint.x - _vanishingHalfWidth, _vanishingPoint.y),
      edgePaint,
    );
    canvas.drawLine(
      Vector2(_centerX + _bottomHalfWidth, _bottomY),
      Vector2(_vanishingPoint.x + _vanishingHalfWidth, _vanishingPoint.y),
      edgePaint,
    );

    // Línea central divisoria
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Vector2(_centerX, _vanishingPoint.y),
      Vector2(_centerX, _bottomY),
      centerPaint,
    );

    // Segmentos que avanzan hacia el jugador
    final segmentPaint = Paint()..color = _segmentColor;
    for (final segment in _segments) {
      final y = _lerp(_vanishingPoint.y, _bottomY, segment.progress);
      final halfW = _lerp(_vanishingHalfWidth, _bottomHalfWidth, segment.progress);
      final thickness = 6.0 + segment.progress * 24.0;

      canvas.drawRect(
        Rect.fromCenter(
          center: Vector2(_centerX, y),
          width: halfW * 2,
          height: thickness,
        ),
        segmentPaint,
      );
    }

    // Postes laterales que crecen al acercarse (refuerzan la sensación de profundidad)
    final postPaint = Paint()..color = _segmentColor.withOpacity(0.75);
    for (final segment in _segments) {
      if (segment.progress < 0.04) continue;
      final y = _lerp(_vanishingPoint.y, _bottomY, segment.progress);
      final halfW = _lerp(_vanishingHalfWidth, _bottomHalfWidth, segment.progress);
      final postHeight = 4.0 + segment.progress * 18.0;
      final postWidth = 3.0 + segment.progress * 6.0;

      canvas.drawRect(
        Rect.fromCenter(
          center: Vector2(_centerX - halfW, y),
          width: postWidth,
          height: postHeight,
        ),
        postPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Vector2(_centerX + halfW, y),
          width: postWidth,
          height: postHeight,
        ),
        postPaint,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _Segment {
  double progress;
  _Segment({required this.progress});
}
