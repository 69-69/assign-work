import 'dart:math';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:flutter/material.dart';

class AnimatedHexagonGrid extends StatefulWidget {
  final Widget child;

  const AnimatedHexagonGrid({super.key, required this.child});

  @override
  State<AnimatedHexagonGrid> createState() => _AnimatedHexagonGridState();
}

class _AnimatedHexagonGridState extends State<AnimatedHexagonGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // bool _hideSplashScreen = false;
  // Timer? _timer;

  @override
  void initState() {
    super.initState();
    // _startTimer();
    _controller = AnimationController(duration: kTProgressDelay, vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    // _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double hexSize = context.screenWidth / 10;
    final double spacing = hexSize * 1.5;

    List<Widget> hexagons = _buildList(spacing, hexSize);

    return Stack(children: [...hexagons, widget.child]);
  }

  List<Widget> _buildList(double spacing, double hexSize) {
    List<Widget> hexagons = [];

    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 10; col++) {
        double offsetX = (row % 2 == 0
            ? col * spacing
            : col * spacing + spacing / 2);
        double offsetY = row * (hexSize * 0.75);

        hexagons.add(
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              var radians = _controller.value * 2 * pi;

              return Transform.translate(
                offset: Offset(
                  offsetX + sin(radians) * 50,
                  offsetY + cos(radians) * 50,
                ),
                child: Hexagon(
                  size: hexSize,
                  color: (col.isEven ? kWarningColor : kOrangeColor).toAlpha(
                    (0.9),
                  ),
                ),
              );
            },
          ),
        );
      }
    }
    return hexagons;
  }
}

class Hexagon extends StatelessWidget {
  final double size;
  final Color color;

  const Hexagon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: HexagonPainter(color));
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;

  HexagonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final double width = size.width;
    final double height = size.height;
    final double radius = width / 2;
    final double dx = width / 2;
    final double dy = height / 2;

    path.moveTo(dx + radius * cos(0), dy + radius * sin(0));
    for (int i = 1; i < 6; i++) {
      path.lineTo(dx + radius * cos(i * pi / 3), dy + radius * sin(i * pi / 3));
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
