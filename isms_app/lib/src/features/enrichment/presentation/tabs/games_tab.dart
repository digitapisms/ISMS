import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/enrichment_providers.dart';
import '../../domain/game.dart';
import '../screens/game_play_screen.dart';

class GamesTab extends ConsumerWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider);

    return gamesAsync.when(
      data: (games) {
        if (games.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_esports_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No games available',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Games will appear here when added',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return _GameCard(game: game);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load games',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(gamesProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends ConsumerWidget {
  final Game game;

  const _GameCard({required this.game});

  void _playGame(BuildContext context, WidgetRef ref, Game game) async {
    try {
      final repo = ref.read(enrichmentRepositoryProvider);
      final studentId = await repo.getCurrentStudentId();

      if (studentId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student profile not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create game session
      final sessionId = await repo.createGameSession(
        gameId: game.id,
        studentId: studentId,
      );

      if (context.mounted) {
        if (game.gameType == GameType.embeddedUrl && game.gameUrl != null) {
          // Navigate to game play screen for embedded games
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  GamePlayScreen(game: game, sessionId: sessionId),
            ),
          );
        } else if (game.gameType == GameType.external && game.gameUrl != null) {
          // Open external URL - show message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${game.title} in browser...')),
          );
        } else {
          // Built-in games - show placeholder
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Playing ${game.title}')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () {
          _playGame(context, ref, game);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.sports_esports,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                game.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (game.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  game.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (game.subjectTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: game.subjectTags.take(2).map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: 10),
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
