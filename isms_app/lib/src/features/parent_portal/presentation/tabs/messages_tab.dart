import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../messaging/presentation/tabs/conversations_tab.dart';

class MessagesTab extends ConsumerWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reuse the messaging conversations tab
    return const ConversationsTab();
  }
}

