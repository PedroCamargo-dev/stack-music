import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// Testa a lógica pura do Sleep Timer sem dependência de just_audio/audio_service.
/// A integração com PlayerHandler é validada manualmente ou via widget test.
void main() {
  test('timer expira após a duração definida e emite null', () async {
    final controller = StreamController<Duration?>.broadcast();
    addTearDown(controller.close);

    DateTime? target;
    Timer? timer;

    void setTimer(Duration duration) {
      timer?.cancel();
      target = DateTime.now().add(duration);
      controller.add(duration);
      timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final remaining = target?.difference(DateTime.now());
        if (remaining == null || remaining <= Duration.zero) {
          timer?.cancel();
          timer = null;
          target = null;
          controller.add(null);
        } else {
          controller.add(remaining);
        }
      });
    }

    final emissions = <Duration?>[];
    controller.stream.listen(emissions.add);

    setTimer(const Duration(milliseconds: 350));
    expect(timer, isNotNull);

    // Aguarda expiração + margem
    await Future.delayed(const Duration(milliseconds: 500));

    expect(timer, isNull);
    expect(emissions.last, isNull);
    // Deve ter emitido pelo menos: valor inicial + alguns decrementos + null final
    expect(emissions.length, greaterThanOrEqualTo(3));
  });

  test('cancelamento emite null imediatamente e interrompe o timer', () async {
    final controller = StreamController<Duration?>.broadcast();
    addTearDown(controller.close);

    DateTime? target;
    Timer? timer;

    void setTimer(Duration duration) {
      timer?.cancel();
      target = DateTime.now().add(duration);
      controller.add(duration);
      timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final remaining = target?.difference(DateTime.now());
        if (remaining == null || remaining <= Duration.zero) {
          timer?.cancel();
          timer = null;
          target = null;
          controller.add(null);
        } else {
          controller.add(remaining);
        }
      });
    }

    void cancelTimer() {
      timer?.cancel();
      timer = null;
      target = null;
      controller.add(null);
    }

    final emissions = <Duration?>[];
    controller.stream.listen(emissions.add);

    setTimer(const Duration(seconds: 5));
    expect(timer, isNotNull);

    // Cancela rapidamente
    await Future.delayed(const Duration(milliseconds: 150));
    cancelTimer();

    expect(timer, isNull);
    // Aguarda microtask para o stream entregar o evento null
    await Future.delayed(Duration.zero);
    expect(emissions.last, isNull);

    // Aguarda além do tempo original — nenhuma nova emissão deve ocorrer
    final countAfterCancel = emissions.length;
    await Future.delayed(const Duration(milliseconds: 300));
    expect(emissions.length, countAfterCancel);
  });

  test('valores emitidos são decrescentes até expiração', () async {
    final controller = StreamController<Duration?>.broadcast();
    addTearDown(controller.close);

    DateTime? target;
    Timer? timer;

    void setTimer(Duration duration) {
      timer?.cancel();
      target = DateTime.now().add(duration);
      controller.add(duration);
      timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final remaining = target?.difference(DateTime.now());
        if (remaining == null || remaining <= Duration.zero) {
          timer?.cancel();
          timer = null;
          target = null;
          controller.add(null);
        } else {
          controller.add(remaining);
        }
      });
    }

    final emissions = <Duration?>[];
    controller.stream.listen(emissions.add);

    setTimer(const Duration(milliseconds: 450));
    await Future.delayed(const Duration(milliseconds: 600));

    // Filtra apenas os valores não-null (durações restantes)
    final durations = emissions.whereType<Duration>().toList();
    expect(durations.length, greaterThanOrEqualTo(2));

    // Verifica ordem decrescente
    for (var i = 1; i < durations.length; i++) {
      expect(durations[i].inMilliseconds, lessThanOrEqualTo(durations[i - 1].inMilliseconds));
    }
  });
}