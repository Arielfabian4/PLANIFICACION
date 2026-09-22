import 'package:flutter/material.dart';
import '../theme/ciauto_theme.dart';

class CiautoLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const CiautoLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícono del logo: círculo rojo con silueta de auto
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: CiautoColors.redGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CiautoColors.red.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_car_filled,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: size * 0.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: textColor ?? CiautoColors.dark,
              ),
              children: const [
                TextSpan(text: 'CI'),
                TextSpan(
                  text: 'AUTO',
                  style: TextStyle(color: CiautoColors.red),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
