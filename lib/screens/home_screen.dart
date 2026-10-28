import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets/states.dart';
import 'group_screen.dart';

/// 화면 A 홈 — 내 그룹 · 지난 선택 탭 (TabBar)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Retry without setState: rebuild the screen with a fresh request.
  static void reload(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // A-1 P02 앱 이름 표시줄 — 사용자가 아는 말로
          title: const Text('Good Eats'),
          bottom: const TabBar(
            // A-2 P06 내 그룹 · 지난 선택 탭 — 두 목록을 기억하지 않아도 한 번에
            tabs: [
              Tab(icon: Icon(Icons.groups_rounded), text: 'My Groups'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Past Picks'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_GroupsTab(), _PastPicksTab()],
        ),
      ),
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      // STATE: S1 그룹 목록 → A-3 그룹 카드 (구현하지 않음)
      future: Api.groups(), // json-server GET /groups
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(message: 'Loading your groups...'); // P01
        }
        if (snap.hasError) {
          return ErrorView(
            message: 'Is the mock server running?\n(${snap.error})',
            onRetry: () => HomeScreen.reload(context),
          ); // P09
        }
        final groups = snap.data!;
        if (groups.isEmpty) {
          return const EmptyView(
            icon: Icons.group_add_rounded,
            title: 'No groups yet',
            hint: 'Ask a friend for an invite code to join a group.',
          ); // P10
        }
        return LayoutBuilder(
          builder: (context, c) {
            // Adaptive: list on phones, grid on wide screens.
            if (isWide(c)) {
              // A-5 P07 넓은 화면 그룹 격자 — 폭 700px 이상에서 카드를 나란히
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 150,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: groups.length,
                itemBuilder: (_, i) => _GroupCard(group: groups[i]),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _GroupCard(group: groups[i]),
            );
          },
        );
      },
    );
  }
}

/// A-3 P08 그룹 카드 — 이름·인원·예산·지역만
class _GroupCard extends StatelessWidget {
  final dynamic group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final members = (group['members'] as List).cast<String>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupScreen(group: group)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Text(group['emoji'], style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(group['name'],
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${members.length} members · ${members.join(', ')}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${group['budget']} · ${group['area']}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastPicksTab extends StatelessWidget {
  const _PastPicksTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      // STATE: S2 지난 선택 목록 → A-4 (구현하지 않음)
      future: Api.archived(), // json-server GET /archived (empty on purpose)
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(message: 'Loading past picks...');
        }
        if (snap.hasError) {
          return ErrorView(
            message: 'Is the mock server running?\n(${snap.error})',
            onRetry: () => HomeScreen.reload(context),
          );
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const EmptyView(
            icon: Icons.restaurant_menu_rounded,
            title: 'No past picks yet',
            hint: 'Finish a taste battle with your group and\n'
                'the place you chose will show up here.',
          ); // A-4 P10 지난 선택 빈 안내
        }
        return ListView(
          children: [
            for (final it in items)
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text('${it['place']}'),
              ),
          ],
        );
      },
    );
  }
}
