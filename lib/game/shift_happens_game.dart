import 'package:flame/game.dart';

/// Clase principal del juego. Hereda de [FlameGame].
///
/// Aquí se registrarán los componentes (hámster, obstáculos, fondos),
/// los managers (puntuación, guardado, realidad activa) y la lógica
/// de cambio de realidad con la tecla Shift.
class ShiftHappensGame extends FlameGame {
  ShiftHappensGame();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Aquí se cargarán los assets iniciales y se añadirán los componentes.
  }
}
