# Streakly

Streakly is a Modern, **Local-First** Habit Tracker built with Flutter.

## Features

- **Local Storage**: All data is stored securely on your device using Hive. No account required.
- **Habit Tracking**: Create, track, and manage your daily habits.
- **Notes**: Add notes to your habits to track progress details.
- **Privacy Focused**: Your data stays with you.
- **Customizable**: Set reminders (coming soon), icons, and colors.
- **Widgets**: Home screen widgets for quick access.

## Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

## Architecture

This project was migrated from a cloud-based (Supabase) architecture to a fully local one.
- **State Management**: Provider
- **Storage**: Hive (NoSQL)
- **Notifications**: Flutter Local Notifications (In Progress)
