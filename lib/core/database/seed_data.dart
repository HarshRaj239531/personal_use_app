import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/expense_model.dart';
import '../../models/task_model.dart';
import '../../models/study_session_model.dart';
import '../../models/time_log_model.dart';
import '../../models/goal_okr_model.dart';
import '../../models/habit_model.dart';
import '../../models/job_model.dart';
import '../../models/skill_model.dart';
import '../../models/project_model.dart';
import '../../models/bug_model.dart';
import '../../models/idea_model.dart';
import '../../models/resource_model.dart';
import '../../models/interview_prep_model.dart';
import '../../models/journal_model.dart';
import '../../models/document_model.dart';
import '../../models/subscription_model.dart';
import '../../models/wishlist_model.dart';
import '../../models/inventory_model.dart';
import '../../models/secure_item_model.dart';
import '../../models/note_model.dart';
import '../../models/important_date_model.dart';

class SeedData {
  static Future<void> populateIfEmpty(Database db) async {
    final taskCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tasks'));
    if (taskCount != null && taskCount > 0) {
      return; // Already populated
    }

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
    final day2 = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 2)));
    final day3 = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 3)));

    // 1. Expenses
    final expenses = [
      ExpenseModel(id: 'exp_1', title: 'Swiggy Dinner', amount: 480, type: 'expense', category: 'Food', paymentMode: 'UPI', date: now.subtract(const Duration(hours: 4))),
      ExpenseModel(id: 'exp_2', title: 'Monthly Metro Pass', amount: 1200, type: 'expense', category: 'Transport', paymentMode: 'UPI', date: now.subtract(const Duration(days: 2))),
      ExpenseModel(id: 'exp_3', title: 'Tech Domain Renewal', amount: 999, type: 'expense', category: 'Tech', paymentMode: 'Card', date: now.subtract(const Duration(days: 4))),
      ExpenseModel(id: 'exp_4', title: 'DSA Masterclass Book', amount: 650, type: 'expense', category: 'Education', paymentMode: 'UPI', date: now.subtract(const Duration(days: 6))),
      ExpenseModel(id: 'exp_5', title: 'Freelance Milestone', amount: 45000, type: 'income', category: 'Salary', paymentMode: 'NetBanking', date: now.subtract(const Duration(days: 8))),
    ];
    for (var exp in expenses) {
      await db.insert('expenses', exp.toMap());
    }

    // 2. Goals & OKRs
    final goalId = 'goal_1';
    final goal = GoalModel(
      id: goalId,
      title: 'Get a Software Developer Job',
      category: 'Career',
      targetDate: now.add(const Duration(days: 45)),
    );
    await db.insert('goals', goal.toMap());

    final keyResults = [
      KeyResultModel(id: 'kr_1', goalId: goalId, title: 'Improve DSA Problem Solving', current: 60, target: 100, unit: '%'),
      KeyResultModel(id: 'kr_2', goalId: goalId, title: 'Build 3 Full-Stack/Flutter Projects', current: 2, target: 3, unit: 'projects'),
      KeyResultModel(id: 'kr_3', goalId: goalId, title: 'Apply to 20 Top Tech Companies', current: 12, target: 20, unit: 'companies'),
    ];
    for (var kr in keyResults) {
      await db.insert('key_results', kr.toMap());
    }

    // 3. Tasks
    final tasks = [
      TaskModel(id: 't_1', title: 'Complete Flutter State Management module', priority: 'High', dueDate: now, linkedGoalId: goalId, tag: 'Flutter'),
      TaskModel(id: 't_2', title: 'Apply to 2 High-Growth Tech Startups', priority: 'High', dueDate: now, linkedGoalId: goalId, tag: 'Career'),
      TaskModel(id: 't_3', title: 'Practice 2 DSA Tree Questions', priority: 'Medium', dueDate: now, linkedGoalId: goalId, tag: 'DSA'),
      TaskModel(id: 't_4', title: 'Review HillGuard GitHub Readme & Architecture', priority: 'Low', dueDate: now.add(const Duration(days: 2)), linkedProjectId: 'proj_1', tag: 'Project'),
      TaskModel(id: 't_5', title: 'Organize BCA Marksheets in Document Vault', priority: 'Medium', dueDate: now.add(const Duration(days: 3)), isCompleted: true, tag: 'Personal'),
    ];
    for (var t in tasks) {
      await db.insert('tasks', t.toMap());
    }

    // 4. Study Sessions
    final studySessions = [
      StudySessionModel(id: 's_1', subject: 'Flutter', topic: 'State Management & SQLite FFI', durationMinutes: 120, date: now.subtract(const Duration(days: 1)), rating: 5, notes: 'Built local offline-first storage architecture'),
      StudySessionModel(id: 's_2', subject: 'DSA', topic: 'Binary Search & Sliding Window', durationMinutes: 90, date: now.subtract(const Duration(days: 2)), rating: 4, notes: 'Solved 4 medium LeetCode questions'),
      StudySessionModel(id: 's_3', subject: 'Python', topic: 'Decorators and Generators', durationMinutes: 60, date: now.subtract(const Duration(days: 3)), rating: 4, notes: 'Mastered memory efficiency in Python iterators'),
    ];
    for (var s in studySessions) {
      await db.insert('study_sessions', s.toMap());
    }

    // 5. Time Logs
    final timeLogs = [
      TimeLogModel(id: 'tl_1', activity: 'Flutter LifeOS Dev', category: 'Project', durationSeconds: 7200, date: now),
      TimeLogModel(id: 'tl_2', activity: 'DSA Practice', category: 'Study', durationSeconds: 4800, date: now.subtract(const Duration(days: 1))),
      TimeLogModel(id: 'tl_3', activity: 'Job Applications & Cold Emails', category: 'Job', durationSeconds: 2700, date: now.subtract(const Duration(days: 2))),
    ];
    for (var tl in timeLogs) {
      await db.insert('time_logs', tl.toMap());
    }

    // 6. Habits
    final habits = [
      HabitModel(id: 'h_1', name: 'Coding & Development', iconName: 'code', streak: 12, completedDates: [today, yesterday, day2, day3]),
      HabitModel(id: 'h_2', name: 'Study & Learning', iconName: 'book', streak: 8, completedDates: [today, yesterday, day2]),
      HabitModel(id: 'h_3', name: 'Daily Workout / Fitness', iconName: 'fitness', streak: 5, completedDates: [today, yesterday]),
      HabitModel(id: 'h_4', name: 'Drink 3L Water', iconName: 'water', streak: 14, completedDates: [today, yesterday, day2, day3]),
      HabitModel(id: 'h_5', name: 'Read 20 Pages', iconName: 'read', streak: 4, completedDates: [yesterday, day2]),
      HabitModel(id: 'h_6', name: 'Night Journaling', iconName: 'journal', streak: 7, completedDates: [today, yesterday]),
    ];
    for (var h in habits) {
      await db.insert('habits', h.toMap());
    }

    // 7. Jobs & Career
    final jobs = [
      JobModel(id: 'job_1', company: 'Google', position: 'Software Engineer - Mobile', appliedDate: now.subtract(const Duration(days: 12)), status: 'Interview', interviewDate: now.add(const Duration(days: 5)), package: '₹32 LPA', location: 'Bangalore / Hybrid', jobLink: 'https://careers.google.com', notes: 'Technical round scheduled'),
      JobModel(id: 'job_2', company: 'Razorpay', position: 'Frontend / Flutter Engineer', appliedDate: now.subtract(const Duration(days: 8)), status: 'Assessment', testDate: now.add(const Duration(days: 2)), package: '₹18 LPA', location: 'Bangalore', jobLink: 'https://razorpay.com/jobs', notes: 'Coding assessment pending'),
      JobModel(id: 'job_3', company: 'Zerodha', position: 'Full-Stack Developer', appliedDate: now.subtract(const Duration(days: 15)), status: 'Waiting', package: '₹22 LPA', location: 'Remote', jobLink: 'https://zerodha.tech', notes: 'Resume screened'),
      JobModel(id: 'job_4', company: 'Swiggy', position: 'Software Development Engineer I', appliedDate: now.subtract(const Duration(days: 20)), status: 'Selected', package: '₹16 LPA', location: 'Bangalore', notes: 'Offer in hand!'),
      JobModel(id: 'job_5', company: 'TCS Digital', position: 'Systems Engineer', appliedDate: now.subtract(const Duration(days: 30)), status: 'Selected', package: '₹7.5 LPA', location: 'Noida', notes: 'Selected via Prime track'),
    ];
    for (var j in jobs) {
      await db.insert('jobs', j.toMap());
    }

    // 8. Skills
    final skills = [
      SkillModel(id: 'sk_1', name: 'Flutter & Dart', currentLevel: 85, targetLevel: 95, resources: 'Flutter Docs, ResoCoder, Riverpod repo', notes: 'Expert in Architecture, UI & Native Plugins', practiceHours: 240),
      SkillModel(id: 'sk_2', name: 'Laravel & PHP', currentLevel: 65, targetLevel: 80, resources: 'Laracasts, Official Laravel Docs', notes: 'REST APIs, Eloquent, Authentication', practiceHours: 110),
      SkillModel(id: 'sk_3', name: 'Python', currentLevel: 75, targetLevel: 90, resources: 'Corey Schafer, FastApi docs', notes: 'Data processing, Automation, APIs', practiceHours: 150),
      SkillModel(id: 'sk_4', name: 'DSA (Data Structures)', currentLevel: 55, targetLevel: 85, resources: 'Striver SDE Sheet, LeetCode Top 150', notes: 'Strengthen Dynamic Programming & Graphs', practiceHours: 180),
      SkillModel(id: 'sk_5', name: 'SQL & Database Design', currentLevel: 80, targetLevel: 90, resources: 'PostgreSQL Tutorial, High-Performance MySQL', notes: 'Indexing, Joins, Query Optimization', practiceHours: 90),
      SkillModel(id: 'sk_6', name: 'Git & DevOps Basics', currentLevel: 90, targetLevel: 95, resources: 'Pro Git Book, GitHub Actions', notes: 'Branching strategies, CI/CD pipelines', practiceHours: 70),
    ];
    for (var sk in skills) {
      await db.insert('skills', sk.toMap());
    }

    // 9. Coding Projects
    final projects = [
      ProjectModel(id: 'proj_1', title: 'HillGuard', description: 'Real-time mountain landslide and emergency monitoring alert system.', technologies: 'Flutter, Firebase, IoT, SQLite', progress: 85, githubUrl: 'https://github.com/harsh/hillguard', status: 'In Progress'),
      ProjectModel(id: 'proj_2', title: 'SlickSync', description: 'Ultra-fast cross-platform local network clipboard and file sync tool.', technologies: 'Flutter, WebSockets, Dart FFI', progress: 100, githubUrl: 'https://github.com/harsh/slicksync', liveUrl: 'https://slicksync.dev', status: 'Completed'),
      ProjectModel(id: 'proj_3', title: 'Personal Finance AI', description: 'Smart expense and budgeting app with predictive analytics.', technologies: 'Flutter, Machine Learning, SQLite', progress: 50, githubUrl: 'https://github.com/harsh/personal-finance', status: 'In Progress'),
    ];
    for (var p in projects) {
      await db.insert('projects', p.toMap());
    }

    // 10. Bugs (Mini Jira)
    final bugs = [
      BugModel(id: 'bug_1', title: 'Login API returning 401 on token expiration', description: 'Need automatic refresh token interceptor', priority: 'High', status: 'Open', projectId: 'proj_1', projectName: 'HillGuard'),
      BugModel(id: 'bug_2', title: 'UI overflow on user profile small screens', description: 'Wrap column in SingleChildScrollView', priority: 'Medium', status: 'Fixed', projectId: 'proj_2', projectName: 'SlickSync'),
      BugModel(id: 'bug_3', title: 'WebSocket reconnection latency on network drop', description: 'Implement exponential backoff retry loop', priority: 'Critical', status: 'In Progress', projectId: 'proj_2', projectName: 'SlickSync'),
    ];
    for (var b in bugs) {
      await db.insert('bugs', b.toMap());
    }

    // 11. Ideas
    final ideas = [
      IdeaModel(id: 'idea_1', title: 'Offline Emergency Communication App', category: 'Project', priority: 'High', description: 'Peer-to-peer mesh network communication app using Wi-Fi Direct and BLE when cellular networks fail.', technologies: 'Flutter, Bluetooth Low Energy, Wi-Fi Direct', status: 'In Progress'),
      IdeaModel(id: 'idea_2', title: 'AI Code Reviewer CLI', category: 'Tool', priority: 'Medium', description: 'CLI tool that checks git diffs before push and suggests security and performance fixes.', technologies: 'Python, LLMs, Git Hooks', status: 'Idea'),
      IdeaModel(id: 'idea_3', title: 'Portfolio Builder for Developers', category: 'Startup', priority: 'High', description: 'Dynamic dev portfolio generator pulling directly from GitHub repos, LeetCode, and Medium.', technologies: 'Next.js, TailwindCSS, GitHub API', status: 'Research'),
    ];
    for (var i in ideas) {
      await db.insert('ideas', i.toMap());
    }

    // 12. Resources & Bookmarks
    final resources = [
      ResourceModel(id: 'res_1', title: 'Official Flutter Documentation', url: 'https://docs.flutter.dev', category: 'Documentation', description: 'Best reference for Flutter widgets and architectural patterns', tags: 'Flutter, Dart', isFavorite: true),
      ResourceModel(id: 'res_2', title: 'NeetCode 150 Roadmaps', url: 'https://neetcode.io/roadmap', category: 'Interview', description: 'Step by step DSA learning path with video explanations', tags: 'DSA, LeetCode', isFavorite: true),
      ResourceModel(id: 'res_3', title: 'System Design Primer', url: 'https://github.com/donnemartin/system-design-primer', category: 'GitHub', description: 'Learn how to build large-scale systems', tags: 'Architecture, Backend', isFavorite: false),
    ];
    for (var r in resources) {
      await db.insert('resources', r.toMap());
    }

    // 13. Interview Prep Questions
    final questions = [
      InterviewQuestionModel(
        id: 'q_1',
        technology: 'Flutter',
        question: 'What is the difference between Stateless and Stateful Widgets?',
        answer: 'A StatelessWidget never changes during runtime. Its appearance and properties remain fixed once built.\nA StatefulWidget has mutable state stored in a State object that can be updated dynamically via setState(), triggering a rebuild of the widget subtree.',
        difficulty: 'Easy',
        isMastered: true,
      ),
      InterviewQuestionModel(
        id: 'q_2',
        technology: 'Flutter',
        question: 'Explain the Flutter Build Lifecycle (initState, build, dispose).',
        answer: '1. createState(): Instantiates the mutable State object.\n2. initState(): Called once when State is inserted into tree. Ideal for one-time listeners and subscriptions.\n3. didChangeDependencies(): Called when inherited widgets change.\n4. build(): Pure function returning the widget tree.\n5. dispose(): Clean up controllers, streams, and animations when the widget is permanently removed.',
        difficulty: 'Medium',
        isMastered: true,
      ),
      InterviewQuestionModel(
        id: 'q_3',
        technology: 'Python',
        question: 'What are Decorators and how do they work in Python?',
        answer: 'Decorators are functions that take another function as an argument, extend or modify its behavior without modifying the original code, and return a new callable. They use the @decorator syntax and syntactic sugar over f = decorator(f).',
        difficulty: 'Medium',
        isMastered: false,
      ),
      InterviewQuestionModel(
        id: 'q_4',
        technology: 'DSA',
        question: 'How do you detect a cycle in a Linked List?',
        answer: 'Use Floyd’s Cycle-Finding Algorithm (Tortoise and Hare). Maintain two pointers: slow moves 1 step at a time, fast moves 2 steps. If there is a cycle, slow and fast will eventually meet (slow == fast). If fast reaches null, no cycle exists. Time: O(N), Space: O(1).',
        difficulty: 'Easy',
        isMastered: true,
      ),
    ];
    for (var q in questions) {
      await db.insert('interview_questions', q.toMap());
    }

    final mockInterview = MockInterviewLogModel(
      id: 'mock_1',
      company: 'TCS Prime Mock Round',
      date: now.subtract(const Duration(days: 4)),
      questionsAsked: 'Flutter state management, BLoC vs Riverpod, SQL Indexing, Array manipulation',
      performanceRating: 8,
      thingsToImprove: 'Explain BLoC event-to-state stream mapping more concisely; practice SQL group by with having clause.',
    );
    await db.insert('mock_interviews', mockInterview.toMap());

    // 14. Journal
    final journal = JournalModel(
      id: 'j_1',
      date: now,
      mood: 'Great',
      whatHappened: 'Completed LifeOS local SQLite architecture and modularized the entire personal command center.',
      whatLearned: 'Deep-dived into Flutter FFI database drivers and reactive cross-module communication.',
      wentWell: 'Maintained high focus for 6+ hours and reached a 12-day coding streak!',
      couldImprove: 'Spend 30 minutes on DSA graph problems tomorrow morning before jumping into frontend styling.',
    );
    await db.insert('journals', journal.toMap());

    // 15. Documents Vault
    final documents = [
      DocumentModel(id: 'doc_1', title: 'BCA Final Marksheet', type: 'Education', year: '2026', status: 'Available', identifierNo: 'BCA-2026-9842', notes: 'First Division with Honors'),
      DocumentModel(id: 'doc_2', title: 'Senior Secondary (12th) Certificate', type: 'Education', year: '2023', status: 'Verified', identifierNo: 'CBSE-12-84920'),
      DocumentModel(id: 'doc_3', title: 'Passport', type: 'Identity', year: '2024', status: 'Verified', expiryDate: now.add(const Duration(days: 365 * 8)), notes: 'Valid till 2034'),
      DocumentModel(id: 'doc_4', title: 'Swiggy SDE Offer Letter', type: 'Employment', year: '2026', status: 'Available', notes: 'Joining date: November 2026'),
    ];
    for (var doc in documents) {
      await db.insert('documents', doc.toMap());
    }

    // 16. Subscriptions
    final subscriptions = [
      SubscriptionModel(id: 'sub_1', name: 'Netflix Premium (4K)', amount: 649, billingCycle: 'Monthly', nextBillingDate: now.add(const Duration(days: 18)), category: 'Entertainment'),
      SubscriptionModel(id: 'sub_2', name: 'Spotify Individual', amount: 119, billingCycle: 'Monthly', nextBillingDate: now.add(const Duration(days: 1)), category: 'Entertainment'),
      SubscriptionModel(id: 'sub_3', name: 'Google One Cloud Storage (100GB)', amount: 130, billingCycle: 'Monthly', nextBillingDate: now.add(const Duration(days: 4)), category: 'Cloud & Tech'),
      SubscriptionModel(id: 'sub_4', name: 'Developer Domain (harsh.dev)', amount: 999, billingCycle: 'Yearly', nextBillingDate: now.add(const Duration(days: 140)), category: 'Cloud & Tech'),
    ];
    for (var sub in subscriptions) {
      await db.insert('subscriptions', sub.toMap());
    }

    // 17. Wishlist
    final wishlist = [
      WishlistItemModel(id: 'w_1', title: 'Apple MacBook Pro M3', price: 145000, priority: 'High', category: 'Tech', url: 'https://apple.com'),
      WishlistItemModel(id: 'w_2', title: 'Sony WH-1000XM5 Headphones', price: 26990, priority: 'Medium', category: 'Tech', url: 'https://sony.co.in'),
      WishlistItemModel(id: 'w_3', title: 'Ergonomic Desk Chair', price: 12500, priority: 'Medium', category: 'Home'),
      WishlistItemModel(id: 'w_4', title: 'Mechanical Keyboard (Keychron K2)', price: 7999, priority: 'Low', category: 'Tech', isPurchased: true),
    ];
    for (var w in wishlist) {
      await db.insert('wishlist', w.toMap());
    }

    // 18. Inventory
    final inventory = [
      InventoryItemModel(id: 'inv_1', name: 'Primary Laptop (Dell XPS 15)', category: 'Electronics', price: 120000, purchaseDate: now.subtract(const Duration(days: 300)), warrantyExpiry: now.add(const Duration(days: 65)), serialNumber: 'DXPS-9520-4829', notes: 'Under Dell Premium Support'),
      InventoryItemModel(id: 'inv_2', name: 'Smartphone (OnePlus 12)', category: 'Electronics', price: 64999, purchaseDate: now.subtract(const Duration(days: 120)), warrantyExpiry: now.add(const Duration(days: 245)), serialNumber: 'OP12-884920'),
      InventoryItemModel(id: 'inv_3', name: 'LG 27-inch 4K Monitor', category: 'Electronics', price: 28000, purchaseDate: now.subtract(const Duration(days: 200)), serialNumber: 'LG27UL-8594'),
    ];
    for (var inv in inventory) {
      await db.insert('inventory', inv.toMap());
    }

    // 19. Secure Vault
    final secureItems = [
      SecureItemModel(id: 'sec_1', title: 'Home 5GHz Wi-Fi', category: 'Wi-Fi', secretValue: 'UltraSpeed@2026#Secure', secondaryValue: 'FiberHome_5G', notes: 'WPA3 Personal'),
      SecureItemModel(id: 'sec_2', title: 'Google Gemini Pro API Key', category: 'API Key', secretValue: 'AIzaSyA889342_SecretDemoKeyValid', notes: 'Personal development environment key'),
      SecureItemModel(id: 'sec_3', title: 'GitHub Personal Access Token', category: 'Credentials', secretValue: 'ghp_88492049284918294829104829', secondaryValue: 'harsh-dev', notes: 'Repo and workflow scopes'),
    ];
    for (var sec in secureItems) {
      await db.insert('secure_items', sec.toMap());
    }

    // 20. Notes
    final notes = [
      NoteModel(id: 'n_1', title: 'Flutter State Optimization Cheatsheet', content: '1. Use const constructors wherever possible to avoid unnecessary rebuilds.\n2. Isolate rebuilds with Builder or ValueListenableBuilder.\n3. Cache expensive computations with compute() or worker isolates.\n4. Avoid placing heavy logic in build() methods.', category: 'Code', isPinned: true, colorHex: '0xFF6366F1'),
      NoteModel(id: 'n_2', title: 'Tech Stack Decisions for 2026', content: 'Focus on Flutter for cross-platform desktop & mobile; FastAPI / Laravel for reliable backend microservices; SQLite for bulletproof offline-first storage.', category: 'Ideas', isPinned: false),
    ];
    for (var n in notes) {
      await db.insert('notes', n.toMap());
    }

    // 21. Important Dates
    final importantDates = [
      ImportantDateModel(id: 'date_1', title: 'Document Submission Deadline', date: now.add(const Duration(days: 11)), category: 'Deadline', reminderTime: '10:00 AM', notes: 'Submit BCA marksheets & address proof'),
      ImportantDateModel(id: 'date_2', title: 'Google Technical Interview', date: now.add(const Duration(days: 5)), category: 'Interview', reminderTime: '02:00 PM', notes: 'Round 1: DSA + Flutter Architecture'),
      ImportantDateModel(id: 'date_3', title: 'Spotify Subscription Renewal', date: now.add(const Duration(days: 1)), category: 'Payment', reminderTime: '12:00 PM', notes: '₹119 via UPI autopay'),
    ];
    for (var d in importantDates) {
      await db.insert('important_dates', d.toMap());
    }
  }
}
