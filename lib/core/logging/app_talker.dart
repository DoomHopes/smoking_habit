import 'package:talker_flutter/talker_flutter.dart';

/// Централизованный экземпляр логгера Talker для всего приложения.
final Talker talker = TalkerFlutter.init(
  settings: TalkerSettings(
    useConsoleLogs: true,
    maxHistoryItems: 200,
  ),
);
