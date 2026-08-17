import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/settings_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';

/// The adult-facing area (reached only through the hold-gate): sound settings,
/// child profiles and a light progress view. Deliberately plain and text-based
/// — this screen is for grown-ups, not children.
class ParentZoneScreen extends StatelessWidget {
  const ParentZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Parent Zone'),
        backgroundColor: AppColors.grape,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SoundSettings(),
          SizedBox(height: 24),
          _ProfilesSection(),
          SizedBox(height: 24),
          _PrivacyNote(),
        ],
      ),
    );
  }
}

class _SoundSettings extends StatelessWidget {
  const _SoundSettings();

  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;
    return _Card(
      title: 'Sound',
      child: AnimatedBuilder(
        animation: s,
        builder: (context, _) => Column(
          children: [
            SwitchListTile(
              title: const Text('Sound effects'),
              value: s.soundOn,
              onChanged: s.setSound,
            ),
            SwitchListTile(
              title: const Text('Music'),
              value: s.musicOn,
              onChanged: s.setMusic,
            ),
            SwitchListTile(
              title: const Text('Voice narration'),
              value: s.voiceOn,
              onChanged: s.setVoice,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilesSection extends StatelessWidget {
  const _ProfilesSection();

  @override
  Widget build(BuildContext context) {
    final ps = ProfileService.instance;
    return _Card(
      title: 'Children',
      child: AnimatedBuilder(
        animation: ps,
        builder: (context, _) {
          return Column(
            children: [
              for (final p in ps.profiles)
                ListTile(
                  leading: Text(p.avatar, style: const TextStyle(fontSize: 30)),
                  title: Text(p.name),
                  subtitle: Text(
                      '⭐ ${p.stars}   🌈 ${p.rainbows}   💖 ${p.hearts}   •   ${p.completed.length} activities'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ps.active?.id == p.id)
                        const Icon(Icons.check_circle,
                            color: AppColors.grassDeep)
                      else
                        TextButton(
                          onPressed: () => ps.setActive(p.id),
                          child: const Text('Use'),
                        ),
                      if (ps.profiles.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ps.removeProfile(p.id),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.grape),
                  icon: const Icon(Icons.add),
                  label: const Text('Add child'),
                  onPressed: () => _addChild(context, ps),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addChild(BuildContext context, ProfileService ps) async {
    final controller = TextEditingController();
    String avatar = '🐰';
    const avatars = ['🐰', '🐻', '🐱', '🐶', '🦊', '🐨', '🦁', '🐸'];
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New child'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final a in avatars)
                    GestureDetector(
                      onTap: () => setState(() => avatar = a),
                      child: CircleAvatar(
                        backgroundColor: avatar == a
                            ? AppColors.grape.withValues(alpha: 0.3)
                            : Colors.transparent,
                        child: Text(a, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) ps.addProfile(name, avatar);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  /// The hosted policy. Kept in one place so the store listing, the Play
  /// Console entry and the app can never drift apart.
  static final Uri _policyUrl =
      Uri.parse('https://kiddly-privacy-policy.vercel.app/');

  /// Opens the policy in the device's browser rather than an in-app web view.
  /// [LaunchMode.externalApplication] is deliberate: an embedded web view would
  /// keep the child inside the app with a browser they cannot navigate out of,
  /// which is exactly what Play's Families policy asks us to avoid.
  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // A device with no browser makes launchUrl return false on some platforms
    // and throw on others — neither should ever crash the Parent Zone, so we
    // fall back to showing the address for the parent to type in by hand.
    var ok = false;
    try {
      ok = await launchUrl(_policyUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open a browser. Visit $_policyUrl')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Privacy',
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This app is designed for children. It works fully offline, '
              'collects no personal data, contains no ads and no purchases. '
              'All profiles and progress stay on this device.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _open(context),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Read the full Privacy Policy'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.grape,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const Text(
              'Opens in your browser.',
              style: TextStyle(color: Colors.black38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
