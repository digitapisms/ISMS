import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/library_providers.dart';
import '../../domain/digital_resource.dart';
import '../../domain/digital_resource_annotation.dart';
import '../../domain/digital_resource_progress.dart';
import '../../domain/annotation_reply.dart';
import '../widgets/annotation_dialog.dart';

class DigitalResourceViewerScreen extends ConsumerStatefulWidget {
  const DigitalResourceViewerScreen({super.key, required this.resourceId});

  final String resourceId;

  @override
  ConsumerState<DigitalResourceViewerScreen> createState() =>
      _DigitalResourceViewerScreenState();
}

class _DigitalResourceViewerScreenState
    extends ConsumerState<DigitalResourceViewerScreen> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(1);
  final ValueNotifier<bool> _showAnnotations = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _showProgress = ValueNotifier<bool>(true);
  final Map<String, bool> _expandedAnnotations = {};
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _replyingToAnnotations = {};

  @override
  void initState() {
    super.initState();
    _loadInitialProgress();
  }

  Future<void> _loadInitialProgress() async {
    final progress = await ref
        .read(libraryRepositoryProvider)
        .getProgress(widget.resourceId);
    if (progress != null && mounted) {
      _currentPage.value = progress.currentPage;
      _pageController.jumpToPage(progress.currentPage - 1);
    }
  }

  Future<void> _updateProgress(int page) async {
    final totalPages = 10; // This should come from the resource metadata
    final percentage = (page / totalPages) * 100;

    try {
      await ref
          .read(libraryRepositoryProvider)
          .updateProgress(
            resourceId: widget.resourceId,
            currentPage: page,
            percentageCompleted: percentage,
            timeSpentSeconds: 10, // Increment by time spent on page
          );
    } catch (error) {
      // Handle error silently
    }
  }

  Future<void> _addAnnotation(AnnotationType type, String content) async {
    try {
      await ref
          .read(libraryRepositoryProvider)
          .createAnnotation(
            resourceId: widget.resourceId,
            annotationType: type,
            content: content,
            pageNumber: _currentPage.value,
          );

      // Update annotation counts in progress
      await ref
          .read(libraryRepositoryProvider)
          .updateAnnotationCounts(widget.resourceId);

      // Refresh annotations
      ref.invalidate(digitalResourceAnnotationsProvider(widget.resourceId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\${type.displayName} added successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add annotation: \$error')),
      );
    }
  }

  Future<void> _bookmarkPage(int page) async {
    final progress = await ref
        .read(libraryRepositoryProvider)
        .getProgress(widget.resourceId);

    if (progress != null) {
      final bookmarks = List<int>.from(progress.bookmarkedPages);
      if (bookmarks.contains(page)) {
        bookmarks.remove(page);
      } else {
        bookmarks.add(page);
      }

      await ref
          .read(libraryRepositoryProvider)
          .updateProgress(
            resourceId: widget.resourceId,
            bookmarkedPages: bookmarks,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookmarks.contains(page)
                ? 'Page \$page bookmarked'
                : 'Page \$page removed from bookmarks',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resourceAsync = ref.watch(
      digitalResourcesProvider.select(
        (resources) => resources.value?.firstWhere(
          (r) => r.id == widget.resourceId,
          orElse: () => throw Exception('Resource not found'),
        ),
      ),
    );

    final annotationsAsync = ref.watch(
      digitalResourceAnnotationsProvider(widget.resourceId),
    );

    final progressAsync = ref.watch(
      digitalResourceProgressProvider(widget.resourceId),
    );

    return Scaffold(
      appBar: AppBar(
        title: resourceAsync.when(
          data: (resource) => Text(resource.title),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Digital Resource'),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _currentPage,
            builder: (context, page, _) {
              return IconButton(
                icon: const Icon(Icons.bookmark),
                onPressed: () => _bookmarkPage(page),
                tooltip: 'Bookmark this page',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: () => _showAddAnnotationDialog(AnnotationType.note),
            tooltip: 'Add note',
          ),
          IconButton(
            icon: const Icon(Icons.highlight),
            onPressed: () => _showAddAnnotationDialog(AnnotationType.highlight),
            tooltip: 'Add highlight',
          ),
          IconButton(
            icon: const Icon(Icons.question_answer),
            onPressed: () => _showAddAnnotationDialog(AnnotationType.question),
            tooltip: 'Ask question',
          ),
        ],
      ),
      body: resourceAsync.when(
        data: (resource) =>
            _buildResourceViewer(resource, annotationsAsync, progressAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading resource',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(digitalResourcesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceViewer(
    DigitalResource resource,
    AsyncValue<List<DigitalResourceAnnotation>> annotationsAsync,
    AsyncValue<DigitalResourceProgress?> progressAsync,
  ) {
    return Column(
      children: [
        // Progress bar
        ValueListenableBuilder<bool>(
          valueListenable: _showProgress,
          builder: (context, showProgress, _) {
            if (!showProgress) return const SizedBox.shrink();
            return progressAsync.when(
              data: (progress) => LinearProgressIndicator(
                value: progress?.percentageCompleted / 100 ?? 0.0,
                backgroundColor: Colors.grey[300],
                minHeight: 4,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),

        // Main content area
        Expanded(
          child: Row(
            children: [
              // Resource content (simulated)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (page) {
                        _currentPage.value = page + 1;
                        _updateProgress(page + 1);
                      },
                      itemCount: 10, // Simulated pages
                      itemBuilder: (context, pageIndex) {
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\${resource.title} - Page \${pageIndex + 1}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'This is simulated content for page \${pageIndex + 1}. '
                                'In a real implementation, this would display the actual '
                                'digital resource content (PDF, video, audio, etc.)',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 24),
                              if (pageIndex == 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Resource Information:',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Type: \${resource.resourceType.displayName}',
                                    ),
                                    Text(
                                      'File Size: \${resource.fileSizeFormatted}',
                                    ),
                                    if (resource.description != null)
                                      Text(
                                        'Description: \${resource.description}',
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Annotations sidebar
              ValueListenableBuilder<bool>(
                valueListenable: _showAnnotations,
                builder: (context, showAnnotations, _) {
                  if (!showAnnotations) return const SizedBox.shrink();
                  return SizedBox(
                    width: 300,
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Text(
                                  'Annotations',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      _showAnnotations.value = false,
                                  iconSize: 18,
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: annotationsAsync.when(
                              data: (annotations) {
                                final pageAnnotations = annotations
                                    .where(
                                      (a) => a.pageNumber == _currentPage.value,
                                    )
                                    .toList();

                                if (pageAnnotations.isEmpty) {
                                  return const Center(
                                    child: Text('No annotations for this page'),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: pageAnnotations.length,
                                  itemBuilder: (context, index) {
                                    final annotation = pageAnnotations[index];
                                    return _buildAnnotationItem(annotation);
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) =>
                                  Center(child: Text('Error: \$error')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Bottom navigation
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _currentPage,
                builder: (context, page, _) {
                  return Text('Page \$page of 10');
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<bool>(
                valueListenable: _showAnnotations,
                builder: (context, showAnnotations, _) {
                  return IconButton(
                    icon: Icon(
                      showAnnotations ? Icons.chat : Icons.chat_bubble_outline,
                    ),
                    onPressed: () => _showAnnotations.value = !showAnnotations,
                    tooltip: showAnnotations
                        ? 'Hide annotations'
                        : 'Show annotations',
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _showProgress,
                builder: (context, showProgress, _) {
                  return IconButton(
                    icon: Icon(
                      showProgress ? Icons.bar_chart : Icons.bar_chart_outlined,
                    ),
                    onPressed: () => _showProgress.value = !showProgress,
                    tooltip: showProgress ? 'Hide progress' : 'Show progress',
                  );
                },
              ),
              progressAsync.when(
                data: (progress) {
                  if (progress == null) return const SizedBox.shrink();
                  return Row(
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 4),
                      Text(progress.timeSpentFormatted),
                      const SizedBox(width: 16),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(size: 16),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddAnnotationDialog(AnnotationType type) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AnnotationDialog(annotationType: type),
    );

    if (result != null && result.isNotEmpty) {
      await _addAnnotation(type, result);
    }
  }

  Widget _buildAnnotationItem(DigitalResourceAnnotation annotation) {
    final repliesAsync = ref.watch(annotationRepliesProvider(annotation.id));
    final isExpanded = _expandedAnnotations[annotation.id] ?? false;
    final isReplying = _replyingToAnnotations[annotation.id] ?? false;

    if (!_replyControllers.containsKey(annotation.id)) {
      _replyControllers[annotation.id] = TextEditingController();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        key: ValueKey(annotation.id),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          _expandedAnnotations[annotation.id] = expanded;
        },
        leading: Icon(_getAnnotationIcon(annotation.annotationType)),
        title: Text(annotation.content),
        subtitle: Text(
          '\${annotation.annotationType.displayName} • \${_formatDate(annotation.createdAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply count
            repliesAsync.when(
              data: (replies) {
                if (replies.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('\${replies.length}'),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Like button
            if (annotation.likesCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text('\${annotation.likesCount}'),
              ),
            IconButton(
              icon: const Icon(Icons.thumb_up, size: 16),
              onPressed: () => _likeAnnotation(annotation.id),
            ),

            // Reply button
            IconButton(
              icon: const Icon(Icons.reply, size: 16),
              onPressed: () => _toggleReplying(annotation.id),
            ),
          ],
        ),
        children: [
          // Reply input field (when replying)
          if (isReplying)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyControllers[annotation.id],
                      decoration: const InputDecoration(
                        hintText: 'Write a reply...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final content = _replyControllers[annotation.id]!.text
                          .trim();
                      if (content.isNotEmpty) {
                        _addReply(annotation.id, content);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _toggleReplying(annotation.id),
                  ),
                ],
              ),
            ),

          // Replies list
          repliesAsync.when(
            data: (replies) {
              if (replies.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No replies yet'),
                );
              }

              return Column(
                children: replies
                    .map((reply) => _buildReplyItem(reply))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading replies: \$error'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(AnnotationReply reply) {
    final likesCountAsync = ref.watch(
      annotationReplyLikesCountProvider(reply.id),
    );
    final hasLikedAsync = ref.watch(
      hasUserLikedAnnotationReplyProvider(reply.id),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Colors.grey[50],
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const Icon(Icons.reply, size: 16, color: Colors.grey),
        title: Text(reply.content),
        subtitle: Text('Reply • \${_formatDate(reply.createdAt)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Like count
            likesCountAsync.when(
              data: (count) {
                if (count > 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('\$count'),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Like button
            hasLikedAsync.when(
              data: (hasLiked) => IconButton(
                icon: Icon(
                  hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 16,
                  color: hasLiked ? Colors.blue : null,
                ),
                onPressed: () => _likeReply(reply.id),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _likeAnnotation(String annotationId) async {
    try {
      await ref.read(libraryRepositoryProvider).likeAnnotation(annotationId);
      ref.invalidate(digitalResourceAnnotationsProvider(widget.resourceId));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like annotation: \$error')),
      );
    }
  }

  Future<void> _addReply(String annotationId, String content) async {
    try {
      await ref
          .read(libraryRepositoryProvider)
          .createAnnotationReply(annotationId: annotationId, content: content);

      // Refresh replies
      ref.invalidate(annotationRepliesProvider(annotationId));

      // Clear reply controller
      _replyControllers[annotationId]?.clear();
      _replyingToAnnotations[annotationId] = false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply added successfully')));
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add reply: \$error')));
    }
  }

  Future<void> _likeReply(String replyId) async {
    try {
      await ref.read(libraryRepositoryProvider).likeAnnotationReply(replyId);

      // Refresh the specific reply
      ref.invalidate(annotationReplyProvider(replyId));
      ref.invalidate(annotationReplyLikesCountProvider(replyId));
      ref.invalidate(hasUserLikedAnnotationReplyProvider(replyId));
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to like reply: \$error')));
    }
  }

  void _toggleAnnotationExpansion(String annotationId) {
    setState(() {
      _expandedAnnotations[annotationId] =
          !(_expandedAnnotations[annotationId] ?? false);

      // Initialize reply controller if not exists
      if (!_replyControllers.containsKey(annotationId)) {
        _replyControllers[annotationId] = TextEditingController();
      }
    });
  }

  void _toggleReplying(String annotationId) {
    setState(() {
      _replyingToAnnotations[annotationId] =
          !(_replyingToAnnotations[annotationId] ?? false);

      // Initialize reply controller if not exists
      if (!_replyControllers.containsKey(annotationId)) {
        _replyControllers[annotationId] = TextEditingController();
      }

      // Expand annotation when replying
      if (_replyingToAnnotations[annotationId] == true) {
        _expandedAnnotations[annotationId] = true;
      }
    });
  }

  IconData _getAnnotationIcon(AnnotationType type) {
    switch (type) {
      case AnnotationType.note:
        return Icons.note;
      case AnnotationType.highlight:
        return Icons.highlight;
      case AnnotationType.comment:
        return Icons.comment;
      case AnnotationType.question:
        return Icons.question_answer;
      case AnnotationType.answer:
        return Icons.check_circle;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '\${date.day}/\${date.month}/\${date.year}';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    _showAnnotations.dispose();
    _showProgress.dispose();

    // Dispose all reply controllers
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }
}
