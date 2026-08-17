import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import 'reward_hud.dart';
import 'round_button.dart';

/// Standard chrome for an activity screen: a soft gradient sky, a top bar with
/// a big Home button and the reward tally, an optional spoken title, and the
/// activity body. Keeps navigation identical and dead-simple everywhere.
class PlayScaffold extends StatelessWidget {
  final Widget child;
  final List<Color> gradient;
  final VoidCallback? onHome;
  final String? title;
  final Widget? trailing;

  const PlayScaffold({
    super.key,
    required this.child,
    required this.gradient,
    this.onHome,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    if (onHome != null)
                      RoundButton(
                        icon: Icons.home_rounded,
                        semanticLabel: 'Home',
                        onTap: () {
                          AudioService.instance.stopVoice();
                          onHome!();
                        },
                      ),
                    const Spacer(),
                    ?trailing,
                    const SizedBox(width: 10),
                    const RewardHud(),
                  ],
                ),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 2),
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3A2E5C),
                    ),
                  ),
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
