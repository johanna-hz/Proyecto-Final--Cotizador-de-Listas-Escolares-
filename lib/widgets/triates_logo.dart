import 'package:flutter/material.dart';

class TriatesLogoWidget extends StatelessWidget {
  final double size;

  const TriatesLogoWidget({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.jpg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to logo.png or vector logo if logo.jpg is not found
        return Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error2, stackTrace2) {
            // Fallback vector logo if neither image asset is present
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCharacter(const Color(0xFF00B4D8), hasCap: true),
                    const SizedBox(width: 8),
                    _buildCharacter(const Color(0xFF7209B7), hasCap: false),
                    const SizedBox(width: 8),
                    _buildCharacter(const Color(0xFFF72585), hasCap: false),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('T', style: TextStyle(fontSize: size * 0.25, fontWeight: FontWeight.bold, color: const Color(0xFF00B4D8))),
                    Text('R', style: TextStyle(fontSize: size * 0.25, fontWeight: FontWeight.bold, color: const Color(0xFFF72585))),
                    Text('i', style: TextStyle(fontSize: size * 0.25, fontWeight: FontWeight.bold, color: const Color(0xFFFFB703))),
                    Text('a', style: TextStyle(fontSize: size * 0.25, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B6B))),
                    Text('t', style: TextStyle(fontSize: size * 0.25, fontWeight: FontWeight.bold, color: const Color(0xFF7209B7))),
                    Text('e', style: TextStyle(fontSize: size * 0.25, fontWeight: FontWeight.bold, color: const Color(0xFF38B000))),
                    Text('s', style: TextStyle(fontSize: size * 0.25, fontWeight: FontWeight.bold, color: const Color(0xFF00B4D8))),
                  ],
                ),
                const Text(
                  'papelería',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCharacter(Color color, {bool hasCap = false}) {
    return SizedBox(
      width: size * 0.25,
      height: size * 0.25,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 2,
            left: 4,
            child: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          Positioned(
            top: 2,
            right: 4,
            child: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          if (hasCap)
            Positioned(
              top: 0,
              left: 10,
              child: Container(width: 10, height: 5, color: color),
            ),
          Container(
            width: size * 0.2,
            height: size * 0.2,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 2.5, height: 2.5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    SizedBox(width: size * 0.04),
                    Container(width: 2.5, height: 2.5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  width: size * 0.07,
                  height: size * 0.035,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white, width: 2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
