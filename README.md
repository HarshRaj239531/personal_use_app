# LifeOS — Personal Command Center & Operating System

> **100% Private • Local SQLite Database • 100% Offline Gemma 4 AI Copilot • Zero Cloud Dependency**

LifeOS is an all-in-one personal operating system designed exclusively for personal mastery, career development, financial tracking, and productivity. Built with **Flutter**, native **SQLite (`life_os.db`)**, Google Fonts (**Plus Jakarta Sans**), and an integrated **Gemma 4 on-device AI**.

---

## ⚡ Key Highlights

- **🔒 100% Offline & Private**: No data ever leaves your device. Database runs entirely in native SQLite.
- **🤖 Gemma 4 AI Copilot**:
  - **Local Model**: `gemma-4-E4B-it-Q4_K_M.gguf` (4.97 GB) located at `C:\Users\hr529\.lmstudio\models\lmstudio-community\gemma-4-E4B-it-GGUF\gemma-4-E4B-it-Q4_K_M.gguf`.
  - **Dual-Engine Architecture**:
    1. **Localhost Server**: Connects to LM Studio, llama.cpp, or Ollama local inference endpoint without internet.
    2. **On-Device RAG Engine**: Zero network required. Deeply analyzes your real SQLite tasks, expenses, study velocity, habit streaks, and goals on Android & Windows.
- **📱 Cross-Platform Ready**: Runs seamlessly on Windows Desktop (`life_os.exe`) and Android mobile (`flutter run -d android`).
- **🎨 Luxury Cyber-Dark UI**: Glassmorphism cards, glowing status badges, high-contrast typography, and smooth micro-animations.

---

## 🚀 All 27 Modules

### 1. Core Productivity
- **Command Dashboard & Daily Brief**: Real-time heuristic summary of your day, active streaks, pending items, and 1-tap Gemma AI suggestions.
- **Expense & Budget Tracker**: Inflow, outflow, monthly budgets, and categorical breakdown.
- **Study & Learning Tracker**: Subject logs with 1–5 star ratings (automatically levels up matching skills).
- **Time Tracker & Pomodoro**: Digital stopwatch and countdown timer linked to your projects and study topics.
- **Todo & Task Management**: High/Medium/Low priorities, tags, and reactive OKR linking.
- **Notes & Memos**: Searchable thoughts, code snippets, and 1-tap save from Gemma AI.
- **Goals & OKRs**: Hierarchical objectives broken down into measurable Key Results.
- **Habit Tracker**: Daily habits with a 7-day streak matrix.

### 2. Developer & Career Suite
- **Job Tracker**: Full recruitment pipeline (Applied, Assessment, Interview, Offer, Package/CTC).
- **Skills Matrix**: Hard skills competency meters (levels up from completed study sessions).
- **Project Manager**: Personal coding projects with GitHub repo links and tech stacks.
- **Bug Tracker (Mini Jira)**: Issue tracking with severity and status.
- **Idea Bank**: App concepts and startup ideas.
- **Resource Library**: Bookmarked documentation, courses, and repos.
- **Interview Prep**: Flashcard question bank and mock technical interview scoring.

### 3. Personal Life & Security
- **Daily Journal**: 4 structured reflection prompts with mood tracking.
- **Document Vault**: Registry for academic certificates, degrees, and passports.
- **Subscriptions Tracker**: Recurring services and monthly burn rate.
- **Shopping Wishlist**: Target purchases with priority tags.
- **Personal Inventory**: Hardware and asset tracker with warranty alerts.
- **Secure Vault**: PIN-locked storage for passwords, API keys, and recovery codes.

### 4. Utilities & Analytics
- **Unified Life Calendar**: Aggregated timeline of tasks, interviews, and renewals.
- **8-in-1 Calculators**: EMI, In-Hand Salary, GST, Percentage, and Discount tools.
- **Productivity Analytics**: LifeOS index, financial trends, and learning velocity charts.
- **Settings & DB Backup**: JSON export/import and dark mode customization.

---

## 🛠️ How to Run

### Windows Desktop (Already Compiled & Tested)
```bash
# Debug run
flutter run -d windows

# Or launch the direct native binary:
.\build\windows\x64\runner\Debug\life_os.exe
```

### Android Mobile (Offline Mode)
```bash
# Connect your Android phone via USB (with USB debugging enabled)
flutter devices

# Run on your phone
flutter run -d <device-id>
```
*Note: On mobile, LifeOS runs 100% offline out-of-the-box using the internal on-device RAG engine. If connected to home Wi-Fi, you can also point the local server IP to your PC's IP (e.g., `http://192.168.1.X:1234/v1`) in the Gemma settings.*

---

## 📁 Database Architecture
- **Location**: `C:\Users\hr529\AppData\Roaming\com.lifeos\life_os\life_os.db`
- **Driver**: Native SQLite FFI with WAL (Write-Ahead Logging) enabled.
