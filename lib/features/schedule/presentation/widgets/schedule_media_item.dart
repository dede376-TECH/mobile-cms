// schedule_media_item.dart - Widget ligne média
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/schedule.dart';
import '../../../media/domain/models/media_item.dart';
import '../../../media/presentation/providers/media_provider.dart';

class ScheduleMediaItem extends ConsumerWidget {
  final ScheduledMedia scheduledMedia;

  const ScheduleMediaItem({super.key, required this.scheduledMedia});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref
        .read(mediaProviderRef)
        .mediaItems
        .firstWhere(
          (m) => m.id == scheduledMedia.mediaId,
          orElse: () => MediaItem(
            id: scheduledMedia.mediaId,
            name: 'Média inconnu',
            filePath: '',
            type: MediaType.image,
            createdAt: DateTime.now(),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        children: [
          Icon(
            mediaItem.type == MediaType.image ? Icons.image : Icons.videocam,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${scheduledMedia.order + 1}. ${mediaItem.name}',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${scheduledMedia.duration}s',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
