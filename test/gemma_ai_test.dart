import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_use_app/controllers/life_os_provider.dart';
import 'package:personal_use_app/services/gemma_ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
  });

  test('Gemma AI Service answers "Please tell me the world" and handles comprehensive offline queries', () async {
    final aiService = GemmaAiService.instance;
    aiService.engineMode = GemmaEngineMode.onDeviceOnly;

    final provider = LifeOsProvider();
    await provider.initialize();

    // 1. EXACT USER QUERY FROM SCREENSHOT: "Please tell me the world"
    final resWorld = await aiService.askGemma(
      prompt: 'Please tell me the world',
      provider: provider,
    );
    print('\n[USER QUERY: PLEASE TELL ME THE WORLD]:\n$resWorld');
    expect(resWorld.contains('Planet Earth & The World'), isTrue);
    expect(resWorld.contains('8.1 billion people'), isTrue);
    expect(resWorld.contains('Mount Everest'), isTrue);
    // Ensure generic productivity boilerplate is NOT returned
    expect(resWorld.contains('Focus on fundamental rules'), isFalse);

    // 2. Query: "What the time"
    final resTime = await aiService.askGemma(
      prompt: 'What the time',
      provider: provider,
    );
    print('\n[USER QUERY: WHAT THE TIME]:\n$resTime');
    expect(resTime.contains('Current Live Time & Date'), isTrue);

    // 3. Hindi Query: "kaise ho" -> English Output
    final resHindi = await aiService.askGemma(
      prompt: 'kaise ho',
      provider: provider,
    );
    print('\n[USER QUERY: KAISE HO (ENGLISH OUTPUT)]:\n$resHindi');
    expect(resHindi.contains('peak efficiency'), isTrue);

    // 4. Universe Query
    final resUniverse = await aiService.askGemma(
      prompt: 'tell me about universe',
      provider: provider,
    );
    print('\n[USER QUERY: UNIVERSE]:\n$resUniverse');
    expect(resUniverse.contains('The Universe & The Cosmos'), isTrue);

    // 5. Computer Query
    final resComputer = await aiService.askGemma(
      prompt: 'how does computer work',
      provider: provider,
    );
    print('\n[USER QUERY: COMPUTER]:\n$resComputer');
    expect(resComputer.contains('How Computers Work'), isTrue);

    // 6. Action: Expense
    final resExpense = await aiService.askGemma(
      prompt: 'monthly spend me 500 add kr do',
      provider: provider,
    );
    print('\n[USER QUERY: EXPENSE]:\n$resExpense');
    expect(resExpense.contains('Expense Successfully Added'), isTrue);

    // 7. Dynamic Synthesizer Query: Unknown topic without productivity boilerplate
    final resOpen = await aiService.askGemma(
      prompt: 'tell me about Bengal Tigers',
      provider: provider,
    );
    print('\n[USER QUERY: OPEN TOPIC]:\n$resOpen');
    expect(resOpen.contains('Bengal Tigers'), isTrue);
    expect(resOpen.contains('Focus on fundamental rules'), isFalse);
  });
}
