import 'package:flutter/material.dart';

import '../widgets/states.dart';
import 'battle_screen.dart';
import 'result_screen.dart';

/// 화면 B 그룹 상세 — 멤버 칩, 결정 조건 요약, 취향 배틀 시작
class GroupScreen extends StatelessWidget {
  final dynamic group;
  const GroupScreen({super.key, required this.group});

  void _showSettings(BuildContext context) {
    // B-5 P03 그룹 설정 시트 — 화면을 떠나지 않고 보고 닫기
    // STATE: S3 그룹 설정(예산·지역·못 먹는 음식) → B-2, B-5 (구현하지 않음)
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _SettingsSheet(group: group),
    );
  }

  void _showInvite(BuildContext context) {
    // B-6 P02 친구 초대 코드 (가짜 — 실제 가입 없음)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite friends'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this code with your friends:'),
            SizedBox(height: 12),
            SelectableText('EAT-4821',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = (group['members'] as List).cast<String>();
    final avoid = (group['avoid'] as List).cast<String>();

    final header = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${group['emoji']}  ${group['name']}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            // B-1 P06 멤버 칩 · 친구 초대 — 누가 있는지 한눈에
            Text('Members', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in members)
                  Chip(
                    avatar: CircleAvatar(child: Text(m[0])),
                    label: Text(m),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Invite'),
                  onPressed: () => _showInvite(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final settings = Card(
      child: Column(
        children: [
          // B-2 P05 결정 조건 요약 — 결정 전에 조건을 보여 실수 방지
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Budget'),
            subtitle: Text(group['budget']),
          ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('Area'),
            subtitle: Text(group['area']),
          ),
          ListTile(
            leading: const Icon(Icons.no_food_outlined),
            title: const Text("Can't eat"),
            subtitle: Text(avoid.isEmpty ? 'Nothing' : avoid.join(', ')),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('See all group settings'),
            trailing: const Icon(Icons.expand_less),
            onTap: () => _showSettings(context),
          ),
        ],
      ),
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // B-3 P04 취향 배틀 시작 (주요 행동 1개) · B-4 P07 AI 추천 바로 보기 (지름길)
        FilledButton.icon(
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BattleScreen(group: group, round: 0),
            ),
          ),
          icon: const Icon(Icons.compare_arrows_rounded),
          label: const Text('Start taste battle'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ResultScreen(group: group)),
          ),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Skip — just show the AI pick'),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(group['name'])),
      body: LayoutBuilder(
        builder: (context, c) {
          if (isWide(c)) {
            // B-7 P07 넓은 화면 두 단 — 왼쪽 멤버·버튼, 오른쪽 조건
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Column(
                          children: [header, const SizedBox(height: 16), actions])),
                  const SizedBox(width: 24),
                  Expanded(child: settings),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              header,
              const SizedBox(height: 12),
              settings,
              const SizedBox(height: 20),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  final dynamic group;
  const _SettingsSheet({required this.group});

  @override
  Widget build(BuildContext context) {
    final avoid = (group['avoid'] as List).cast<String>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group settings',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Set by the group leader. Everyone sees the same values.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            _row(context, Icons.payments_outlined, 'Budget', group['budget']),
            _row(context, Icons.place_outlined, 'Area', group['area']),
            _row(context, Icons.no_food_outlined, "Can't eat",
                avoid.isEmpty ? 'Nothing' : avoid.join(', ')),
            _row(context, Icons.schedule, 'Time', 'Tonight, 7:00 PM'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context), // P03 easy exit
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
