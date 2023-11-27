import 'package:flutter/material.dart';

class Square extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  const Square(this.size, this.backgroundColor, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
        ),
      ),
    );
  }
}
