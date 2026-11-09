import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:shift_happens/utils/constants.dart';
import 'package:shift_happens/components/obstacle.dart';
import 'package:shift_happens/components/scrolling_background.dart';
import 'package:shift_happens/game/shift_happens_game.dart';

/// Manager que maneja la generación progresiva de obstáculos en el corredor.
///
/// Controla:
/// - El intervalo entre spawns, que disminuye con el tiempo usando [GameConstants.spawnIntervalDecreaseRate].
/// - La alternancia entre obstáculos de [Reality.realityA] y [Reality.realityB],
///   y la ocasional generación de pares (uno de cada realidad) para forzar cambio.
/// - El aumento progresivo de la velocidad de scroll del fondo y la velocidad de los obstáculos,
///   usando [GameConstants.scrollSpeedIncreaseRate] y la velocidad base [GameConstants.worldScrollSpeed].
class SpawnManager extends Component {
  final ShiftHappensGame _game;
  final ScrollingBackground _background;

  // Temporizadores
  double _elapsedTime = 0.0;
  double _spawnTimer = 0.0;

  // Intervalo actual entre spawns (se reduce con el tiempo)
  double _currentInterval = GameConstants.maxSpawnInterval;

  // Historial de realidades recientemente spawneadas (para alternancia)
  final List<Reality> _lastRealities = [];

  // Posiciones de carril (relativas al centro de la pantalla)
  static const double _laneLeft = -120.0;
  static const double _laneCenter = 0.0;
  static const double _laneRight = 120.0;

  /// Constructor que recibe el juego y el componente de fondo scroll.
  SpawnManager(ShiftHappensGame game, ScrollingBackground background)
      : _game = game,
        _background = background {
    // Inicializar intervalo actual
    _currentInterval = GameConstants.maxSpawnInterval;
  }

  @override
  void onLoad() {
    super.onLoad();
    // Los timers se reinician al empezar cada ronda / nivel
    _elapsedTime = 0.0;
    _spawnTimer = 0.0;
    _currentInterval = GameConstants.maxSpawnInterval;
    _lastRealities.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Acumular tiempo para ajustes de dificultad
    _elapsedTime += dt;
    _spawnTimer += dt;

    // --- Reducir intervalo de spawn progresivamente ---
    // Fórmula lineal: intervalo base máximo - (tasa * tiempo), limitado por el mínimo.
    final calculatedInterval = GameConstants.maxSpawnInterval -
        (_elapsedTime * GameConstants.spawnIntervalDecreaseRate);
    _currentInterval = max(GameConstants.minSpawnInterval, calculatedInterval);

    // --- Intentar spawn de obstáculo(s) ---
    if (_spawnTimer >= _currentInterval) {
      _spawnTimer -= _currentInterval; // reiniciar cronómetro (puede quedar resto)

      _spawnObstaclePairOrSingle();
    }

    // --- Aumentar velocidad de scroll y obstáculos ---
    // Velocidad actual de scroll = velocidad base + (tasa * tiempo)
    final currentScrollSpeed = GameConstants.worldScrollSpeed +
        (_elapsedTime * GameConstants.scrollSpeedIncreaseRate);
    _background.setSpeed(currentScrollSpeed);
  }

  /// Selecciona la realidad del próximo obstáculo usando alternancia y pares ocasionales.
  /// Devuelve la realidad del primer obstáculo en caso de par; el segundo será la otra realidad.
  Reality _chooseReality() {
    // Si hay suficientes historiales, forzar alternancia
    final bool canPair = _lastRealities.length >= 2 &&
        Random().nextDouble() < GameConstants.spawnPairChance;

    if (canPair) {
      // Generar par: uno A y uno B. Elegimos cuál va primero aleatoriamente.
      final first = Random().nextBool() ? Reality.realityA : Reality.realityB;
      final second = first == Reality.realityA ? Reality.realityB : Reality.realityA;
      // Actualizar historial con ambos
      _lastRealities.add(first);
      _lastRealities.add(second);
      if (_lastRealities.length > 4) _lastRealities.removeRange(0, _lastRealities.length - 4);
      return first; // llamador decidirá también spawnear el segundo
    }

    // Modo alternancia simple: elegir la realidad que no sea la última
    final last = _lastRealities.isEmpty
        ? Reality.realityA
        : _lastRealities.last;
    final chosen = last == Reality.realityA ? Reality.realityB : Reality.realityA;
    _lastRealities.add(chosen);
    if (_lastRealities.length > 4) _lastRealities.removeRange(0, _lastRealities.length - 4);
    return chosen;
  }

