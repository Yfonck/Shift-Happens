import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart';

import 'package:shift_happens/utils/constants.dart';

/// Componente del hámster jugador.
///
/// Queda fijo en un carril central-bajo de la pantalla mientras el fondo
/// hace scroll para dar sensación de movimiento. Incluye una animación
/// simple de "correr en el sitio" (rebote vertical) y una hitbox rectangular
/// alineada con su posición visual.
class Hamster extends PositionComponent with KeyboardHandler {
  Hamster();

  /// Tamaño del cuadrado placeholder (en píxeles lógicos).
  static const double size = 40.0;

  /// Posición inicial del hámster (carril central-bajo).
  static const Vector2 initialPosition = Vector2(150.0, 450.0);

  /// Parámetros de la animación de correr en el sitio.
  static const double _bounceFrequency = 6.0; // ciclos por segundo
  static const double _bounceAmplitude = 6.0; // píxeles de rebote

  /// Hitbox rectangular del hámster (alineada con su posición visual).
  late final RectangleHitbox hitbox;

  /// Realidad en la que se encuentra el hámster (A o B).
  Reality currentReality = Reality.realityA;

  double _time = 0.0;
  Vector2 _startPosition = Vector2.zero();

  @override
  Future<void> onLoad() async {
    width = size;
    height = size;
    position = initialPosition.clone();
    _startPosition = initialPosition.clone();

    // Hitbox rectangular que cubre todo el cuadrado. Se mueve con el
    // componente, así que siempre queda alineada con la posición visual.
    hitbox = RectangleHitbox(
      size: Vector2(size, size),
      position: Vector2.zero(),
    );
    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Animación de "correr en el sitio": rebote vertical sobre la posición fija.
    _time += dt;
    final bounce = _bounceAmplitude * (_time * _bounceFrequency).sin();
    position.y = _startPosition.y + bounce;

    // La X se mantiene fija; el desplazamiento horizontal lo da el scroll del fondo.
    position.x = _startPosition.x;
  }

  /// Alterna entre la realidad A y la realidad B.
  void toggleReality() {
    currentReality =
        currentReality == Reality.realityA ? Reality.realityB : Reality.realityA;
  }

  /// Establece una realidad específica.
  void setReality(Reality reality) {
    currentReality = reality;
  }

  /// Reinicia el hámster a su posición inicial, detiene el ciclo de animación
  /// y lo coloca en la realidad A.
  void reset() {
    _time = 0.0;
    position = initialPosition.clone();
    _startPosition = initialPosition.clone();
    currentReality = Reality.realityA;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Cuadrado de color placeholder según la realidad activa.
    final paint = Paint()
      ..color = currentReality == Reality.realityA
          ? RealityAPalette.background
          : RealityBPalette.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
  }

  @override
  bool onKeyEvent(KeyEvent event) {
    // Cambiar de realidad al presionar Shift (izquierda o derecha).
    if ((event.logicalKey == LogicalKeyboardKey.shiftLeft ||
            event.logicalKey == LogicalKeyboardKey.shiftRight) &&
        event is KeyDownEvent) {
      toggleReality();
      return true;
    }
    return false;
  }
}
