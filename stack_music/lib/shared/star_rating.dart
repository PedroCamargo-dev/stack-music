import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Widget de avaliação 1-5 estrelas com optimistic UI.
/// [rating] é o valor atual (0-5).
/// [onRate] é chamado quando o usuário seleciona uma estrela;
/// o widget atualiza imediatamente e reverte se onRate lançar exceção.
class StarRating extends StatefulWidget {
  final int rating;
  final Future<void> Function(int newRating) onRate;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const StarRating({
    super.key,
    required this.rating,
    required this.onRate,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late int _displayRating;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _displayRating = widget.rating;
  }

  @override
  void didUpdateWidget(covariant StarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_updating && oldWidget.rating != widget.rating) {
      _displayRating = widget.rating;
    }
  }

  Future<void> _handleTap(int value) async {
    if (_updating) return;
    final previous = _displayRating;
    // Optimistic update: tap na mesma estrela remove o rating (toggle)
    final newValue = _displayRating == value ? 0 : value;
    setState(() {
      _displayRating = newValue;
      _updating = true;
    });
    try {
      await widget.onRate(newValue);
    } catch (_) {
      // Rollback em caso de falha
      if (mounted) {
        setState(() {
          _displayRating = previous;
          _updating = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor ?? AppColors.primary;
    final inactive = widget.inactiveColor ?? Colors.white.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = i + 1;
        final filled = value <= _displayRating;
        return GestureDetector(
          onTap: () => _handleTap(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              filled ? Icons.star : Icons.star_border,
              size: widget.size,
              color: filled ? active : inactive,
            ),
          ),
        );
      }),
    );
  }
}