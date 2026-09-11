import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('life_os.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for Windows / Desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _getDatabaseDirectory();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<String> _getDatabaseDirectory() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final directory = await getApplicationSupportDirectory();
      return directory.path;
    } else {
      return await getDatabasesPath();
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Expenses
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        paymentMode TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Tasks
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL,
        dueDate TEXT,
        isCompleted INTEGER NOT NULL,
        linkedGoalId TEXT,
        linkedProjectId TEXT,
        tag TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Study Sessions
    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        date TEXT NOT NULL,
        rating INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    // Time Logs
    await db.execute('''
      CREATE TABLE time_logs (
        id TEXT PRIMARY KEY,
        activity TEXT NOT NULL,
        category TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Goals & OKRs
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        targetDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE key_results (
        id TEXT PRIMARY KEY,
        goalId TEXT NOT NULL,
        title TEXT NOT NULL,
        current REAL NOT NULL,
        target REAL NOT NULL,
        unit TEXT NOT NULL
      )
    ''');

    // Habits
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconName TEXT NOT NULL,
        streak INTEGER NOT NULL,
        completedDates TEXT NOT NULL
      )
    ''');

    // Jobs & Career
    await db.execute('''
      CREATE TABLE jobs (
        id TEXT PRIMARY KEY,
        company TEXT NOT NULL,
        position TEXT NOT NULL,
        appliedDate TEXT NOT NULL,
        status TEXT NOT NULL,
        testDate TEXT,
        interviewDate TEXT,
        result TEXT,
        package TEXT,
        location TEXT,
        jobLink TEXT,
        notes TEXT
      )
    ''');

    // Skills
    await db.execute('''
      CREATE TABLE skills (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        currentLevel INTEGER NOT NULL,
        targetLevel INTEGER NOT NULL,
        resources TEXT,
        notes TEXT,
        practiceHours REAL NOT NULL
      )
    ''');

    // Coding Projects
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        technologies TEXT NOT NULL,
        progress INTEGER NOT NULL,
        githubUrl TEXT,
        liveUrl TEXT,
        status TEXT NOT NULL
      )
    ''');

    // Bugs (Mini Jira)
    await db.execute('''
      CREATE TABLE bugs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        projectId TEXT,
        projectName TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Ideas
    await db.execute('''
      CREATE TABLE ideas (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        description TEXT NOT NULL,
        technologies TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Resources & Bookmarks
    await db.execute('''
      CREATE TABLE resources (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        tags TEXT,
        isFavorite INTEGER NOT NULL,
        isRead INTEGER NOT NULL
      )
    ''');

    // Interview Prep
    await db.execute('''
      CREATE TABLE interview_questions (
        id TEXT PRIMARY KEY,
        technology TEXT NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        isMastered INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE mock_interviews (
        id TEXT PRIMARY KEY,
        company TEXT NOT NULL,
        date TEXT NOT NULL,
        questionsAsked TEXT NOT NULL,
        performanceRating INTEGER NOT NULL,
        thingsToImprove TEXT
      )
    ''');

    // Journal
    await db.execute('''
      CREATE TABLE journals (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        mood TEXT NOT NULL,
        whatHappened TEXT NOT NULL,
        whatLearned TEXT NOT NULL,
        wentWell TEXT NOT NULL,
        couldImprove TEXT NOT NULL
      )
    ''');

    // Documents Vault
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        year TEXT NOT NULL,
        status TEXT NOT NULL,
        identifierNo TEXT,
        expiryDate TEXT,
        notes TEXT,
        hasFile INTEGER NOT NULL
      )
    ''');

    // Subscriptions
    await db.execute('''
      CREATE TABLE subscriptions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        billingCycle TEXT NOT NULL,
        nextBillingDate TEXT NOT NULL,
        category TEXT NOT NULL,
        isActive INTEGER NOT NULL
      )
    ''');

    // Wishlist
    await db.execute('''
      CREATE TABLE wishlist (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        price REAL NOT NULL,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        url TEXT,
        isPurchased INTEGER NOT NULL
      )
    ''');

    // Inventory
    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        purchaseDate TEXT NOT NULL,
        warrantyExpiry TEXT,
        serialNumber TEXT,
        notes TEXT
      )
    ''');

    // Secure Vault
    await db.execute('''
      CREATE TABLE secure_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        secretValue TEXT NOT NULL,
        secondaryValue TEXT,
        notes TEXT,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Notes
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        isPinned INTEGER NOT NULL,
        colorHex TEXT,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Important Dates
    await db.execute('''
      CREATE TABLE important_dates (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        reminderTime TEXT,
        notes TEXT
      )
    ''');
  }

  Future<void> clearAllData() async {
    final db = await database;
    final tables = [
      'expenses', 'tasks', 'study_sessions', 'time_logs', 'goals', 'key_results',
      'habits', 'jobs', 'skills', 'projects', 'bugs', 'ideas', 'resources',
      'interview_questions', 'mock_interviews', 'journals', 'documents',
      'subscriptions', 'wishlist', 'inventory', 'secure_items', 'notes', 'important_dates'
    ];
    for (var table in tables) {
      await db.delete(table);
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
