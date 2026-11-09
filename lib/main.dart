import 'package:flutter/material.dart';
import 'package:shift_happens/game/shift_happens_game.dart';

void main() {
  runApp(const ShiftHappensApp());
}

class ShiftHappensApp extends StatelessWidget {
  const ShiftHappensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shift Happens',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: ShiftHappensGame(),
          autofocus: true,
        ),
      ),
    );
  }
}
