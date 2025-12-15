import 'package:flutter/material.dart';

import '../../domain/game.dart';

class GamePlayScreen extends StatefulWidget {
  final Game game;
  final String sessionId;

  const GamePlayScreen({
    super.key,
    required this.game,
    required this.sessionId,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.game.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              widget.game.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (widget.game.description != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.game.description!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (widget.game.gameUrl != null)
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Open URL in browser using url_launcher
                  // For now, show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Game URL: ${widget.game.gameUrl}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Game'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              )
            else
              Text(
                'Game play interface coming soon',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }
}
