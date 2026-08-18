import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import 'round_button.dart';

/// The top bar every activity shares: a big Home button on the left, the
/// activity's name in the middle and an optional extra control on the right.
///
/// The title is deliberately allowed to *shrink* rather than overflow. Long
/// names ("Fill the Basket"), narrow phones and a parent's large-text
/// accessibility setting all used to push the old inline `Row` past the edge.
class ActivityHeader extends StatelessWidget {
  final VoidCallback onHome;

  /// The activity name. Ignored when [titleWidget] is supplied.
  final String? title;

  /// A richer title (e.g. the Numbers screen's "3 Three"). Shrunk to fit just
  /// like a plain [title].
  final Widget? titleWidget;

  final Color titleColor;

  /// Optional control on the right — a "say it again" button, a score pill…
  /// A blank space the size of the Home button is used when absent, so the
  /// title stays optically centred.
  final Widget? trailing;

  const ActivityHeader({
    super.key,
    required this.onHome,
    this.title,
    this.titleWidget,
    this.titleColor = AppColors.ink,
    this.trailing,
  }) : assert(title != null || titleWidget != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          RoundButton(
            icon: Icons.home_rounded,
            semanticLabel: 'Home',
            onTap: () {
              AudioService.instance.stopVoice();
              onHome();
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: titleWidget ??
                    Text(
                      title!,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 64),
        ],
      ),
    );
  }
}
