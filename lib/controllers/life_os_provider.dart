import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../core/database/seed_data.dart';
import '../models/expense_model.dart';
import '../models/task_model.dart';
import '../models/study_session_model.dart';
import '../models/time_log_model.dart';
import '../models/goal_okr_model.dart';
import '../models/habit_model.dart';
import '../models/job_model.dart';
import '../models/skill_model.dart';
import '../models/project_model.dart';
import '../models/bug_model.dart';
import '../models/idea_model.dart';
import '../models/resource_model.dart';
import '../models/interview_prep_model.dart';
import '../models/journal_model.dart';
import '../models/document_model.dart';
import '../models/subscription_model.dart';
import '../models/wishlist_model.dart';
import '../models/inventory_model.dart';
import '../models/secure_item_model.dart';
import '../models/note_model.dart';
import '../models/important_date_model.dart';

class LifeOsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  String _userName = 'Harsh';
  String get userName => _userName;

  String _userPin = '1234';
  bool _isVaultLocked = true;
  bool get isVaultLocked => _isVaultLocked;

  // Active Live Timer / Stopwatch State
  Timer? _ticker;
  bool _isTimerRunning = false;
  int _timerSeconds = 0;
  String _timerActivity = 'Flutter Architecture';
  String _timerCategory = 'Study';

  bool get isTimerRunning => _isTimerRunning;
  int get timerSeconds => _timerSeconds;
  String get timerActivity => _timerActivity;
  String get timerCategory => _timerCategory;

  // Module Data Lists
  List<ExpenseModel> _expenses = [];
  List<TaskModel> _tasks = [];
  List<StudySessionModel> _studySessions = [];
  List<TimeLogModel> _timeLogs = [];
  List<GoalModel> _goals = [];
  List<HabitModel> _habits = [];
  List<JobModel> _jobs = [];
  List<SkillModel> _skills = [];
  List<ProjectModel> _projects = [];
  List<BugModel> _bugs = [];
  List<IdeaModel> _ideas = [];
  List<ResourceModel> _resources = [];
  List<InterviewQuestionModel> _interviewQuestions = [];
  List<MockInterviewLogModel> _mockInterviews = [];
  List<JournalModel> _journals = [];
  List<DocumentModel> _documents = [];
  List<SubscriptionModel> _subscriptions = [];
  List<WishlistItemModel> _wishlist = [];
  List<InventoryItemModel> _inventory = [];
  List<SecureItemModel> _secureItems = [];
  List<NoteModel> _notes = [];
  List<ImportantDateModel> _importantDates = [];

  // Getters
  List<ExpenseModel> get expenses => _expenses;
  List<TaskModel> get tasks => _tasks;
  List<StudySessionModel> get studySessions => _studySessions;
  List<TimeLogModel> get timeLogs => _timeLogs;
  List<GoalModel> get goals => _goals;
  List<HabitModel> get habits => _habits;
  List<JobModel> get jobs => _jobs;
  List<SkillModel> get skills => _skills;
  List<ProjectModel> get projects => _projects;
  List<BugModel> get bugs => _bugs;
  List<IdeaModel> get ideas => _ideas;
  List<ResourceModel> get resources => _resources;
  List<InterviewQuestionModel> get interviewQuestions => _interviewQuestions;
  List<MockInterviewLogModel> get mockInterviews => _mockInterviews;
  List<JournalModel> get journals => _journals;
  List<DocumentModel> get documents => _documents;
  List<SubscriptionModel> get subscriptions => _subscriptions;
  List<WishlistItemModel> get wishlist => _wishlist;
  List<InventoryItemModel> get inventory => _inventory;
  List<SecureItemModel> get secureItems => _secureItems;
  List<NoteModel> get notes => _notes;
  List<ImportantDateModel> get importantDates => _importantDates;

  // Computed Financial Metrics
  double get totalExpenseThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.type == 'expense' && e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  double get totalIncomeThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.type == 'income' && e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  double get netBalance => totalIncomeThisMonth - totalExpenseThisMonth;

  double get monthlySubscriptionBurn {
    return _subscriptions.where((s) => s.isActive).fold(0.0, (acc, s) => acc + s.monthlyCost);
  }

  // Computed Productivity Metrics
  int get totalStudyMinutesThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _studySessions
        .where((s) => s.date.isAfter(startOfWeek.subtract(const Duration(days: 1))))
        .fold(0, (acc, s) => acc + s.durationMinutes);
  }

  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingTasksCount => _tasks.where((t) => !t.isCompleted).length;

  int get maxHabitStreak {
    if (_habits.isEmpty) return 0;
    return _habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
  }

  // Smart Local Daily Brief Generator
  Map<String, dynamic> get dailyBrief {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    final tasksDueToday = _tasks.where((t) => !t.isCompleted && t.dueDate != null && DateFormat('yyyy-MM-dd').format(t.dueDate!) == todayStr).length;
    final urgentDeadlines = _importantDates.where((d) => d.daysRemaining >= 0 && d.daysRemaining <= 3).toList();
    final upcomingBills = _subscriptions.where((s) => s.isActive && s.nextBillingDate.difference(now).inDays <= 3 && s.nextBillingDate.isAfter(now.subtract(const Duration(days: 1)))).toList();
    
    String suggestion = 'Keep up the momentum! Focus on your #1 priority task today.';
    if (_skills.any((s) => s.name.contains('DSA') && s.currentLevel < 60)) {
      suggestion = 'You have high-priority DSA practice queued for your job interviews.';
    } else if (tasksDueToday > 0) {
      suggestion = 'You have $tasksDueToday focus tasks scheduled for today.';
    }

    return {
      'greeting': _getGreeting(),
      'tasksCount': tasksDueToday,
      'deadlines': urgentDeadlines,
      'studyHours': (totalStudyMinutesThisWeek / 60).toStringAsFixed(1),
      'spentThisMonth': totalExpenseThisMonth,
      'streak': maxHabitStreak,
      'upcomingBills': upcomingBills,
      'suggestion': suggestion,
    };
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // Initialization
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _userName = prefs.getString('userName') ?? 'Harsh';
    _userPin = prefs.getString('userPin') ?? '1234';

    final db = await _dbHelper.database;
    await SeedData.populateIfEmpty(db);
    await reloadAllData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reloadAllData() async {
    final db = await _dbHelper.database;

    // 1. Expenses
    final expMaps = await db.query('expenses', orderBy: 'date DESC');
    _expenses = expMaps.map((m) => ExpenseModel.fromMap(m)).toList();

    // 2. Tasks
    final taskMaps = await db.query('tasks', orderBy: 'createdAt DESC');
    _tasks = taskMaps.map((m) => TaskModel.fromMap(m)).toList();

    // 3. Study
    final studyMaps = await db.query('study_sessions', orderBy: 'date DESC');
    _studySessions = studyMaps.map((m) => StudySessionModel.fromMap(m)).toList();

    // 4. Time logs
    final timeMaps = await db.query('time_logs', orderBy: 'date DESC');
    _timeLogs = timeMaps.map((m) => TimeLogModel.fromMap(m)).toList();

    // 5. Goals & OKRs
    final goalMaps = await db.query('goals');
    final krMaps = await db.query('key_results');
    _goals = goalMaps.map((gm) {
      final krs = krMaps.where((k) => k['goalId'] == gm['id']).map((k) => KeyResultModel.fromMap(k)).toList();
      return GoalModel.fromMap(gm, keyResults: krs);
    }).toList();

    // 6. Habits
    final habitMaps = await db.query('habits');
    _habits = habitMaps.map((m) => HabitModel.fromMap(m)).toList();

    // 7. Jobs
    final jobMaps = await db.query('jobs', orderBy: 'appliedDate DESC');
    _jobs = jobMaps.map((m) => JobModel.fromMap(m)).toList();

    // 8. Skills
    final skillMaps = await db.query('skills', orderBy: 'currentLevel DESC');
    _skills = skillMaps.map((m) => SkillModel.fromMap(m)).toList();

    // 9. Projects
    final projMaps = await db.query('projects');
    _projects = projMaps.map((m) => ProjectModel.fromMap(m)).toList();

    // 10. Bugs
    final bugMaps = await db.query('bugs', orderBy: 'createdAt DESC');
    _bugs = bugMaps.map((m) => BugModel.fromMap(m)).toList();

    // 11. Ideas
    final ideaMaps = await db.query('ideas', orderBy: 'createdAt DESC');
    _ideas = ideaMaps.map((m) => IdeaModel.fromMap(m)).toList();

    // 12. Resources
    final resMaps = await db.query('resources');
    _resources = resMaps.map((m) => ResourceModel.fromMap(m)).toList();

    // 13. Interview Prep
    final qMaps = await db.query('interview_questions');
    _interviewQuestions = qMaps.map((m) => InterviewQuestionModel.fromMap(m)).toList();
    final mockMaps = await db.query('mock_interviews', orderBy: 'date DESC');
    _mockInterviews = mockMaps.map((m) => MockInterviewLogModel.fromMap(m)).toList();

    // 14. Journal
    final jMaps = await db.query('journals', orderBy: 'date DESC');
    _journals = jMaps.map((m) => JournalModel.fromMap(m)).toList();

    // 15. Documents
    final docMaps = await db.query('documents');
    _documents = docMaps.map((m) => DocumentModel.fromMap(m)).toList();

    // 16. Subscriptions
    final subMaps = await db.query('subscriptions', orderBy: 'nextBillingDate ASC');
    _subscriptions = subMaps.map((m) => SubscriptionModel.fromMap(m)).toList();

    // 17. Wishlist
    final wishMaps = await db.query('wishlist');
    _wishlist = wishMaps.map((m) => WishlistItemModel.fromMap(m)).toList();

    // 18. Inventory
    final invMaps = await db.query('inventory');
    _inventory = invMaps.map((m) => InventoryItemModel.fromMap(m)).toList();

    // 19. Secure Items
    final secMaps = await db.query('secure_items', orderBy: 'updatedAt DESC');
    _secureItems = secMaps.map((m) => SecureItemModel.fromMap(m)).toList();

    // 20. Notes
    final noteMaps = await db.query('notes', orderBy: 'isPinned DESC, updatedAt DESC');
    _notes = noteMaps.map((m) => NoteModel.fromMap(m)).toList();

    // 21. Important Dates
    final dateMaps = await db.query('important_dates', orderBy: 'date ASC');
    _importantDates = dateMaps.map((m) => ImportantDateModel.fromMap(m)).toList();

    notifyListeners();
  }

  // --- THEME & SETTINGS ---
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    notifyListeners();
  }

  Future<void> setUserPin(String pin) async {
    _userPin = pin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPin', pin);
    notifyListeners();
  }

  bool unlockVault(String enteredPin) {
    if (enteredPin == _userPin) {
      _isVaultLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockVault() {
    _isVaultLocked = true;
    notifyListeners();
  }

  // --- LIVE TIMER / POMODORO LOGIC ---
  void startTimer({String? activity, String? category}) {
    if (activity != null) _timerActivity = activity;
    if (category != null) _timerCategory = category;
    _isTimerRunning = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timerSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void pauseTimer() {
    _isTimerRunning = false;
    _ticker?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _isTimerRunning = false;
    _ticker?.cancel();
    _timerSeconds = 0;
    notifyListeners();
  }

  Future<void> finishTimer() async {
    if (_timerSeconds < 5) {
      resetTimer();
      return;
    }
    final duration = _timerSeconds;
    final act = _timerActivity;
    final cat = _timerCategory;
    resetTimer();

    // 1. Log time in Time Logs
    final timeLog = TimeLogModel(
      id: _uuid.v4(),
      activity: act,
      category: cat,
      durationSeconds: duration,
      date: DateTime.now(),
      notes: 'Logged via LifeOS Live Timer',
    );
    final db = await _dbHelper.database;
    await db.insert('time_logs', timeLog.toMap());

    // 2. Interconnected update: If category is Study or Project, update corresponding Skill level & practice hours!
    for (var skill in _skills) {
      if (act.toLowerCase().contains(skill.name.toLowerCase())) {
        final addedHours = duration / 3600.0;
        final newHours = skill.practiceHours + addedHours;
        final levelBoost = (addedHours * 2).clamp(0.0, 5.0).toInt();
        final newLevel = (skill.currentLevel + levelBoost).clamp(0, skill.targetLevel);

        final updatedSkill = skill.copyWith(
          practiceHours: newHours,
          currentLevel: newLevel,
        );
        await db.update('skills', updatedSkill.toMap(), where: 'id = ?', whereArgs: [skill.id]);
        break;
      }
    }

    await reloadAllData();
  }

  // --- CROSS-MODULE INTERCONNECTIONS: EXPENSES ---
  Future<void> addExpense(ExpenseModel expense) async {
    final db = await _dbHelper.database;
    await db.insert('expenses', expense.toMap());
    await reloadAllData();
  }

  Future<void> deleteExpense(String id) async {
    final db = await _dbHelper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await reloadAllData();
  }

  // --- TASKS & GOAL INTERCONNECTION ---
  Future<void> addTask(TaskModel task) async {
    final db = await _dbHelper.database;
    await db.insert('tasks', task.toMap());
    await reloadAllData();
  }

  Future<void> toggleTask(TaskModel task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    final db = await _dbHelper.database;
    await db.update('tasks', updated.toMap(), where: 'id = ?', whereArgs: [task.id]);

    // Interconnection: Completing a task linked to an Objective increments its Key Results!
    if (updated.isCompleted && task.linkedGoalId != null && task.linkedGoalId!.isNotEmpty) {
      final krs = await db.query('key_results', where: 'goalId = ?', whereArgs: [task.linkedGoalId]);
      if (krs.isNotEmpty) {
        final kr = KeyResultModel.fromMap(krs.first);
        final newCurrent = (kr.current + 1).clamp(0.0, kr.target);
        await db.update('key_results', {'current': newCurrent}, where: 'id = ?', whereArgs: [kr.id]);
      }
    }

    await reloadAllData();
  }

  Future<void> deleteTask(String id) async {
    final db = await _dbHelper.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await reloadAllData();
  }

  // --- STUDY SESSION & SKILL INTERCONNECTION ---
  Future<void> addStudySession(StudySessionModel session) async {
    final db = await _dbHelper.database;
    await db.insert('study_sessions', session.toMap());

    // Interconnection: Auto update skill level and practice hours
    for (var skill in _skills) {
      if (skill.name.toLowerCase().contains(session.subject.toLowerCase()) ||
          session.subject.toLowerCase().contains(skill.name.toLowerCase())) {
        final addedHours = session.durationMinutes / 60.0;
        final newHours = skill.practiceHours + addedHours;
        final levelBoost = (session.rating >= 4 ? 2 : 1);
        final newLevel = (skill.currentLevel + levelBoost).clamp(0, skill.targetLevel);

        final updated = skill.copyWith(
          practiceHours: newHours,
          currentLevel: newLevel,
        );
        await db.update('skills', updated.toMap(), where: 'id = ?', whereArgs: [skill.id]);
        break;
      }
    }

    await reloadAllData();
  }

  // --- HABITS & STREAK CALCULATION ---
  Future<void> toggleHabitToday(HabitModel habit) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dates = List<String>.from(habit.completedDates);
    int newStreak = habit.streak;

    if (dates.contains(today)) {
      dates.remove(today);
      newStreak = (newStreak - 1).clamp(0, 9999);
    } else {
      dates.add(today);
      newStreak += 1;
    }

    final updated = habit.copyWith(
      completedDates: dates,
      streak: newStreak,
    );

    final db = await _dbHelper.database;
    await db.update('habits', updated.toMap(), where: 'id = ?', whereArgs: [habit.id]);
    await reloadAllData();
  }

  Future<void> addHabit(String name, String iconName) async {
    final habit = HabitModel(
      id: _uuid.v4(),
      name: name,
      iconName: iconName,
      streak: 0,
      completedDates: [],
    );
    final db = await _dbHelper.database;
    await db.insert('habits', habit.toMap());
    await reloadAllData();
  }

  // --- JOBS & CAREER ---
  Future<void> addJob(JobModel job) async {
    final db = await _dbHelper.database;
    await db.insert('jobs', job.toMap());
    await reloadAllData();
  }

  Future<void> updateJobStatus(String jobId, String newStatus) async {
    final db = await _dbHelper.database;
    await db.update('jobs', {'status': newStatus}, where: 'id = ?', whereArgs: [jobId]);
    await reloadAllData();
  }

  // --- SKILLS ---
  Future<void> addSkill(SkillModel skill) async {
    final db = await _dbHelper.database;
    await db.insert('skills', skill.toMap());
    await reloadAllData();
  }

  Future<void> updateSkillLevel(String id, int level) async {
    final db = await _dbHelper.database;
    await db.update('skills', {'currentLevel': level.clamp(0, 100)}, where: 'id = ?', whereArgs: [id]);
    await reloadAllData();
  }

  // --- PROJECTS ---
  Future<void> addProject(ProjectModel project) async {
    final db = await _dbHelper.database;
    await db.insert('projects', project.toMap());
    await reloadAllData();
  }

  Future<void> updateProjectProgress(String id, int progress) async {
    final db = await _dbHelper.database;
    await db.update('projects', {'progress': progress.clamp(0, 100)}, where: 'id = ?', whereArgs: [id]);
    await reloadAllData();
  }

  // --- BUGS (MINI JIRA) ---
  Future<void> addBug(BugModel bug) async {
    final db = await _dbHelper.database;
    await db.insert('bugs', bug.toMap());
    await reloadAllData();
  }

  Future<void> updateBugStatus(String id, String status) async {
    final db = await _dbHelper.database;
    await db.update('bugs', {'status': status}, where: 'id = ?', whereArgs: [id]);
    await reloadAllData();
  }

  // --- IDEAS ---
  Future<void> addIdea(IdeaModel idea) async {
    final db = await _dbHelper.database;
    await db.insert('ideas', idea.toMap());
    await reloadAllData();
  }

  // --- RESOURCES ---
  Future<void> addResource(ResourceModel resource) async {
    final db = await _dbHelper.database;
    await db.insert('resources', resource.toMap());
    await reloadAllData();
  }

  Future<void> toggleResourceFavorite(ResourceModel resource) async {
    final db = await _dbHelper.database;
    await db.update('resources', {'isFavorite': resource.isFavorite ? 0 : 1}, where: 'id = ?', whereArgs: [resource.id]);
    await reloadAllData();
  }

  // --- INTERVIEW PREP ---
  Future<void> toggleInterviewQuestionMastered(InterviewQuestionModel q) async {
    final db = await _dbHelper.database;
    await db.update('interview_questions', {'isMastered': q.isMastered ? 0 : 1}, where: 'id = ?', whereArgs: [q.id]);
    await reloadAllData();
  }

  Future<void> addMockInterview(MockInterviewLogModel mock) async {
    final db = await _dbHelper.database;
    await db.insert('mock_interviews', mock.toMap());
    await reloadAllData();
  }

  // --- JOURNAL ---
  Future<void> addJournalEntry(JournalModel entry) async {
    final db = await _dbHelper.database;
    await db.insert('journals', entry.toMap());
    await reloadAllData();
  }

  // --- DOCUMENTS VAULT ---
  Future<void> addDocument(DocumentModel doc) async {
    final db = await _dbHelper.database;
    await db.insert('documents', doc.toMap());
    await reloadAllData();
  }

  // --- SUBSCRIPTIONS ---
  Future<void> addSubscription(SubscriptionModel sub) async {
    final db = await _dbHelper.database;
    await db.insert('subscriptions', sub.toMap());
    await reloadAllData();
  }

  // --- WISHLIST ---
  Future<void> addWishlistItem(WishlistItemModel item) async {
    final db = await _dbHelper.database;
    await db.insert('wishlist', item.toMap());
    await reloadAllData();
  }

  Future<void> toggleWishlistPurchased(WishlistItemModel item) async {
    final db = await _dbHelper.database;
    await db.update('wishlist', {'isPurchased': item.isPurchased ? 0 : 1}, where: 'id = ?', whereArgs: [item.id]);
    await reloadAllData();
  }

  // --- INVENTORY ---
  Future<void> addInventoryItem(InventoryItemModel item) async {
    final db = await _dbHelper.database;
    await db.insert('inventory', item.toMap());
    await reloadAllData();
  }

  // --- SECURE VAULT ---
  Future<void> addSecureItem(SecureItemModel item) async {
    final db = await _dbHelper.database;
    await db.insert('secure_items', item.toMap());
    await reloadAllData();
  }

  Future<void> deleteSecureItem(String id) async {
    final db = await _dbHelper.database;
    await db.delete('secure_items', where: 'id = ?', whereArgs: [id]);
    await reloadAllData();
  }

  // --- NOTES ---
  Future<void> addNote(NoteModel note) async {
    final db = await _dbHelper.database;
    await db.insert('notes', note.toMap());
    await reloadAllData();
  }

  Future<void> toggleNotePinned(NoteModel note) async {
    final db = await _dbHelper.database;
    await db.update('notes', {'isPinned': note.isPinned ? 0 : 1}, where: 'id = ?', whereArgs: [note.id]);
    await reloadAllData();
  }

  // --- IMPORTANT DATES ---
  Future<void> addImportantDate(ImportantDateModel item) async {
    final db = await _dbHelper.database;
    await db.insert('important_dates', item.toMap());
    await reloadAllData();
  }

  // --- GOALS & OKRs ---
  Future<void> addGoal(GoalModel goal, List<KeyResultModel> keyResults) async {
    final db = await _dbHelper.database;
    await db.insert('goals', goal.toMap());
    for (var kr in keyResults) {
      await db.insert('key_results', kr.toMap());
    }
    await reloadAllData();
  }

  Future<void> updateKeyResultCurrent(String krId, double current) async {
    final db = await _dbHelper.database;
    await db.update('key_results', {'current': current}, where: 'id = ?', whereArgs: [krId]);
    await reloadAllData();
  }

  // --- BACKUP & RESTORE ---
  Future<String> exportBackupJson() async {
    final backup = {
      'exportedAt': DateTime.now().toIso8601String(),
      'expenses': _expenses.map((e) => e.toMap()).toList(),
      'tasks': _tasks.map((t) => t.toMap()).toList(),
      'studySessions': _studySessions.map((s) => s.toMap()).toList(),
      'goals': _goals.map((g) => g.toMap()).toList(),
      'habits': _habits.map((h) => h.toMap()).toList(),
      'jobs': _jobs.map((j) => j.toMap()).toList(),
      'skills': _skills.map((s) => s.toMap()).toList(),
      'projects': _projects.map((p) => p.toMap()).toList(),
      'notes': _notes.map((n) => n.toMap()).toList(),
      'subscriptions': _subscriptions.map((s) => s.toMap()).toList(),
      'wishlist': _wishlist.map((w) => w.toMap()).toList(),
      'inventory': _inventory.map((i) => i.toMap()).toList(),
      'secureItems': _secureItems.map((s) => s.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  Future<bool> importBackupJson(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final db = await _dbHelper.database;

      if (data.containsKey('expenses')) {
        for (var item in data['expenses']) {
          await db.insert('expenses', item, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data.containsKey('tasks')) {
        for (var item in data['tasks']) {
          await db.insert('tasks', item, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      await reloadAllData();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
