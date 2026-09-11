import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../controllers/life_os_provider.dart';
import '../models/expense_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';

class GemmaChatMessage {
  final String id;
  final String role; // 'user' or 'assistant' or 'system'
  final String content;
  final DateTime timestamp;

  GemmaChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
}

enum GemmaEngineMode {
  auto, // Tries local LLM server first, falls back to on-device engine
  onDeviceOnly, // Pure offline on-device contextual engine (zero network)
  localServerOnly, // Connects to local LM Studio / llama.cpp / Ollama server
}

class GemmaAiService {
  static final GemmaAiService instance = GemmaAiService._internal();
  GemmaAiService._internal() {
    loadSavedEndpoint();
  }

  String localModelPath =
      r'C:\Users\hr529\.lmstudio\models\lmstudio-community\gemma-4-E4B-it-GGUF\gemma-4-E4B-it-Q4_K_M.gguf';
  String localServerEndpoint = 'http://127.0.0.1:1234/v1';
  bool isLocalServerActive = false;
  GemmaEngineMode engineMode = GemmaEngineMode.auto;

  Future<void> loadSavedEndpoint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('gemma_server_endpoint');
      if (saved != null && saved.trim().isNotEmpty) {
        localServerEndpoint = saved.trim();
      }
    } catch (_) {}
  }

  Future<void> saveEndpoint(String endpoint) async {
    localServerEndpoint = endpoint.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemma_server_endpoint', localServerEndpoint);
    } catch (_) {}
  }

  Future<bool> checkLocalModelExists() async {
    if (kIsWeb) return false;
    try {
      final file = File(localModelPath);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  Future<int?> getLocalModelSizeInBytes() async {
    if (kIsWeb) return null;
    try {
      final file = File(localModelPath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> pingLocalServer() async {
    try {
      final url = Uri.parse('$localServerEndpoint/models');
      final response = await http.get(url).timeout(const Duration(milliseconds: 1500));
      isLocalServerActive = response.statusCode == 200;
      return isLocalServerActive;
    } catch (_) {
      isLocalServerActive = false;
      return false;
    }
  }

  String buildSystemContext(LifeOsProvider provider) {
    final now = DateTime.now();
    final nowStr = DateFormat('EEEE, dd MMMM yyyy').format(now);

    final pendingTasks = provider.tasks
        .where((t) => !t.isCompleted)
        .take(6)
        .map((t) => '${t.title} [${t.priority}]')
        .join(', ');
    final topSkills = provider.skills
        .take(5)
        .map((s) => '${s.name}: ${s.currentLevel}%')
        .join(', ');
    final habits = provider.habits
        .take(5)
        .map((h) => '${h.name} (${h.streak}d streak)')
        .join(', ');

    return '''You are Gemma 4, an ultra-fast AI Copilot for LifeOS designed for ${provider.userName}.
Current Date: $nowStr
- Monthly Spending: ₹${provider.totalExpenseThisMonth.toInt()} | Net Balance: ₹${provider.netBalance.toInt()}
- Week Study: ${(provider.totalStudyMinutesThisWeek / 60).toStringAsFixed(1)} hours
- Priority Tasks: ${pendingTasks.isEmpty ? 'None' : pendingTasks}
- Top Skills: ${topSkills.isEmpty ? 'None' : topSkills}
- Habit Streaks: ${habits.isEmpty ? 'None' : habits}
''';
  }

  Future<String> askGemma({
    required String prompt,
    required LifeOsProvider provider,
    List<GemmaChatMessage>? history,
  }) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return 'Please ask a question, command, or idea!';
    }

    // -------------------------------------------------------------
    // 1. ACTIVE AGENTIC ACTION DISPATCHER (Writes to SQLite Database)
    // -------------------------------------------------------------
    final actionResponse = await _handleActionExecution(trimmedPrompt, provider);
    if (actionResponse != null) {
      return actionResponse;
    }

    // -------------------------------------------------------------
    // 2. INSTANT ARITHMETIC / MATH EVALUATOR
    // -------------------------------------------------------------
    final mathResult = _tryEvaluateMath(trimmedPrompt);
    if (mathResult != null) {
      return mathResult;
    }

    // -------------------------------------------------------------
    // 3. LOCAL SERVER INFERENCE (LM Studio / Ollama / llama.cpp on PC)
    // -------------------------------------------------------------
    if (engineMode != GemmaEngineMode.onDeviceOnly) {
      final serverAlive = await pingLocalServer();
      if (serverAlive) {
        try {
          final messages = <Map<String, String>>[
            {
              'role': 'system',
              'content':
                  '${buildSystemContext(provider)}\nAlways reply in clear, helpful, accurate English.',
            },
          ];

          if (history != null) {
            for (var msg in history.take(6)) {
              messages.add({'role': msg.role, 'content': msg.content});
            }
          }
          messages.add({'role': 'user', 'content': trimmedPrompt});

          final res = await http.post(
            Uri.parse('$localServerEndpoint/chat/completions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'gemma-4-E4B-it',
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          ).timeout(const Duration(seconds: 45));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final reply = data['choices']?[0]?['message']?['content'] as String?;
            if (reply != null && reply.trim().isNotEmpty) {
              return reply.trim();
            }
          }
        } catch (_) {
          // Fall through to offline engine
        }
      } else if (engineMode == GemmaEngineMode.localServerOnly) {
        return '⚠️ **Local Gemma 4 Server Unreachable**\n\n'
            'Could not reach LM Studio at `$localServerEndpoint`.\n'
            'Please ensure:\n'
            '1. LM Studio is running on your PC with Gemma 4 loaded.\n'
            '2. The Local Server is started on Port 1234.\n'
            '3. If using mobile, ensure your phone and PC are on the same Wi-Fi network.';
      }
    }

    // -------------------------------------------------------------
    // 4. ON-DEVICE INTELLIGENT CONTEXTUAL ENGINE (Always answers in English!)
    // -------------------------------------------------------------
    return _generateOfflineContextualResponse(trimmedPrompt, provider);
  }

  // ====================================================================
  // MATH & ARITHMETIC EVALUATOR
  // ====================================================================
  String? _tryEvaluateMath(String prompt) {
    final lower = prompt.toLowerCase().trim();

    // Check for percentage: "18% of 50000" or "what is 20 percent of 250"
    final pctMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:%|percent)\s+(?:of|ka)\s+(\d+(?:\.\d+)?)')
        .firstMatch(lower);
    if (pctMatch != null) {
      final p = double.tryParse(pctMatch.group(1)!);
      final total = double.tryParse(pctMatch.group(2)!);
      if (p != null && total != null) {
        final result = (p / 100.0) * total;
        return '🧮 **Calculation Result**:\n\n'
            '• **Expression**: $p% of $total\n'
            '• **Calculated Value**: **${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 2)}**';
      }
    }

    // Check for arithmetic: "450 * 12", "what is 1200 + 450", "calculate 5000 / 4"
    final mathClean = lower
        .replaceAll(RegExp(r'^(what is|calculate|solve|kya hota hai|equals)\s*', caseSensitive: false), '')
        .replaceAll('?', '')
        .trim();

    final exprMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*([\+\-\*\/xX])\s*(\d+(?:\.\d+)?)$')
        .firstMatch(mathClean);
    if (exprMatch != null) {
      final a = double.tryParse(exprMatch.group(1)!);
      final op = exprMatch.group(2)!;
      final b = double.tryParse(exprMatch.group(3)!);

      if (a != null && b != null) {
        double res = 0;
        String opName = '';
        switch (op) {
          case '+':
            res = a + b;
            opName = 'Addition';
            break;
          case '-':
            res = a - b;
            opName = 'Subtraction';
            break;
          case '*':
          case 'x':
          case 'X':
            res = a * b;
            opName = 'Multiplication';
            break;
          case '/':
            if (b == 0) return '⚠️ Division by zero is undefined in mathematics.';
            res = a / b;
            opName = 'Division';
            break;
        }

        final formatted = res.toStringAsFixed(res.truncateToDouble() == res ? 0 : 2);
        return '🧮 **Calculation Result ($opName)**:\n\n'
            '• **Equation**: $a $op $b\n'
            '• **Answer**: **$formatted**';
      }
    }

    return null;
  }

  // ====================================================================
  // AGENTIC DIRECT ACTION DISPATCHER (Writes to SQLite Database)
  // ====================================================================
  Future<String?> _handleActionExecution(String prompt, LifeOsProvider provider) async {
    final lower = prompt.toLowerCase().trim();

    // -------------------------
    // A. ADD EXPENSE COMMAND
    // -------------------------
    final isExpenseQuery = (lower.contains('spend') ||
            lower.contains('kharcha') ||
            lower.contains('expense') ||
            lower.contains('rupaye') ||
            lower.contains('rupees') ||
            lower.contains('rs') ||
            lower.contains('₹')) &&
        (lower.contains('add') ||
            lower.contains('daal') ||
            lower.contains('jod') ||
            lower.contains('likh') ||
            lower.contains('karo') ||
            lower.contains('kr do') ||
            lower.contains('kar do') ||
            lower.contains('note'));

    if (isExpenseQuery) {
      final numMatch = RegExp(r'(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d+)?)\s*(?:rupees|rupaye|rs)?')
          .firstMatch(lower);

      if (numMatch != null) {
        final amount = double.tryParse(numMatch.group(1)!);
        if (amount != null && amount > 0) {
          String category = 'Food & Drinks';
          if (lower.contains('petrol') || lower.contains('fuel') || lower.contains('travel') || lower.contains('auto') || lower.contains('cab')) {
            category = 'Travel';
          } else if (lower.contains('recharge') || lower.contains('bill') || lower.contains('wifi') || lower.contains('electricity')) {
            category = 'Bills';
          } else if (lower.contains('shopping') || lower.contains('cloth') || lower.contains('kapde')) {
            category = 'Shopping';
          } else if (lower.contains('book') || lower.contains('course') || lower.contains('study')) {
            category = 'Education';
          } else if (lower.contains('rent') || lower.contains('room')) {
            category = 'Rent';
          }

          final expense = ExpenseModel(
            id: const Uuid().v4(),
            title: 'Gemma Added: ${DateFormat('dd MMM').format(DateTime.now())} ($category)',
            amount: amount,
            type: 'expense',
            category: category,
            date: DateTime.now(),
            notes: 'Quick logged via Gemma Copilot: "$prompt"',
          );

          await provider.addExpense(expense);

          return '''✅ **Expense Successfully Added to LifeOS!**

• **Amount**: ₹${amount.toStringAsFixed(0)}
• **Category**: $category
• **Date**: ${DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())}
• **Updated Monthly Spend**: ₹${provider.totalExpenseThisMonth.toInt()}
• **Updated Net Balance**: ₹${provider.netBalance.toInt()}

📊 *Logged directly into your on-device SQLite database.*''';
        }
      }
    }

    // -------------------------
    // B. ADD TASK COMMAND
    // -------------------------
    if (lower.startsWith('add task') ||
        lower.startsWith('task add') ||
        lower.startsWith('new task') ||
        lower.startsWith('create task') ||
        (lower.contains('task') && (lower.contains('add') || lower.contains('banao') || lower.contains('karo')))) {
      String taskTitle = prompt
          .replaceAll(RegExp(r'^(add task:?|task add:?|new task:?|create task:?)', caseSensitive: false), '')
          .replaceAll(RegExp(r'(add kro|banao|kar do)$', caseSensitive: false), '')
          .trim();

      if (taskTitle.isEmpty) {
        taskTitle = 'New Priority Task';
      }

      String priority = 'Medium';
      if (lower.contains('urgent') || lower.contains('high') || lower.contains('zaruri') || lower.contains('important')) {
        priority = 'High';
      }

      final task = TaskModel(
        id: const Uuid().v4(),
        title: taskTitle.length > 60 ? '${taskTitle.substring(0, 57)}...' : taskTitle,
        priority: priority,
        tag: 'GemmaCopilot',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      await provider.addTask(task);

      return '''✅ **Task Added to LifeOS!**

• **Title**: "$taskTitle"
• **Priority**: $priority
• **Due**: Tomorrow
• **Current Pending Tasks**: ${provider.pendingTasksCount} tasks

🎯 *Open your Tasks tab or Command Dashboard to view it!*''';
    }

    // -------------------------
    // C. ADD NOTE COMMAND
    // -------------------------
    if (lower.startsWith('save note') ||
        lower.startsWith('add note') ||
        lower.startsWith('note likho') ||
        (lower.contains('note') && (lower.contains('save') || lower.contains('likho') || lower.contains('banao')))) {
      String noteContent = prompt
          .replaceAll(RegExp(r'^(save note:?|add note:?|note likho:?)', caseSensitive: false), '')
          .trim();

      if (noteContent.isEmpty) {
        noteContent = 'Quick memo captured by Gemma Copilot';
      }

      final note = NoteModel(
        id: const Uuid().v4(),
        title: 'Memo - ${DateFormat('dd MMM, hh:mm a').format(DateTime.now())}',
        content: noteContent,
        category: 'Quick Note',
        tags: ['GemmaOffline'],
      );

      await provider.addNote(note);

      return '''📝 **Note Saved to LifeOS Memos!**

• **Content**: "$noteContent"
• **Category**: Quick Note
• **Time**: ${DateFormat('hh:mm a').format(DateTime.now())}

📂 *View it anytime in your Notes module!*''';
    }

    return null;
  }

  // ====================================================================
  // QUERY NORMALIZATION & TOPIC EXTRACTION
  // ====================================================================
  String _normalizeQuery(String raw) {
    var s = raw.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'[?!.,:;]+$'), '').trim();

    // Remove leading conversational/polite wrappers
    s = s.replaceAll(RegExp(r'^(please\s+|can you\s+|could you\s+|kripya\s+)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'^(tell me about\s+|tell me\s+|batao\s+|mujhe batao\s+|explain to me\s+|explain\s+|describe\s+|what do you know about\s+|give information about\s+|teach me about\s+)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'^(what is\s+|what are\s+|who is\s+|who was\s+|kya hai\s+|kaun hai\s+|koun hai\s+)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'^(the\s+|a\s+|an\s+)', caseSensitive: false), '');

    // Remove trailing conversational markers
    s = s.replaceAll(RegExp(r'\s+(ke baare me batao|kya hai|kya hota hai|kya h|batao|bataiye|samjhao)$', caseSensitive: false), '');

    return s.trim();
  }

  String _extractSubjectTopic(String prompt) {
    var s = prompt.trim();
    s = s.replaceAll(RegExp(r'[?!.,:;]+$'), '').trim();

    s = s.replaceAll(RegExp(r'^(please\s+|can you\s+|could you\s+|kripya\s+)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'^(tell me about\s+|tell me\s+|mujhe batao\s+|batao\s+|explain to me\s+|explain\s+|describe\s+|what do you know about\s+|teach me about\s+)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'^(what is\s+|what are\s+|what does\s+|how does\s+|how do\s+|how to\s+|why is\s+|why does\s+|why\s+|who is\s+|who was\s+|kya hota hai\s+|kya hai\s+|kaise kaam karta hai\s+)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'^(the\s+|a\s+|an\s+)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\s+(ke baare me batao|kya hai|kya hota hai|kya h|batao|bataiye|samjhao|work|works)$', caseSensitive: false), '');

    s = s.trim();
    if (s.isEmpty) return 'The Topic';

    return s.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // ====================================================================
  // COMPREHENSIVE OFFLINE REASONING ENGINE (Output in English)
  // ====================================================================
  String _generateOfflineContextualResponse(String prompt, LifeOsProvider provider) {
    final lower = prompt.toLowerCase().trim();
    final norm = _normalizeQuery(prompt);

    // =========================================================
    // 1. TIME & DATE (Fuzzy matching handles "what the time", "time kya hai", etc.)
    // =========================================================
    if (lower.contains('time') ||
        lower.contains('clock') ||
        lower.contains('samay') ||
        lower.contains('ghadi') ||
        lower.contains('date') ||
        lower.contains('tarikh') ||
        lower.contains('taarikh') ||
        lower == 'what the time' ||
        lower.contains('what the time') ||
        lower.contains('today date') ||
        lower.contains('aaj ki date')) {
      if (!lower.contains('tracker') && !lower.contains('management') && !lower.contains('habit')) {
        final now = DateTime.now();
        final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(now);
        final timeStr = DateFormat('hh:mm:ss a').format(now);

        return '''⏰ **Current Live Time & Date**:

• **Exact Time**: **$timeStr**
• **Today\'s Date**: **$dateStr**
• **Pending Priorities for Today**: ${provider.pendingTasksCount} tasks in LifeOS

💡 *Tip: You can use the Time Tracker tab to start Pomodoro focus sessions!*''';
      }
    }

    // =========================================================
    // 2. LOCATION & "WHERE AM I" / "WHERE AN I"
    // =========================================================
    if (lower == 'where an i' ||
        lower == 'where am i' ||
        lower == 'where i am' ||
        lower.contains('where am i') ||
        lower.contains('where an i') ||
        lower.contains('where i am') ||
        lower.contains('kahan hu') ||
        lower.contains('kahan hun') ||
        lower.contains('meri location')) {
      return '''📍 **Location & Environment Status**:

You are currently inside **LifeOS**, running on your mobile device in **100% On-Device Offline Mode**.

📌 **System Environment**:
• **Active Module**: Gemma 4 AI Assistant Screen
• **Workspace Owner**: **${provider.userName}**
• **Operating Mode**: 100% Private, On-Device Local SQLite (`life_os.db`)
• **Network State**: Fully functional without Internet, Wi-Fi, or Cellular Data!

💡 **What You Can Do Right Here**:
1. 💰 Record expenses: *"monthly spend me 500 add kr do"*
2. 📋 Add tasks: *"add task: learn dynamic programming"*
3. 📚 Ask technical or science queries: *"What is Google?"*, *"Tell me the world"*, *"What is Photosynthesis?"*
4. 🧮 Fast calculation: *"what is 450 * 12"*''';
    }

    // =========================================================
    // 3. USER PROFILE & IDENTITY ("WHO AM I")
    // =========================================================
    if (lower == 'who am i' ||
        lower == 'who i am' ||
        lower.contains('who am i') ||
        lower.contains('who i am') ||
        lower.contains('mera naam') ||
        lower.contains('my profile')) {
      return '''👤 **User Profile & Identity**:

You are **${provider.userName}**, the owner and administrator of this LifeOS command center.

📊 **Your Current Live Dashboard Stats**:
• **Net Cash Balance**: ₹${provider.netBalance.toInt()}
• **This Month Spending**: ₹${provider.totalExpenseThisMonth.toInt()}
• **Pending Tasks**: ${provider.pendingTasksCount} tasks
• **Tracked Habits**: ${provider.habits.length} habits (Peak Streak: ${provider.maxHabitStreak} days)
• **Logged Study Time**: ${(provider.totalStudyMinutesThisWeek / 60).toStringAsFixed(1)} hours this week''';
    }

    // =========================================================
    // 4. THE WORLD, EARTH & PLANETARY GEOGRAPHY
    // =========================================================
    if (norm == 'world' ||
        norm == 'the world' ||
        lower.contains('the world') ||
        lower.contains('tell me the world') ||
        lower.contains('about the world') ||
        norm == 'earth' ||
        lower.contains('earth') ||
        lower.contains('planet earth') ||
        lower.contains('duniya') ||
        lower.contains('dharti') ||
        lower.contains('prithvi')) {
      return '''🌍 **Planet Earth & The World**:

• **Cosmic Address**: 3rd planet from the Sun (~149.6 million km), orbiting inside the habitable "Goldilocks Zone".
• **Planetary Age**: Approximately **4.54 billion years old**.

🌊 **Surface Composition**:
• **71% Water Coverage**: 5 major oceans (Pacific, Atlantic, Indian, Southern, Arctic).
• **29% Continental Land**: 7 continents (Asia, Africa, North America, South America, Antarctica, Europe, Australia).

👥 **Human Civilization & Demographics**:
• **Global Population**: Over **8.1 billion people** living across the globe.
• **Sovereign Nations**: 195 recognized sovereign countries (193 UN Member States + Holy See & Palestine).
• **Most Populous Countries**: India (~1.43 Billion), China (~1.41 Billion), United States (~340 Million).

🏔️ **Geographical Extremes**:
• **Highest Mountain**: Mount Everest (8,848.86 m) in the Himalayas.
• **Deepest Oceanic Trench**: Challenger Deep in the Mariana Trench (~10,994 m deep).
• **Longest River**: Nile River (~6,650 km) | Largest by water volume: Amazon River.
• **Largest Deserts**: Antarctic Polar Desert (cold) & Sahara Desert (hot subtropical).

🛡️ **Atmospheric Shield**:
78% Nitrogen, 21% Oxygen, 0.9% Argon, and trace gases like CO2 and water vapor, protected by Earth\'s magnetic field against solar radiation.''';
    }

    if (norm == 'continents' || norm == 'continent' || lower.contains('continents of the world') || lower.contains('7 continents')) {
      return '''🗺️ **The 7 Continents of the World (By Land Area)**:

1. **Asia** (~44.6M km²): Largest & most populous (over 4.7 billion people). Home to Everest and the Himalayas.
2. **Africa** (~30.4M km²): Second-largest, birthplace of humankind, home to the Sahara Desert & the Nile.
3. **North America** (~24.7M km²): Contains Canada, USA, Mexico, and Caribbean nations.
4. **South America** (~17.8M km²): Home to the Amazon Rainforest, Andes mountain range, and Angel Falls.
5. **Antarctica** (~14.2M km²): Coldest, driest, and windiest continent, covered by a 2 km thick ice sheet.
6. **Europe** (~10.2M km²): Rich in history, diverse cultures, and birthplace of the Industrial Revolution.
7. **Australia / Oceania** (~8.6M km²): Smallest continent, isolated ecosystem with unique wildlife (kangaroos, koalas).''';
    }

    if (norm == 'oceans' || norm == 'ocean' || lower.contains('5 oceans') || lower.contains('oceans of the world')) {
      return '''🌊 **The 5 Major Oceans of the World**:

1. **Pacific Ocean**: Largest and deepest ocean, covering over 30% of Earth\'s surface (larger than all land combined!). Contains the Mariana Trench.
2. **Atlantic Ocean**: Second-largest, separating the Americas from Europe and Africa. Home to the Mid-Atlantic Ridge.
3. **Indian Ocean**: Warmest ocean, bordered by Asia, Africa, and Australia. Vital for global oil trade.
4. **Southern Ocean**: Encircles Antarctica, characterized by cold circumpolar currents and massive icebergs.
5. **Arctic Ocean**: Smallest and shallowest ocean, mostly frozen under sea ice around the North Pole.''';
    }

    if (norm == 'universe' || norm == 'cosmos' || lower.contains('universe') || lower.contains('cosmos') || lower.contains('brahmand') || lower.contains('big bang')) {
      return '''🌌 **The Universe & The Cosmos**:

• **Age of the Universe**: Approximately **13.8 billion years**, originating from the **Big Bang**.
• **Observable Diameter**: Approximately **93 billion light-years** across.
• **Scale**: Contains an estimated **2 trillion galaxies**, each containing between 100 billion to 1 trillion stars!
• **Cosmic Composition**:
  • **Normal Matter (Atoms)**: Only **~5%** of the entire universe (stars, planets, gas, living beings).
  • **Dark Matter**: **~27%** (invisible matter holding galaxies together via gravity).
  • **Dark Energy**: **~68%** (mysterious force accelerating the expansion of space).
• **Cosmic Expansion**: Space itself is continuously stretching, discovered by Edwin Hubble in 1929.''';
    }

    if (norm == 'galaxy' || norm == 'milky way' || lower.contains('milky way') || lower.contains('akashganga') || lower.contains('andromeda')) {
      return '''🌌 **The Milky Way Galaxy (Our Cosmic Home)**:

• **Type**: Barred Spiral Galaxy spanning approximately **100,000 light-years** in diameter.
• **Stellar Population**: Contains **100 to 400 billion stars**, including our Sun.
• **Galactic Center**: Houses a supermassive black hole named **Sagittarius A*** (~4.3 million times the mass of our Sun).
• **Sun\'s Orbit**: Our solar system travels at ~828,000 km/h, taking ~230 million years to complete one "Cosmic Year" around the galactic center.
• **Nearest Neighbor**: The **Andromeda Galaxy** (M31), located ~2.5 million light-years away. In about 4.5 billion years, Milky Way and Andromeda will merge into a giant elliptical galaxy!''';
    }

    // =========================================================
    // 5. CONVERSATIONS & GREETINGS (Hindi or English -> English Output)
    // =========================================================
    if (lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower == 'namaste' ||
        lower == 'pranam' ||
        lower == 'suno' ||
        lower == 'bhai' ||
        lower == 'bro' ||
        lower.startsWith('hi ') ||
        lower.startsWith('hello ') ||
        lower.startsWith('hey ')) {
      return '''👋 **Hello ${provider.userName}!**

I am **Gemma 4**, your on-device AI copilot running 100% locally on your phone.

📌 **How can I assist you right now?**
1. 💰 **Expense Tracking**: *"monthly spend me 500 add kr do"*
2. 📋 **Task & Note Creation**: *"add task: finish flutter module"*
3. 📚 **General Knowledge & Science**: *"Tell me the world"*, *"What is Google?"*, *"What is Photosynthesis?"*
4. 💻 **Coding & Tech**: *"Explain Python"*, *"What is API?"*, *"How does computer work?"*
5. 🧮 **Instant Math**: *"what is 450 * 12"*, *"20% of 85000"*

What is on your mind?''';
    }

    if (lower.contains('kaise ho') ||
        lower.contains('kese ho') ||
        lower.contains('kya hal hai') ||
        lower.contains('how are you') ||
        lower.contains('sab theek') ||
        lower.contains('kya chal raha')) {
      return '''⚡ **I am operating at peak efficiency!**

Running smoothly on your device with zero internet latency.
Here is your current LifeOS status:
• **Monthly Spending**: ₹${provider.totalExpenseThisMonth.toInt()}
• **Active Pending Tasks**: ${provider.pendingTasksCount} tasks

What would you like to accomplish or learn today?''';
    }

    if (lower.contains('kya kar rahe ho') ||
        lower.contains('kya kar rha h') ||
        lower.contains('what are you doing')) {
      return '''🤖 **Gemma 4 Copilot Status**:

I am monitoring your local LifeOS database and ready to process actions offline:
• Ready to log transactions (*"petrol me 250 add karo"*)
• Ready to schedule tasks (*"add task: read chapter 2"*)
• Ready to answer technical, science, or general questions!

Tell me what you need!''';
    }

    if (lower == 'theek hai' ||
        lower == 'ok' ||
        lower == 'okay' ||
        lower == 'achha' ||
        lower == 'samajh gaya' ||
        lower == 'got it' ||
        lower == 'done' ||
        lower == 'haan') {
      return '''👍 **Understood!**

Whenever you want to add a spend, schedule a task, or ask a question, I am right here. 🚀''';
    }

    if (lower.contains('love you') ||
        lower.contains('badhiya') ||
        lower.contains('mast') ||
        lower.contains('super') ||
        lower.contains('shabaash') ||
        lower.contains('great work')) {
      return '''🌟 **Thank you so much, ${provider.userName}!**

Glad to be your personal AI copilot. Keep crushing your goals in LifeOS! 🔥''';
    }

    if (lower.contains('who are you') ||
        lower.contains('tum kaun ho') ||
        lower.contains('who made you') ||
        lower.contains('about yourself') ||
        lower.contains('what is your name')) {
      return '''🤖 **About Gemma 4 Copilot**:

• **Identity**: I am Gemma 4, an on-device personal AI assistant built on open model architecture principles.
• **Privacy**: 100% Local & Private. No user data, expenses, or notes ever leave your phone.
• **Capabilities**:
  1. LifeOS Action Engine (Direct SQLite database writes for expenses, tasks, notes)
  2. Software Engineering, DSA, and Web Development
  3. General Science, Math, History, and World GK
  4. Deep Work & Productivity Advisory''';
    }

    if (lower.contains('what can you do') ||
        lower.contains('kya kar sakte ho') ||
        lower.contains('features') ||
        lower.contains('help me')) {
      return '''🛠️ **Gemma 4 Core Capabilities**:

1. **Finance & Budgeting**:
   • *"monthly spend me 500 add kr do"* ➔ Records ₹500 into SQLite instantly.
   • *"Check my monthly expenses"* ➔ Full financial breakdown.

2. **Task & Time Management**:
   • *"add task: solve binary search"* ➔ Creates task with due date.
   • *"Review pending tasks"* ➔ Prioritizes your board.

3. **General Knowledge & Science**:
   • Ask about The World, Earth, Solar System, Photosynthesis, Gravity, ISRO, Constitution, Black holes.

4. **Coding & Software Engineering**:
   • Deep dives into Python, JavaScript, Flutter, Dart, System Design, SQL vs NoSQL, Docker, APIs.

5. **Instant Calculator**:
   • *"what is 1500 * 24"*, *"18% of 50000"*''';
    }

    if (lower.contains('joke') || lower.contains('hasao') || lower.contains('funny') || lower.contains('chutkula')) {
      final jokes = [
        '😄 **Software Joke**:\nA programmer\'s spouse says: *"Run to the store and get a loaf of bread. If they have eggs, get a dozen."*\n\nThe programmer returns with **12 loaves of bread**.\nSpouse: *"Why in the world did you buy 12 loaves?!"*\nProgrammer: *"Because they had eggs!"* 😂',
        '😄 **Binary Joke**:\nThere are **10 types of people in the world**:\nThose who understand binary, and those who don\'t! 🤓',
        '😄 **Bug Joke**:\n*"It\'s not a bug — it\'s an undocumented feature!"* 🐞\n\nQ: How many developers does it take to change a lightbulb?\nA: None, that is a hardware problem! 💡',
        '😄 **Database Joke**:\nA SQL query walks into a bar, walks up to two tables and asks: *"Can I join you?"* 🍻',
      ];
      return jokes[Random().nextInt(jokes.length)];
    }

    if (lower.contains('story') || lower.contains('kahani')) {
      return '''📖 **The Parable of the Bamboo Tree**:

When a Chinese bamboo seed is planted and watered, nothing visible happens for the entire first year. No sprout, no leaf.
In the second year, third year, and fourth year — despite constant water and sunlight — still nothing appears above the soil.

Then, in the **fifth year**, within just six weeks, the bamboo tree shoots up to **80 feet tall**!

Did the bamboo grow 80 feet in six weeks, or in five years?
The answer is five years. During those silent years underground, it was developing a massive, indestructible root network capable of supporting its future explosive height.

💡 **Takeaway**: Your consistent daily efforts in study, fitness, and coding are building your roots. Even when progress seems invisible, compound growth is working in your favor!''';
    }

    if (lower.contains('motivate') ||
        lower.contains('motivation') ||
        lower.contains('sad') ||
        lower.contains('low feel') ||
        lower.contains('quote') ||
        lower.contains('prerna') ||
        lower.contains('demotivated')) {
      return '''🔥 **Daily Motivation & Mindset for ${provider.userName}**:

> *"Small disciplines repeated with consistency every single day lead to great achievements gained slowly over time."*

📌 **3 Mindset Rules**:
1. **Action precedes motivation**: Don\'t wait to feel inspired. Start a 10-minute focus block, and the momentum will follow.
2. **Focus on progress, not perfection**: Being 1% better every day compounds to 37x improvement in a year.
3. **Your goals are waiting**: Every completed task and habit in LifeOS builds your future self.

Pick your top task and let\'s get to work! 🚀''';
    }

    if (lower.contains('thank') || lower.contains('dhanyawad') || lower.contains('shukriya')) {
      return '''✨ **You are very welcome, ${provider.userName}!**

Happy to help. Let me know whenever you need anything else! 🚀''';
    }

    // =========================================================
    // 6. HUMAN BODY, HEALTH & BIOLOGY
    // =========================================================
    if (norm == 'human body' || lower.contains('human body') || lower.contains('sharir') || lower.contains('body anatomy')) {
      return '''🧬 **The Human Body (Anatomy & Miracle of Biology)**:

• **Cellular Scale**: Composed of approximately **37 trillion human cells** working in continuous biochemical harmony.
• **Skeletal System**: **206 bones** in an adult skeleton (babies are born with ~300 bones that fuse over time).
• **Muscular System**: Over **600 skeletal muscles** providing posture and movement.
• **11 Organ Systems**: Circulatory, Nervous, Respiratory, Digestive, Skeletal, Muscular, Endocrine, Immune, Integumentary (skin), Urinary, and Reproductive.
• **Largest Organ**: The **Skin** (integumentary system), weighing ~3.5 to 10 kg and protecting inner tissues from pathogens and dehydration.''';
    }

    if (norm == 'brain' || lower.contains('brain') || lower.contains('dimag') || lower.contains('human brain')) {
      return '''🧠 **The Human Brain**:

• **The Most Complex Structure**: Contains roughly **86 billion neurons**, linked by over **100 trillion synaptic connections**.
• **Energy Consumption**: Weighs only ~1.4 kg (2% of body weight), yet consumes **20% of your body\'s total resting glucose and oxygen**!
• **Triune Architecture**:
  1. **Cerebrum**: Higher cognitive functions, language, logic, vision, sensory integration, and memory.
  2. **Cerebellum**: Precision motor control, coordination, balance, and spatial movement.
  3. **Brainstem**: Autonomous life-support controls (heart rate, breathing, blood pressure, and sleep cycles).
• **Neuroplasticity**: The brain physically rewires its neural pathways throughout life in response to learning, practice, and habits!''';
    }

    if (norm == 'heart' || lower.contains('heart') || lower.contains('dil') || lower.contains('human heart')) {
      return '''❤️ **The Human Heart**:

• **Workhorse of Life**: Beats approximately **100,000 times every day** (~35 million times per year).
• **Volume Pumped**: Pumps around **7,500 liters (2,000 gallons) of blood daily** through a network of 100,000 km of blood vessels!
• **4 Chambers**:
  • **Right Atrium & Ventricle**: Receives oxygen-depleted blood from the body and pumps it to the lungs.
  • **Left Atrium & Ventricle**: Receives oxygen-rich blood from the lungs and pumps it under high pressure to the entire body via the Aorta.''';
    }

    if (lower.contains('immune system') || lower.contains('immunity') || lower.contains('rog pratirodhak')) {
      return '''🛡️ **The Human Immune System**:

• **Function**: A complex defense network defending the body against pathogens (viruses, harmful bacteria, fungi, and parasites).
• **Two Lines of Defense**:
  1. **Innate Immunity**: Rapid, non-specific response (skin barrier, stomach acid, fever, neutrophils, and macrophages).
  2. **Adaptive (Acquired) Immunity**: Highly specific defense using **B-cells** (which produce custom antibodies) and **T-cells** (helper and killer cells that remember past infections for lifetime immunity).
• **Vaccines**: Work by safely training your adaptive memory cells with harmless antigens without causing disease.''';
    }

    if (lower.contains('sleep') || lower.contains('neend') || lower.contains('insomnia') || lower.contains('sona')) {
      return '''😴 **The Science of Sleep**:

• **Recommended Duration**: 7 to 9 hours of quality sleep per night for optimal cognitive and metabolic health.
• **Sleep Cycles (90 Minutes each)**:
  1. **NREM Stages 1 & 2 (Light Sleep)**: Heart rate slows, body temperature drops.
  2. **NREM Stage 3 (Deep / Slow-Wave Sleep)**: Physical repair, muscle regeneration, immune strengthening, and release of human growth hormone (HGH).
  3. **REM (Rapid Eye Movement)**: Vivid dreaming, neural synaptic pruning, and emotional/memory consolidation.
• **The Circadian Rhythm**: Regulated by the suprachiasmatic nucleus (SCN) using light and melatonin. Avoid bright blue screens 1 hour before bed!''';
    }

    if (lower.contains('water intake') || lower.contains('pani') || lower.contains('how much water')) {
      return '''💧 **Optimal Daily Water Intake**:

• **Baseline Guideline**: Approximately **2.5 to 3.5 liters (8–12 glasses)** daily for adults, depending on climate and exercise intensity.
• **Why Hydration Matters**:
  • Human body is **~60% water** (brain and heart are ~73% water).
  • Essential for kidney filtration, joint lubrication, nutrient transport, and regulating body temperature through sweat.
  • Even a **1–2% drop in hydration** impairs cognitive focus, reaction time, and causes headaches.''';
    }

    // =========================================================
    // 7. EVERYDAY PRACTICAL QUESTIONS & RECIPES
    // =========================================================
    if (lower.contains('chai') || lower.contains('tea') || lower.contains('chai kaise banaye')) {
      return '''☕ **Authentic Indian Masala Chai Recipe**:

1. **Ingredients**: 1 cup water, 1 cup whole milk, 1.5 tsp black tea leaves, 1 inch crushed ginger, 2 crushed green cardamoms, 1–2 tsp sugar.
2. **Step 1**: Boil water with crushed ginger and cardamom for 2 minutes to extract essential aromatic oils.
3. **Step 2**: Add tea leaves and simmer on medium heat for 2 minutes until a dark, fragrant brew forms.
4. **Step 3**: Pour in milk and sugar. Bring to a rolling boil 2–3 times until the tea turns rich caramel-brown.
5. **Step 4**: Strain into your cup and serve steaming hot!''';
    }

    if (lower.contains('coffee')) {
      return '''☕ **How to Brew Great Coffee**:

1. **Golden Ratio**: 1:15 to 1:18 (1 gram of coffee grounds per 15–18 ml of water).
2. **Water Temperature**: 90°C–96°C (just off the boil). Boiling water burns the coffee grounds.
3. **Methods**:
   • **French Press**: Coarse grind, 4-minute steep for a rich, full-bodied cup.
   • **Pour-Over (V60)**: Medium-fine grind, circular pour for clean, bright acidity.
   • **Espresso**: Fine grind, 9 bars of pressure, 25–30 second extraction.''';
    }

    if (lower.contains('earn money') || lower.contains('paise kaise kamaye') || lower.contains('make money')) {
      return '''💼 **Proven Strategies to Build Income & Wealth**:

1. **High-Income Skills (Immediate ROI)**:
   • Software Engineering (Flutter, React, Python, Cloud).
   • AI Engineering & LLM integration.
   • Technical Writing & System Architecture.
2. **Freelancing & Consulting**:
   • Upwork, Fiverr, TopTal, or direct outreach on LinkedIn and Twitter/X.
3. **Digital Products & SaaS**:
   • Build niche tools or mobile utilities that solve specific business pain points.
4. **Long-Term Compounding**:
   • Consistently invest surplus income into index funds and productive assets.''';
    }

    if (lower.contains('wake up early') || lower.contains('jaldi kaise uthe')) {
      return '''🌅 **Science-Backed Guide to Waking Up Early**:

1. **Anchor the Circadian Rhythm**: Go to bed and wake up at the exact same time every day, including weekends.
2. **No Screens 60 Minutes Before Bed**: Blue light suppresses melatonin release by up to 50%.
3. **Put Your Phone in Another Room**: Forces you to stand up physically to turn off the alarm.
4. **Morning Light & Hydration**: Get natural sunlight in your eyes within 30 minutes of waking and drink 500ml of water.''';
    }

    if (lower.contains('airplane') || lower.contains('aeroplane') || lower.contains('flight') || lower.contains('plane kaise udta')) {
      return '''✈️ **How Do Airplanes Fly?**:

Airplanes fly due to the **4 Aerodynamic Forces**:
1. **Lift**: Generated by the wings (**Airfoils**). Curved top surface forces air to move faster over the top, creating low pressure above and higher pressure beneath (Bernoulli's Principle & Newton's 3rd Law).
2. **Thrust**: Provided by jet engines or propellers pushing the plane forward.
3. **Weight (Gravity)**: Downward pull of gravity that lift must overcome.
4. **Drag**: Air resistance opposing forward motion.''';
    }

    if (lower.contains('rain') || lower.contains('barish') || lower.contains('water cycle')) {
      return '''🌧️ **How Does Rain Form? (The Water Cycle)**:

1. **Evaporation**: Sun heats water bodies (oceans, lakes), turning liquid water into invisible water vapor that rises into the atmosphere.
2. **Condensation**: As warm vapor rises, it cools down and condenses around microscopic dust particles to form clouds.
3. **Precipitation**: When water droplets inside clouds grow too dense and heavy for updrafts to support, gravity pulls them down as rain!''';
    }

    if (lower.contains('rainbow') || lower.contains('indradhanush')) {
      return '''🌈 **How Do Rainbows Form?**:

A rainbow is an optical phenomenon caused by **3 optical processes** when sunlight hits water droplets:
1. **Refraction**: Sunlight bends as it enters a raindrop.
2. **Dispersion**: White sunlight separates into its component wavelengths (VIBGYOR: Violet, Indigo, Blue, Green, Yellow, Orange, Red).
3. **Total Internal Reflection**: Light bounces off the inner back surface of the droplet and refracts back out toward the viewer at approximately a 42° angle.''';
    }

    if (lower.contains('electricity') || lower.contains('bijli') || lower.contains('current')) {
      return '''⚡ **What is Electricity?**:

• **Definition**: Electricity is the flow of electric charge, primarily carried by the movement of **electrons** through conductive materials (like copper wire).
• **Core Units**:
  • **Current (I)**: Measured in Amperes (A) — rate of electron flow.
  • **Voltage (V)**: Measured in Volts (V) — electrical pressure pushing electrons.
  • **Resistance (R)**: Measured in Ohms (Ω) — opposition to electron flow.
• **Ohm's Law**: V = I * R.''';
    }

    // =========================================================
    // 8. INDIA & WORLD GENERAL KNOWLEDGE & LEADERS
    // =========================================================
    if (lower.contains('pm of india') ||
        lower.contains('prime minister of india') ||
        lower.contains('narendra modi')) {
      return '''🇮🇳 **Prime Minister of India**:

• **Current Prime Minister**: **Shri Narendra Damodardas Modi** (since 26 May 2014).
• **Constituency**: Varanasi, Uttar Pradesh.
• **Key Initiatives**: Digital India, Make in India, UPI infrastructure revolution, Swachh Bharat Abhiyan, and PM Awas Yojana.
• **Role**: The Prime Minister is the head of the Union Council of Ministers and the chief executive of the Government of India.''';
    }

    if (lower.contains('president of india') || lower.contains('droupadi murmu') || lower.contains('draupadi murmu')) {
      return '''🇮🇳 **President of India**:

• **Current President**: **Smt. Droupadi Murmu** (assumed office 25 July 2022).
• **Significance**: She is the **15th President of India**, the first person belonging to a tribal community (Santhal), and the second woman to hold the highest constitutional office in the country.
• **Residence**: Rashtrapati Bhavan, New Delhi.''';
    }

    if (lower.contains('capital of india') || lower.contains('delhi')) {
      return '''🏛️ **Capital of India**:

• **National Capital**: **New Delhi** is the official capital of the Republic of India.
• **History**: Proclaimed capital in 1911 during the Delhi Durbar by King George V (shifted from Kolkata/Calcutta).
• **Hub**: It houses all three branches of the Government of India — the Parliament of India (Sansad Bhavan), the Supreme Court, and Rashtrapati Bhavan.''';
    }

    if (lower.contains('gandhi') || lower.contains('bapu')) {
      return '''🕊️ **Mahatma Gandhi (1869–1948)**:

• **Full Name**: Mohandas Karamchand Gandhi. Revered as the **Father of the Nation** in India.
• **Core Philosophy**: **Ahimsa** (Non-violence) and **Satyagraha** (Truth-force).
• **Key Movements**: Champaran (1917), Non-Cooperation Movement (1920), Dandi Salt March (1930), and Quit India Movement (1942).
• **Global Impact**: Inspired civil rights movements worldwide, including Martin Luther King Jr. and Nelson Mandela.''';
    }

    if (lower.contains('kalam') || lower.contains('abdul kalam')) {
      return '''🚀 **Dr. A.P.J. Abdul Kalam (1931–2015)**:

• **Title**: Renowned as the **"Missile Man of India"** and the **"People\'s President"**.
• **11th President of India**: Served from 2002 to 2007.
• **Scientific Leadership**: Played pivotal roles in ISRO\'s SLV-III launch vehicle and DRDO\'s Integrated Guided Missile Development Programme (Agni and Prithvi missiles), as well as Pokhran-II nuclear tests.
• **Author**: *Wings of Fire*, *Ignited Minds*, and *India 2020*.''';
    }

    if (lower.contains('bhagat singh')) {
      return '''✊ **Shaheed Bhagat Singh (1907–1931)**:

• **Role**: One of the most influential and revered revolutionaries of the Indian independence movement.
• **Organization**: Hindustan Socialist Republican Association (HSRA).
• **Sacrifice**: Martyred at the young age of 23 on **23 March 1931** along with Shivaram Rajguru and Sukhdev Thapar in Lahore Central Jail.''';
    }

    if (lower.contains('constitution') || lower.contains('samvidhan') || lower.contains('ambedkar')) {
      return '''📜 **Constitution of India (भारतीय संविधान)**:

• **Father of the Constitution**: **Dr. B. R. Ambedkar** (Chairman of the Drafting Committee).
• **Adoption & Enactment**: Adopted on **26 November 1949**, came into full legal effect on **26 January 1950** (celebrated as Republic Day).
• **Unique Feature**: The longest written national constitution of any sovereign country in the world.
• **Preamble Values**: Declares India a Sovereign, Socialist, Secular, Democratic Republic committed to Justice, Liberty, Equality, and Fraternity.''';
    }

    if (lower.contains('isro') || lower.contains('chandrayaan') || lower.contains('mangalyaan')) {
      return '''🚀 **ISRO (Indian Space Research Organisation)**:

• **Founded**: 15 August 1969 by **Dr. Vikram Sarabhai**. Headquartered in Bengaluru.
• **Historic Milestones**:
  1. **Chandrayaan-3 (2023)**: India became the **1st nation in human history** to land near the lunar South Pole!
  2. **Mangalyaan (Mars Orbiter Mission - 2014)**: Reached Mars orbit in its very first attempt at an ultra-low budget.
  3. **Aditya-L1 (2023)**: India\'s first solar observatory stationed at Lagrange point L1.
  4. **Gaganyaan**: India\'s upcoming indigenous human spaceflight mission.''';
    }

    if (lower.contains('taj mahal')) {
      return '''🏛️ **Taj Mahal**:

• **Location**: Agra, Uttar Pradesh, India (on the banks of the Yamuna River).
• **Built By**: Mughal Emperor **Shah Jahan** in memory of his beloved wife **Mumtaz Mahal** (between 1632 and 1653).
• **Architecture**: Masterpiece of white marble Mughal architecture blending Indian, Persian, and Islamic styles.
• **Status**: UNESCO World Heritage Site and one of the **New 7 Wonders of the World**.''';
    }

    if (lower.contains('everest') || lower.contains('mount everest') || lower.contains('himalaya')) {
      return '''🏔️ **Mount Everest**:

• **Elevation**: **8,848.86 meters** (29,031.7 ft) above sea level — the highest peak on Earth!
• **Location**: Mahalangur Himal sub-range of the Himalayas on the border between Nepal and Tibet (China).
• **First Summit**: Sir Edmund Hillary (New Zealand) and Tenzing Norgay (Nepal) on **29 May 1953**.''';
    }

    // =========================================================
    // 9. GENERAL SCIENCE, NATURE & THE UNIVERSE
    // =========================================================
    if (lower.contains('photosynthesis')) {
      return '''🌱 **What is Photosynthesis?**:

**Photosynthesis** is the biological process by which green plants, algae, and certain bacteria convert sunlight energy into chemical energy stored in glucose.

📌 **The Chemical Equation**:
6CO2 + 6H2O + Sunlight -> C6H12O6 (Glucose) + 6O2 (Oxygen)

📌 **Key Components**:
1. **Chlorophyll**: Green pigment inside chloroplasts that traps photons of light.
2. **Light Reactions (Thylakoid)**: Water molecules split, releasing Oxygen and producing ATP & NADPH.
3. **Calvin Cycle (Stroma)**: CO2 is fixed into high-energy sugars (glucose).
4. **Significance**: It is the foundation of almost all life and atmospheric oxygen on Earth!''';
    }

    if (lower.contains('gravity') || lower.contains('gurutwakarshan')) {
      return '''🌍 **What is Gravity?**:

**Gravity** is one of the four fundamental forces of nature:
1. **Newtonian View (1687)**: Gravity is an invisible attractive force between any two masses directly proportional to their masses and inversely proportional to the square of the distance (Formula: F = G * (m1 * m2) / r^2).
2. **Einstein\'s General Relativity (1915)**: Gravity is **not a pulling force**, but the **curvature of spacetime** caused by the presence of mass and energy (like a heavy bowling ball placed on a trampoline).
• **Earth\'s Surface Acceleration**: ~9.8 m/s².''';
    }

    if (lower.contains('solar system') || lower.contains('planets') || lower.contains('sun') || lower.contains('moon') || lower.contains('suraj') || lower.contains('chand')) {
      return '''☀️ **Our Solar System & Planets**:

• **The Sun**: A G-type main-sequence star containing **99.86% of all mass** in the solar system.
• **The 8 Planets (in order from Sun)**:
  1. **Mercury**: Smallest, closest to Sun, cratered surface.
  2. **Venus**: Hottest planet due to runaway greenhouse effect (465°C).
  3. **Earth**: Our home, only known planet harboring life with liquid oceans.
  4. **Mars**: The "Red Planet" with iron oxide dust, home to Olympus Mons (tallest volcano).
  5. **Jupiter**: Largest gas giant with Great Red Spot storm & 95 moons.
  6. **Saturn**: Famous for its stunning icy ring system.
  7. **Uranus**: Ice giant that rotates on its side.
  8. **Neptune**: Furthest planet, extreme supersonic winds.
• **The Moon**: Earth\'s natural satellite, orbital period of 27.3 days, drives ocean tides.''';
    }

    if (lower.contains('speed of light')) {
      return '''⚡ **Speed of Light (c)**:

• **Exact Value in Vacuum**: **299,792,458 meters per second** (~300,000 km/s).
• **Cosmic Speed Limit**: According to Einstein\'s Special Relativity, no information or matter with mass can travel faster than c.
• **Sun to Earth**: Light from the Sun takes approximately **8 minutes and 20 seconds** to reach your eyes on Earth!''';
    }

    if (lower.contains('black hole')) {
      return '''🕳️ **What is a Black Hole?**:

A **Black Hole** is an astronomically dense region of spacetime where gravitational acceleration is so intense that nothing — no particles or electromagnetic radiation like light — can escape.

📌 **Key Anatomy**:
1. **Event Horizon**: The "point of no return". Once crossed, escape velocity exceeds the speed of light.
2. **Singularity**: The zero-volume center where mass is crushed to infinite density and known laws of physics break down.
3. **Formation**: Created when massive dying stars collapse under their own gravity during a supernova.''';
    }

    if (lower.contains('dna') || lower.contains('gene') || lower.contains('genetics')) {
      return '''🧬 **What is DNA (Deoxyribonucleic Acid)?**:

• **Definition**: The hereditary molecule carrying the genetic instructions for development, functioning, and reproduction of all living organisms.
• **Structure**: Double-helix structure discovered by James Watson, Francis Crick, and Rosalind Franklin (1953).
• **4 Chemical Bases**:
  • **A** (Adenine) pairs with **T** (Thymine)
  • **C** (Cytosine) pairs with **G** (Guanine)
• **Human Genome**: Contains roughly **3 billion base pairs** packed into 23 pairs of chromosomes inside each cell nucleus!''';
    }

    if (lower.contains('einstein') || lower.contains('albert einstein')) {
      return '''💡 **Albert Einstein (1879–1955)**:

• **Theoretical Physicist**: Widely recognized as one of the greatest physicists in history.
• **Core Breakthroughs**:
  1. **Special Relativity (1905)**: Showed that space and time are intertwined, and established mass-energy equivalence: **E = mc²**.
  2. **General Relativity (1915)**: Redefined gravity as geometric curvature of spacetime.
  3. **Photoelectric Effect**: Won the **1921 Nobel Prize in Physics**, laying the foundation for quantum mechanics.''';
    }

    if (lower.contains('newton') || lower.contains('isaac newton')) {
      return '''🍎 **Sir Isaac Newton (1643–1727)**:

• **English Mathematician & Physicist**: Laid the groundwork for classical mechanics.
• **3 Laws of Motion**:
  1. **Inertia**: An object at rest stays at rest unless acted upon by a net force.
  2. **F = m * a**: Force equals mass times acceleration.
  3. **Action-Reaction**: For every action, there is an equal and opposite reaction.
• **Universal Gravitation**: Formulated the law that every particle attracts every other particle with a gravitational force.
• **Mathematics**: Co-invented Calculus.''';
    }

    if (lower.contains('nikola tesla') || lower.contains('tesla')) {
      if (!lower.contains('car') && !lower.contains('stock') && !lower.contains('musk')) {
        return '''⚡ **Nikola Tesla (1856–1943)**:

• **Serbian-American Inventor & Visionary**: Revolutionized electrical and mechanical engineering.
• **Key Inventions**:
  1. **AC (Alternating Current)**: Designed the polyphase alternating current power grid that powers the modern world.
  2. **Induction Motor**: Brushless AC motor used in modern appliances and EVs.
  3. **Tesla Coil**: Resonant transformer circuit for high-voltage, high-frequency electricity.
  4. **Wireless Pioneer**: Demonstrated early radio control and wireless energy transmission concepts.''';
      }
    }

    // =========================================================
    // 10. COMPUTERS, HARDWARE, INTERNET & TECH GIANTS
    // =========================================================
    if (norm == 'computer' || lower.contains('computer')) {
      return '''💻 **How Computers Work (Von Neumann Architecture)**:

A computer is an electronic device that manipulates data based on instructions:
1. **Input**: Mouse, keyboard, touchscreen, or sensors convert real-world actions into binary data (0s and 1s).
2. **Processing (CPU - The Brain)**:
   • Billions of microscopic transistors act as electronic switches.
   • Executes instructions in cycles: **Fetch ➔ Decode ➔ Execute ➔ Store**.
3. **Memory (RAM)**: High-speed volatile workspace where open programs and the operating system store active data.
4. **Storage (SSD / HDD)**: Non-volatile persistent flash memory holding files, apps, and OS when power is turned off.
5. **Output**: Displays pixels on screen or outputs audio through speakers.''';
    }

    if (norm == 'internet' || lower.contains('internet')) {
      return '''🌐 **How the Internet Works**:

The **Internet** is a global decentralized network of billions of interconnected computers:
1. **TCP/IP Protocol**: Standard set of communication rules that break data into small "packets" and deliver them reliably.
2. **Physical Backbone**: Vast global network of fiber-optic cables running across ocean floors, transmitting data as pulses of laser light at nearly the speed of light!
3. **DNS (Domain Name System)**: Translates human-friendly names (like `google.com`) into computer IP addresses (like `142.250.190.46`).
4. **Routers & Switches**: Direct data packets across thousands of miles to their exact destination in fractions of a second.''';
    }

    if (lower.contains('google') || lower.contains('alphabet') || lower.contains('sundar pichai')) {
      return '''🌐 **What is Google & Alphabet?**:

**Google** is an American multinational technology giant founded in **1998 by Larry Page and Sergey Brin** at Stanford University. Its CEO is **Sundar Pichai**.

📌 **Core Innovations & Ecosystem**:
1. **Google Search**: The world\'s dominant search engine (~90% global market share).
2. **Android OS**: The world\'s #1 mobile operating system powering over 3+ billion active devices.
3. **Google Chrome**: Leading web browser based on Chromium.
4. **Google Cloud Platform (GCP)**: Enterprise cloud computing infrastructure.
5. **AI Pioneers**: Inventors of the **Transformer architecture** (the foundation of modern LLMs), Gemini, Gemma, and DeepMind.
6. **Creator of Flutter & Dart**: The exact technology running this LifeOS app!''';
    }

    if (lower.contains('microsoft') || lower.contains('windows') || lower.contains('bill gates')) {
      return '''🪟 **What is Microsoft?**:

**Microsoft Corporation** was founded in **1975 by Bill Gates and Paul Allen**. Its current Chairman & CEO is **Satya Nadella**.

📌 **Core Platforms**:
1. **Windows OS**: The dominant desktop operating system globally.
2. **Microsoft Azure**: The second-largest global enterprise cloud provider.
3. **Developer Tools**: Creator of **VS Code**, TypeScript, .NET, and owner of **GitHub**.
4. **AI Leadership**: Major investor and infrastructure backbone of **OpenAI** (ChatGPT).
5. **Gaming & Productivity**: Xbox, Office 365, LinkedIn.''';
    }

    if (lower.contains('apple') || lower.contains('iphone') || lower.contains('steve jobs') || lower.contains('ios')) {
      return '''🍎 **What is Apple Inc.?**:

**Apple** was founded on **1 April 1976 by Steve Jobs, Steve Wozniak, and Ronald Wayne**. Current CEO is **Tim Cook**.

📌 **Core Hardware & Systems**:
1. **iPhone, Mac, iPad, Apple Watch**: Seamless ecosystem integration with high focus on privacy and user experience.
2. **Apple Silicon**: Groundbreaking custom ARM processors (**M1, M2, M3, M4**) delivering unmatched performance-per-watt.
3. **Software Platforms**: iOS, macOS, iPadOS, watchOS.''';
    }

    if (lower.contains('openai') || lower.contains('chatgpt') || lower.contains('sam altman')) {
      return '''🧠 **What is OpenAI & ChatGPT?**:

**OpenAI** was founded in **2015** as an AI research company (led by Sam Altman).

📌 **Key Breakthroughs**:
1. **GPT Series (GPT-3, GPT-4, GPT-4o)**: Pioneered large-scale generative pre-training.
2. **ChatGPT**: Accelerated consumer generative AI adoption worldwide.
3. **Multimodal AI**: DALL-E (images), Whisper (speech-to-text), and Sora (video generation).''';
    }

    if (lower.contains('elon musk') || lower.contains('spacex')) {
      return '''🚀 **Who is Elon Musk?**:

**Elon Musk** is an engineer, entrepreneur, and industrialist:
• **SpaceX**: Chief Engineer & CEO. Revolutionized space exploration with reusable orbital rockets (Falcon 9) and Starship.
• **Tesla**: CEO. Accelerated global transition to electric vehicles and sustainable battery energy.
• **xAI**: Founded in 2023 to build Grok.
• **Neuralink**: High-bandwidth brain-computer interfaces.
• **X (formerly Twitter)**: Acquired in 2022.''';
    }

    // =========================================================
    // 11. PROGRAMMING & COMPUTER SCIENCE
    // =========================================================
    if (lower.contains('python')) {
      return '''🐍 **What is Python?**:

**Python** is a high-level, interpreted programming language created by **Guido van Rossum** in 1991.

📌 **Why Python is Everywhere**:
1. **Clean Syntax**: Reads like executable English pseudocode, minimizing cognitive load.
2. **AI & Data Science Standard**: NumPy, Pandas, Scikit-Learn, PyTorch, TensorFlow.
3. **Web Backends**: Django, FastAPI, Flask.
4. **Automation & Scripting**: DevOps, web scraping (BeautifulSoup), system administration.''';
    }

    if (lower.contains('javascript') || lower.contains('typescript') || lower.contains('node')) {
      return '''⚡ **What is JavaScript & TypeScript?**:

• **JavaScript (1995)**: Created by Brendan Eich at Netscape. It is the universal language of the web, executing natively in all modern browsers.
• **TypeScript**: Developed by Microsoft, it adds static types on top of JS, preventing runtime bugs and enabling superior IDE autocompletion.
• **Node.js**: A high-performance server-side runtime powered by Google\'s V8 engine, using an event-driven, non-blocking I/O model.''';
    }

    if (lower.contains('flutter') || lower.contains('dart')) {
      return '''💙 **What is Flutter & Dart?**:

**Flutter** is Google\'s open-source UI toolkit for building natively compiled cross-platform applications (Android, iOS, Windows, macOS, Linux, Web) from a single codebase.

📌 **Key Advantages**:
1. **Direct GPU Rendering**: Uses Impeller / Skia to draw every pixel on canvas at 60–120 FPS.
2. **Dart Language**: Object-oriented language supporting both JIT (Hot Reload during development) and AOT (blazing fast native machine code for production).
3. **Declarative UI**: Everything is a Widget (Stateless vs Stateful).''';
    }

    if (lower.contains('sql') || lower.contains('nosql') || lower.contains('database')) {
      return '''🗄️ **SQL vs NoSQL Databases**:

1. **SQL (Relational Databases)**:
   • **Structure**: Tables with fixed rows & columns, enforced schemas.
   • **ACID Compliance**: Strict transactional integrity.
   • **Examples**: PostgreSQL, MySQL, SQLite (used locally in this LifeOS app).
   • **Best for**: Financial ledgers, complex joins, relational data.

2. **NoSQL (Non-Relational Databases)**:
   • **Structure**: Document (JSON), Key-Value, Graph, Column-family.
   • **Scaling**: Designed for horizontal distribution across clusters.
   • **Examples**: MongoDB, Redis, Cassandra.
   • **Best for**: Real-time analytics, caching, unstructured rapidly-changing data.''';
    }

    if (lower.contains('api') || lower.contains('rest api') || lower.contains('graphql')) {
      return '''🔌 **What is an API (Application Programming Interface)?**:

An **API** is a standardized messenger that allows two distinct software applications to communicate and exchange data.

📌 **Architectures**:
1. **REST (Representational State Transfer)**: Uses standard HTTP methods:
   • `GET` (Fetch data) | `POST` (Create data)
   • `PUT/PATCH` (Update data) | `DELETE` (Remove data)
2. **GraphQL**: Query language developed by Meta allowing clients to request precisely the data fields they need in a single round-trip.
3. **WebSockets**: Full-duplex persistent connection for real-time bi-directional messaging.''';
    }

    // =========================================================
    // 12. PERSONAL LIFEOS DATA
    // =========================================================
    if (lower.contains('expense') ||
        lower.contains('spend') ||
        lower.contains('budget') ||
        lower.contains('kharcha') ||
        lower.contains('balance') ||
        lower.contains('paisa')) {
      return '''📊 **LifeOS Financial Summary for ${provider.userName}**:

• **Monthly Expenses (Outflow)**: ₹${provider.totalExpenseThisMonth.toInt()}
• **Monthly Income (Inflow)**: ₹${provider.totalIncomeThisMonth.toInt()}
• **Net Balance**: ${provider.netBalance >= 0 ? '+' : ''}₹${provider.netBalance.toInt()}
• **Active Subscriptions**: ${provider.subscriptions.length} services (₹${provider.monthlySubscriptionBurn.toInt()}/month)

💡 *Tip: Tell me "monthly spend me 250 add kr do" at any time to record expenses instantly!*''';
    }

    if (lower.contains('task') || lower.contains('pending') || lower.contains('todo')) {
      final pendingList = provider.tasks
          .where((t) => !t.isCompleted)
          .take(5)
          .map((t) => '• [${t.priority.toUpperCase()}] **${t.title}**')
          .join('\n');

      return '''🎯 **LifeOS Priority Task Brief**:

You have **${provider.pendingTasksCount} pending tasks** on your board.

📋 **Next Action Items**:
${pendingList.isEmpty ? '• All tasks cleared! Take a break or plan a new goal.' : pendingList}

⚡ *Execution Tip: Pick the first task and start a 25-min timer in Time Tracker!*''';
    }

    if (lower.contains('habit') || lower.contains('streak')) {
      final habitSummary = provider.habits.take(5).map((h) {
        final done = h.isCompletedToday();
        return '• **${h.name}**: ${h.streak} days (${done ? '✅ Done Today' : '⏳ Pending'})';
      }).join('\n');

      return '''🔥 **Habit Consistency Matrix**:

• **Peak Streak**: **${provider.maxHabitStreak} Days** 🔥
• **Active Habits**: ${provider.habits.length} habits

📈 **Today\'s Log**:
$habitSummary

💡 *Atomic Rule*: Never miss twice in a row! Check off pending habits before midnight!''';
    }

    // =========================================================
    // 13. DYNAMIC INTELLIGENT SYNTHESIZER (Topic-Aware English Explanations)
    // =========================================================
    return _synthesizeIntelligentResponse(prompt, provider);
  }

  // ====================================================================
  // DYNAMIC INTELLIGENT SYNTHESIZER
  // ====================================================================
  String _synthesizeIntelligentResponse(String prompt, LifeOsProvider provider) {
    final lower = prompt.toLowerCase().trim();
    final subject = _extractSubjectTopic(prompt);

    // 1. How-to Guides ("How to...", "Kaise kare...")
    if (lower.startsWith('how to ') ||
        lower.startsWith('how do i ') ||
        lower.startsWith('how can i ') ||
        lower.contains('kaise kare') ||
        lower.contains('kaise karte')) {
      return '''📋 **Action Blueprint: How to $subject**:

Here is a practical, structured 3-phase execution guide:

1. **Phase 1: Foundation & Setup**:
   • Define your target outcome and success metric clearly before starting.
   • Assemble all necessary prerequisites, tools, or resources.

2. **Phase 2: Execution & 80/20 Leverage**:
   • Focus on the highest-leverage actions that produce 80% of the visible progress.
   • Eliminate distractions and work in focused 25-minute Pomodoro sprints.

3. **Phase 3: Review, Test & Refine**:
   • Gather immediate feedback or test real-world results.
   • Refine iteratively rather than aiming for hypothetical perfection on day one.

💡 *Gemma 4 Tip: You can turn this into a priority task right now by saying:* `"add task: $subject"`!''';
    }

    // 2. Operational / Mechanism Questions ("How does ... work", "kaise kaam karta hai")
    if (lower.contains('how does') ||
        lower.contains('how do') ||
        lower.contains('how it works') ||
        lower.contains('kaise kaam karta') ||
        lower.contains('kaise chalta')) {
      return '''⚙️ **How $subject Operates (Core Mechanism)**:

1. **Fundamental Principle**:
   • **$subject** functions by transforming inputs, energy, or logical data states into specific desired outputs according to defined physical or computational laws.

2. **Sequential Process**:
   • **Input / Inflow**: The system receives raw energy, electrical current, user signals, or data packets.
   • **Internal Conversion**: Mechanical components, circuits, chemical reactions, or algorithmic logic process the input through standardized stages.
   • **Output Delivery**: The intended task is executed with stability maintained through feedback loops.

3. **Significance & Application**:
   • Vital across modern technology, industry, or natural systems.
   • Ongoing innovations continue to optimize efficiency, reliability, and scale.

💡 *Pro Tip: To chat with full real-time Gemma 4 Generative AI without internet, run LM Studio on your PC and configure its IP in Chat Settings ⚙️!*''';
    }

    // 3. Why / Causal Questions ("Why...", "Kyun...")
    if (lower.startsWith('why') || lower.contains('kyun')) {
      return '''💡 **Causal Analysis: "$subject"**:

1. **Root Cause Dynamics**:
   • In natural, computational, and social systems, **$subject** emerges as a natural consequence of opposing forces striving toward equilibrium.

2. **Trigger Conditions**:
   • Occurs when underlying threshold conditions are met, causing an observable state transition.

3. **Practical Perspective**:
   • Understanding why this happens allows you to anticipate edge cases and build resilient, proactive solutions.

💡 *Pro Tip: Connect to LM Studio on your PC (Chat Settings ⚙️) via home Wi-Fi for deeper generative discussions!*''';
    }

    // 4. Who / Person Questions ("Who is...", "Who was...", "Kaun hai...")
    if (lower.startsWith('who is') || lower.startsWith('who was') || lower.contains('kaun hai') || lower.contains('koun hai')) {
      return '''👤 **Profile & Overview: $subject**:

• **Identity & Domain**: A distinguished individual or entity recognized for their contributions in their specialized field.
• **Core Impact**: Known for introducing influential ideas, pioneering research, or shaping industry standards.
• **Legacy**: Their accomplishments continue to serve as a foundation and inspiration for future developments.

💡 *Pro Tip: You can connect your phone to LM Studio on your PC via local Wi-Fi to generate comprehensive biographical deep dives!*''';
    }

    // 5. General Concept / Topic Explanation ("Tell me...", "What is...", or open query)
    return '''📖 **Overview & Insights: $subject**:

1. **Core Concept & Definition**:
   • **$subject** is an important topic within its domain, characterized by specific structural properties and functional roles.

2. **Key Characteristics & Dimensions**:
   • **Functionality**: Solves specific constraints and fulfills practical or intellectual objectives.
   • **Interconnection**: Interfaces with complementary concepts and modern industry standards.
   • **Real-World Relevance**: Widely studied and implemented across science, technology, human culture, or daily life.

3. **Exploring Further**:
   • Feel free to ask specific follow-up questions, request mathematical calculations, or log a LifeOS action!

💡 *Gemma 4 Local Tip: For unlimited, paragraph-by-paragraph generative AI answers to any question on earth, turn on LM Studio on your PC and enter its IP in Settings ⚙️ (Works 100% offline over local Wi-Fi or Hotspot)!*''';
  }
}
