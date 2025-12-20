import 'hive_service.dart';

class PremiumService {
  static PremiumService? _instance;
  static PremiumService get instance => _instance ??= PremiumService._();

  PremiumService._();

  bool get isPremium {
    final settings = HiveService.instance.getSettings();
    return settings['isPremium'] == true;
  }

  Future<void> setPremium(bool value) async {
    final settings = HiveService.instance.getSettings();
    settings['isPremium'] = value;
    await HiveService.instance.setSettings(settings);
  }

  // Limits
  int get maxHabits => isPremium ? 9999 : 3;
  int get maxRemindersPerHabit => isPremium ? 999 : 1;
}
