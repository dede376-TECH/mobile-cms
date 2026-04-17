// player_status_indicator.dart - Badge statut (réutilisable)
import 'package:flutter/material.dart';
import '../../../app_core_ui/domain/models/app_models.dart';

/// Badge circulaire indiquant le statut d'un player.
class PlayerStatusIndicator extends StatelessWidget {
  final PlayerStatus status;

  const PlayerStatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon, tooltip) = _resolve(status);

    return Tooltip(
      message: tooltip,
      child: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  (Color, IconData, String) _resolve(PlayerStatus s) {
    switch (s) {
      case PlayerStatus.online:
        return (Colors.green, Icons.check_circle, 'En ligne');
      case PlayerStatus.offline:
        return (Colors.grey, Icons.cancel, 'Hors ligne');
      case PlayerStatus.playing:
        return (Colors.blue, Icons.play_circle, 'En lecture');
      case PlayerStatus.error:
        return (Colors.red, Icons.error, 'Erreur');
    }
  }
}