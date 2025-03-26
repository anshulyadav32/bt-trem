import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class TerminalTypingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Duration typingSpeed;
  final bool animate;
  
  const TerminalTypingText({
    Key? key, 
    required this.text,
    required this.style,
    this.typingSpeed = const Duration(milliseconds: 30),
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return Text(text, style: style);
    }
    
    return TypewriterAnimatedTextKit(
      text: [text],
      textStyle: style,
      speed: typingSpeed,
      displayFullTextOnTap: true,
      isRepeatingAnimation: false,
    );
  }
}
