import 'package:flutter/material.dart';
import 'dart:math';
import 'colors_v2.dart';

class StakentSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final Color gradientColor;
  final double width;
  final double height;

  const StakentSparkline({
    required this.data,
    required this.color,
    required this.gradientColor,
    this.width = double.infinity,
    this.height = 40,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(width: width, height: height);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          color: color,
          gradientColor: gradientColor,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color gradientColor;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.gradientColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxVal = data.reduce(max);
    final double minVal = data.reduce(min);
    final double range = maxVal - minVal > 0 ? maxVal - minVal : 1;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    final xStep = size.width / (data.length - 1);
    
    // Start drawing line
    path.moveTo(0, size.height - ((data[0] - minVal) / range) * size.height);
    
    for (int i = 1; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      path.lineTo(x, y);
    }
    
    // Draw the line
    canvas.drawPath(path, paint);
    
    // Draw the gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          gradientColor,
          gradientColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw current value dot at the end
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final dotStrokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
      
    final lastX = size.width;
    final lastY = size.height - ((data.last - minVal) / range) * size.height;
    
    canvas.drawCircle(Offset(lastX, lastY), 4.0, dotPaint);
    canvas.drawCircle(Offset(lastX, lastY), 4.0, dotStrokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.color != color;
  }
}