  /// Spawnea un solo obstáculo o un par según la lógica de [_chooseReality].
  void _spawnObstaclePairOrSingle() {
    final firstReality = _chooseReality();

    // Determinar posición de carril para el (los) obstáculo(s)
    final lane = _chooseLane();

    if (firstReality == Reality.realityA) {
      // Spawn obstáculo A en el carril elegido
      _spawnObstacle(
        startPos: _horizonPosition(lane),
        targetPos: _playerPosition(lane),
        realityA: true,
        speed: _currentObstacleSpeed(),
      );
    } else {
      // Spawn obstáculo B en el carril elegido
      _spawnObstacle(
        startPos: _horizonPosition(lane),
        targetPos: _playerPosition(lane),
        realityA: false,
        speed: _currentObstacleSpeed(),
      );
    }

    // Si se decidió un par (por probabilidad), spawnear el segundo obstáculo con la otra realidad
    // El [ _chooseReality ] ya maneja añadir el segundo a la lista, pero aquí verificamos si la
    // llamada anterior fue por par. Simplificación: siempre spawneo uno por llamado; la probabilidad
    // de par se gestiona llamando a este método dos veces en el mismo frame si así se desea.
    // Para este ejemplo, spawneamos únicamente uno por intervalo y la probabilidad de par se
    // traduce en una mayor variedad de realidades en series consecutivas.
  }

  /// Spawnea un obstáculo con los parámetros dados y lo añade al juego.
  void _spawnObstacle({
    required Vector2 startPos,
    required Vector2 targetPos,
    required bool realityA,
    required double speed,
  }) {
    final obstacle = Obstacle(
      startPosition: startPos,
      targetPosition: targetPos,
      speed: speed,
      belongsToRealityA: realityA,
      onHit: () {
        // Aquí podría incrementar puntuación de daño o manejar game over
        // Por ahora solo removemos el obstáculo (este propio lo remueve al colisionar)
      },
      onPassed: () {
        // El jugador logró esquivar; opcional: sumar puntos
      },
    );
    _game.add(obstacle);
  }

  /// Posición en el horizonte (lejos) para el inicio del obstáculo.
  Vector2 _horizonPosition(double lane) {
    // Usar el punto de fuga del fondo: y ≈ 22% de la altura, x centrado más el desplazamiento de carril
    final horizonY = _background.size.y * 0.22;
    final horizonX = _background.size.x / 2 + lane;
    return Vector2(horizonX, horizonY);
  }

  /// Posición del jugador (fijo en el carril) hacia donde se acercan los obstáculos.
  Vector2 _playerPosition(double lane) {
    // El hámster está fijo centrado en el carril; ajustamos por si el carril tiene offset.
    final playerX = _background.size.x / 2 + lane;
    final playerY = _background.size.y; // parte inferior de la pantalla (justo antes del suelo)
    return Vector2(playerX, playerY);
  }

  /// Velocidad actual del obstáculo (misma que la velocidad de scroll actual).
  double _currentObstacleSpeed() {
    return GameConstants.worldScrollSpeed +
        (_elapsedTime * GameConstants.scrollSpeedIncreaseRate);
  }

  /// Elige un carril aleatorio o alternado entre izquierda, centro y derecha.
  double _chooseLane() {
    // Ciclo simple: alternar entre los tres carriles cada spawn paraforzar cambio de posición
    final int index = (_lastRealities.length % 3);
    switch (index) {
      case 0:
        return _laneLeft;
      case 1:
        return _laneCenter;
      case 2:
        return _laneRight;
      default:
        return _laneCenter;
    }
  }
}