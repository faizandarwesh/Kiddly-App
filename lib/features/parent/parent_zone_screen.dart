import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Privacy',
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Text(
          'This app is designed for children. It works fully offline, collects '
          'no personal data, contains no ads, and has no external links or '
          'purchases. All profiles and progress stay on this device.',
          style: TextStyle(color: Colors.black54, height: 1.4),
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
