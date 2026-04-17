import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../domain/models/media_item.dart';
import '../providers/media_provider.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../player/domain/models/player.dart';

class MediaScreen extends ConsumerWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProviderRef);
    final playersState = ref.watch(playerProviderRef);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque de Médias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(mediaProviderRef).loadMediaItems(),
          ),
        ],
      ),
      body: mediaState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : mediaState.error != null
          ? Center(child: Text('Erreur: ${mediaState.error}'))
          : mediaState.mediaItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.perm_media, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun média\nAjoutez des images ou vidéos',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.9,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: mediaState.mediaItems.length,
              itemBuilder: (context, index) {
                final media = mediaState.mediaItems[index];
                return _MediaCard(media: media, players: playersState.players);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadOptions(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  void _showUploadOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ajouter un média',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Image'),
              subtitle: const Text('JPG, PNG, GIF, WebP'),
              onTap: () {
                Navigator.pop(context);
                _showAddMediaDialog(context, ref, MediaType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: const Text('Vidéo'),
              subtitle: const Text('MP4, AVI, MOV'),
              onTap: () {
                Navigator.pop(context);
                _showAddMediaDialog(context, ref, MediaType.video);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMediaDialog(
    BuildContext context,
    WidgetRef ref,
    MediaType type,
  ) {
    ref.read(mediaProviderRef).addMediaItem(type: type);
  }
}

class _MediaCard extends ConsumerWidget {
  final MediaItem media;
  final List<Player> players;

  const _MediaCard({required this.media, required this.players});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMediaOptions(context, ref),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.type == MediaType.image)
              Image.file(
                File(media.filePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              )
            else
              const Center(
                child: Icon(Icons.videocam, size: 48, color: Colors.grey),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${media.duration}s - ${DateFormat('dd/MM').format(media.createdAt)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                radius: 18,
                child: IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: () => _showMediaOptions(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Détails'),
              onTap: () {
                Navigator.pop(context);
                _showDetailsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Envoyer à un player'),
              onTap: () {
                Navigator.pop(context);
                _showSendToPlayerDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(media.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${media.type == MediaType.image ? "Image" : "Vidéo"}'),
            Text('Durée: ${media.duration}s'),
            Text('Chemin: ${media.filePath}'),
            Text(
              'Créé le: ${DateFormat('dd/MM/yyyy HH:mm').format(media.createdAt)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showSendToPlayerDialog(BuildContext context, WidgetRef ref) {
    Player? selectedPlayer;
    if (players.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Aucun player'),
          content: Text(
            'Veuillez d\'abord ajouter un player dans l\'onglet Players.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Envoyer le média'),
            content: DropdownButtonFormField<Player>(
              value: selectedPlayer,
              items: players
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (val) => setState(() => selectedPlayer = val),
              decoration: const InputDecoration(
                labelText: 'Sélectionner un player',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: selectedPlayer == null
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await ref
                            .read(mediaProviderRef)
                            .uploadMediaToPlayer(media, selectedPlayer!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Média envoyé à ${selectedPlayer!.name}',
                              ),
                            ),
                          );
                        }
                      },
                child: const Text('Envoyer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer "${media.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(mediaProviderRef).deleteMediaItem(media.id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
