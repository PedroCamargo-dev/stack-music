import 'package:flutter/material.dart';

/// Fade + slide-in animado para itens de lista/carrossel (250ms, easeOut).
class FadeSlideIn extends StatefulWidget {
 final Widget child;
 final int index; // atraso escalonado

 const FadeSlideIn({super.key, required this.child, this.index = 0});

 @override
 State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
 with SingleTickerProviderStateMixin {
 late final AnimationController _controller = AnimationController(
 vsync: this, duration: const Duration(milliseconds: 250));

 @override
 void initState() {
 super.initState();
 Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 10)),
 () => mounted ? _controller.forward() : null);
 }

 @override
 void dispose() {
 _controller.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 return FadeTransition(
 opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
 child: SlideTransition(
 position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
 .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
 child: widget.child,
 ),
 );
 }
}