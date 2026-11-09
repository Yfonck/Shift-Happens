import 'package:flutter/material.dart';

/// Enum que representa las dos realidades superpuestas del juego.
///
/// - [realityA]: realidad cálida.
/// - [realityB]: realidad fría.
enum Reality {
  realityA,
  realityB,
}

/// Constantes generales de gameplay (velocidades, gravedad, pantalla, spawn).
class GameConstants {
  GameConstants._();

  /// Tamaño de pantalla lógica del juego (en píxeles lógicos).
  static const Size logicalScreenSize = Size(800, 600);

  /// Velocidad de movimiento horizontal del hámster (píxeles por segundo).
  static const double hamsterSpeed = 300.0;

  /// Velocidad de desplazamiento del mundo / obstáculos (píxeles por segundo).
  static const double worldScrollSpeed = 200.0;

  /// Fuerza de impulso si el hámster salta (píxeles por segundo, negativa = hacia arriba).
  static const double jumpForce = -650.0;

  /// Gravedad aplicada al hámster (píxeles por segundo al cuadrado).
  static const double gravity = 1800.0;

  /// Intervalo base entre la aparición de obstáculos (en segundos).
  static const double obstacleSpawnInterval = 1.5;

  /// Intervalo mínimo de spawn (para aumentar dificultad progresivamente).
  static const double minSpawnInterval = 0.8;

  /// Intervalo máximo de spawn.
  static const double maxSpawnInterval = 2.5;

/// Tasa de reducción del intervalo de spawn por segundo (cuanto más tiempo pasa, más cercano es el spawn).
static const double spawnIntervalDecreaseRate = 0.03;

/// Probabilidad de generar un par de obstáculos (uno de cada realidad) en un solo spawn.
static const double spawnPairChance = 0.2;

/// Tasa de aumento de la velocidad de scroll por segundo (píxeles por segundo²).
static const double scrollSpeedIncreaseRate = 30.0;

/// Paleta de colores asociada a una realidad.
}

/// Paleta de colores asociada a una realidad.
class RealityPalette {
  final Color background;
  final Color ground;
  final Color obstacle;

  const RealityPalette({
    required this.background,
    required this.ground,
    required this.obstacle,
  });
}

/// Colores de la realidad A (cálida).
class RealityAPalette {
  static const Color background = Color(0xFFFDEBD0); // crema cálido
  static const Color ground = Color(0xFFE8A87C); // terracota
  static const Color obstacle = Color(0xFFC0392B); // rojo ladrillo
}

/// Colores de la realidad B (fría).
class RealityBPalette {
  static const Color background = Color(0xFFD6EAF8); // azul hielo
  static const Color ground = Color(0xFF5DADE2); // azul cielo
  static const Color obstacle = Color(0xFF2874A6); // azul océano
}

/// Mapa para obtener la paleta de colores según la realidad activa.
const Map<Reality, RealityPalette> realityPalettes = {
  Reality.realityA: RealityPalette(
    background: RealityAPalette.background,
    ground: RealityAPalette.ground,
    obstacle: RealityAPalette.obstacle,
  ),
  Reality.realityB: RealityPalette(
    background: RealityBPalette.background,
    ground: RealityBPalette.ground,
    obstacle: RealityBPalette.obstacle,
  ),
};
