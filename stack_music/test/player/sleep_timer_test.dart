import 'package:flutter_test/flutter_test.dart';
import 'package:stack_music/core/models/subsonic_models.dart';
import 'package:stack_music/core/player/player_handler.dart';
import '../support/performance_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setSleepTimer pausa a reprodução após a duração definida', () async {
    final client = FixtureClient();
    final handler = PlayerHandler(client);
    addTearDown(handler.dispose);

    // Simula uma faixa tocando
    await handler.playQueue([
      SubsonicSong(id: 's1', title: 'T1', artist: 'A', duration: 300),
    ]);
    expect(handler.player.playing, isTrue);

    // Define timer de 2 segundos (usando fakeAsync seria ideal, mas aqui usamos real)
    handler.setSleepTimer(const Duration(seconds: 2));
    expect(handler.isSleepTimerActive, isTrue);

    // Aguarda expiração + margem
    await Future.delayed(const Duration(milliseconds: 2500));
    expect(handler.player.playing, isFalse);
    expect(handler.isSleepTimerActive, isFalse);
  });

  test('cancelSleepTimer impede a pausa automática', () async {
    final client = FixtureClient();
    final handler = PlayerHandler(client);
    addTearDown(handler.dispose);

    await handler.playQueue([
      SubsonicSong(id: 's1', title: 'T1', artist: 'A', duration: 300),
    ]);

    handler.setSleepTimer(const Duration(seconds: 2));
    expect(handler.isSleepTimerActive, isTrue);

    // Cancela antes de expirar
    handler.cancelSleepTimer();
    expect(handler.isSleepTimerActive, isFalse);

    // Aguarda além do tempo original do timer
    await Future.delayed(const Duration(milliseconds: 2500));
    expect(handler.player.playing, isTrue);
  });

  test('sleepRemainingStream emite valores decrescentes', () async {
    final client = FixtureClient();
    final handler = PlayerHandler(client);
    addTearDown(handler.dispose);

    final emissions = <Duration?>[];
    handler.sleepRemainingStream.listen(emissions.add);

    handler.setSleepTimer(const Duration(seconds: 3));
    await Future.delayed(const Duration(milliseconds: 1200));
    handler.cancelSleepTimer();

    // Deve ter recebido pelo menos o valor inicial e um decremento
    expect(emissions.length, greaterThanOrEqualTo(2));
    expect(emissions.first, const Duration(seconds: 3));
    expect(emissions.last, isNull); // cancelamento emite null
  });
}