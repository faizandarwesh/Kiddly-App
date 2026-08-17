import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/audio_service.dart';
import 'core/services/profile_service.dart';
import 'core/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide the system bars for an immersive, distraction-free playground.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Load persisted state before the first frame so rewards/settings are ready.
  await SettingsService.instance.load();
  await ProfileService.instance.load();
  await AudioService.instance.init();

  runApp(const KiddlyApp());
}
