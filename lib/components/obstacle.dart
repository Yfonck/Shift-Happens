import 'package:flame/components.dart';
import 'package:flame/collision.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:shift_happens/utils/constants.dart';

/// Obstáculo del corredor. Aparece en el fondo y se acerca al jugador
/// creciendo en tamaño (simulación de perspectiva).
///
/// El hámster permanece fijo en su carril (no se mueve horizontalmente),
/// por lo tanto el obstáculo se desplaza hacia esa posición fija y la
/// colisión ocurre cuando el obstáculo llega al carril del jugador.
///
/// Su hitbox se escala junto con su tamaño visual para que la colisión sea
/// justa en toda su trayectoria.
class Obstacle extends PositionComponent with CollisionCallbacks {
  /// Si true, pertenece a la realidad A; si false, a la realidad B.
  final bool belongsToRealityA;

  /// Se ejecuta cuando este obstáculo colisiona con el hámster y las
  /// realidades coinciden (jugador pierde).
  final VoidCallback onHit;

  /// Se ejecuta cuando el obstáculo pasa de largo junto al jugador sin
  /// colisionar (jugador suma puntuación).
  final VoidCallback onPassed;

  /// Tamaño mínimo (lejos, en el horizonte) y máximo (cerca del jugador).
  static const double minSize = 16.0;
  static const double maxSize = 48.0;

  /// Progreso de desplazamiento: 0 = horizonte, 1 = junto al jugador.
  double _progress = 0.0;

  /// Velocidad de avance hacia el jugador (unidades por segundo).
  double _speed = 1.0;

  /// Posición inicial (horizonte) y destino (carril fijo del hámster).
  ///
  /// Como el hámster no se mueve horizontalmente, [_targetPosition] es
  /// constante: representa el punto de colisión fijo en pantalla.
  late final Vector2 _startPosition;
  late final Vector2 _targetPosition;

  /// Hitbox que se escala junto con el tamaño visual.
  late final RectangleHitbox hitbox;

  /// Realidad activa del jugador (establecida desde el juego / SpawnManager).
  Reality? playerReality;

  Obstacle({
    required Vector2 startPosition,
    required Vector2 targetPosition,
    required double speed,
    required this.belongsToRealityA,
    required this.onHit,
    required this.onPassed,
  })  : _startPosition = startPosition,
        _targetPosition = targetPosition,
        _speed = speed;

  @override
  Future<void> onLoad() async {
    _updateSize(_progress);
    position = _startPosition.clone();

    hitbox = RectangleHitbox(
      size: size,
      position: Vector2.zero(),
    );
    add(hitbox);
  }

  /// Recalcula el tamaño visual y sincroniza la hitbox con él.
  ///
  /// Se debe llamar cada vez que cambia [_progress] para que la hitbox
  /// tenga exactamente las mismas dimensiones que el cuadrado dibujado,
  /// evitando colisiones demasiado grandes o demasiado pequeñas.
  void _updateSize(double progress) {
    final s = minSize + (maxSize - minSize) * progress;
    size = Vector2(s, s);
    // La hitbox se mantiene alineada con el tamaño visual en todo momento.
    hitbox.size = size;
  }

  /// Establece la realidad activa del jugador para filtrar colisiones.
  void setPlayerReality(Reality reality) {
    playerReality = reality;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _progress = (_progress + _speed * dt).clamp(0.0, 1.0);

    // Interpolar posición entre el horizonte y el carril fijo del jugador.
    // El hámster no se desplaza horizontalmente, así que _targetPosition
    // representa el punto de colisión fijo en pantalla.
    position = Vector2.lerp(_startPosition, _targetPosition, _progress);

    // Escalar visual y hitbox según la cercanía al jugador.
    // Esto se ejecuta cada frame antes de que Flame evalúe colisiones,
    // por lo que la hitbox siempre coincide con el tamaño dibujado.
    _updateSize(_progress);

    // Si llegó al jugador, se considera esquivado (pasó de largo).
    if (_progress >= 1.0) {
      onPassed();
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, Component other) {
    // Solo reacciona si conocemos la realidad del jugador.
    if (playerReality == null) return;

    final playerInRealityA = playerReality == Reality.realityA;

    // Colisión peligrosa solo si el obstáculo y el jugador comparten realidad.
    if (playerInRealityA == belongsToRealityA) {
      onHit();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = belongsToRealityA
          ? RealityAPalette.obstacle
          : RealityBPalette.obstacle;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}
