import 'package:shared_preferences/shared_preferences.dart';

/// Preferences that affect the local practice experience on this device.
class AppPreferences {
  static const _noteTypeKey = 'preferencia_nome_notas';
  static const _labelsKey = 'preferencia_rotulos_teclado';
  static const _bpmKey = 'preferencia_bpm';
  static const _catalogInstrumentKey = 'preferencia_instrumento_catalogo';
  static const _reminderEnabledKey = 'lembrete_diario_ativo';
  static const _reminderHourKey = 'lembrete_diario_hora';
  static const _reminderMinuteKey = 'lembrete_diario_minuto';

  static Future<String> noteType() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_noteTypeKey) ?? 'solfejo';
  }

  static Future<void> setNoteType(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_noteTypeKey, value);
  }

  static Future<bool> showKeyboardLabels() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_labelsKey) ?? true;
  }

  static Future<void> setShowKeyboardLabels(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_labelsKey, value);
  }

  static Future<int> defaultBpm() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_bpmKey) ?? 80;
  }

  static Future<void> setDefaultBpm(int value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_bpmKey, value.clamp(40, 180));
  }

  static Future<String> catalogInstrument() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_catalogInstrumentKey) ?? 'Todos';
  }

  static Future<void> setCatalogInstrument(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_catalogInstrumentKey, value);
  }

  static Future<bool> reminderEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_reminderEnabledKey) ??
      false;
  static Future<void> setReminderEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(
        _reminderEnabledKey,
        value,
      );
  static Future<({int hour, int minute})> reminderTime() async {
    final preferences = await SharedPreferences.getInstance();
    return (
      hour: preferences.getInt(_reminderHourKey) ?? 19,
      minute: preferences.getInt(_reminderMinuteKey) ?? 0,
    );
  }

  static Future<void> setReminderTime(int hour, int minute) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_reminderHourKey, hour);
    await preferences.setInt(_reminderMinuteKey, minute);
  }
}
