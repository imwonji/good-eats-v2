import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets/states.dart';
import 'result_screen.dart';

/// 화면 C 취향 배틀 — A 또는 B를 고른다. 고를 때마다 다음 라운드로
/// Navigator.pushReplacement (no setState, no saved answers).
class BattleScreen extends StatelessWidget {
  final dynamic group;
  final int round;
  final List<dynamic>? pairs; // null on round 0 → fetched from json-server

  const BattleScreen(
      {super.key, required this.group, required this.round, this.pairs});

  void _next(BuildContext context, List<dynamic> all) {
    // STATE: S4 멤버별 A/B 선택 → C-1 진행도, C-2 (구현하지 않음)
    final nextRound = round + 1;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => nextRound < all.length
            ? BattleScreen(group: group, round: nextRound, pairs: all)
            : ResultScreen(group: group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // C-4 P03 배틀 그만두기 — 언제든 빠져나갈 수 있음
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Quit battle',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Taste battle'),
      ),
      body: pairs != null
          ? _body(context, pairs!)
          : FutureBuilder<List<dynamic>>(
              future: Api.pairs(), // json-server GET /pairs
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Setting up the battle...');
                }
                if (snap.hasError) {
                  return ErrorView(
                    message: 'Is the mock server running?\n(${snap.error})',
                    onRetry: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => BattleScreen(group: group, round: 0),
                      ),
                    ),
                  );
                }
                if (snap.data!.isEmpty) {
                  return const EmptyView(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'No dishes to compare',
                    hint: 'Try again later.',
                  );
                }
                return _body(context, snap.data!);
              },
            ),
    );
  }

  Widget _body(BuildContext context, List<dynamic> all) {
    final pair = all[round];
    final cardA = _ChoiceCard(item: pair['a'], onTap: () => _next(context, all));
    final cardB = _ChoiceCard(item: pair['b'], onTap: () => _next(context, all));

    return LayoutBuilder(
      builder: (context, c) {
        final wide = isWide(c); // C-5 P04 A/B 배치 — 폰은 위아래, 넓은 화면은 좌우
        final vs = Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text('VS',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold)),
          ),
        );
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // C-1 P01 라운드 진행도 — "Round 2 of 3"
              Text('Round ${round + 1} of ${all.length}',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (round + 1) / all.length),
              const SizedBox(height: 8),
              // C-6 P01 투표 현황 — 누가 끝냈고 누구를 기다리는지 (셀프 논증 쟁점 1 수정)
              _VoteStatus(members: (group['members'] as List).cast<String>(), round: round),
              const SizedBox(height: 8),
              Text('Which would you rather eat tonight?',
                  style: Theme.of(context).textTheme.titleMedium),
              // C-7 P05 제외 음식 안내 — 그룹이 못 먹는 음식은 배틀에서 뺐다고 알림 (셀프 논증 쟁점 1 수정)
              if ((group['avoid'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_food_outlined,
                          size: 16, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        'Hidden for your group: ${(group['avoid'] as List).join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // C-2 P06 A/B 선택 카드 — 기억하지 않고 화면을 보고 고른다 (넓은 화면은 옆으로, 폰은 위아래)
              Expanded(
                child: wide
                    ? Row(children: [
                        Expanded(child: cardA),
                        vs,
                        Expanded(child: cardB),
                      ])
                    : Column(children: [
                        Expanded(child: cardA),
                        vs,
                        Expanded(child: cardB),
                      ]),
              ),
              const SizedBox(height: 8),
              // C-3 P07 건너뛰기 — 의견이 없으면 바로 다음으로
              TextButton(
                onPressed: () => _next(context, all),
                child: const Text("I'm fine with either — skip"),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// C-6 투표 현황 — 표시만 (미리 정한 가짜 값: 앞의 멤버들은 끝냈고 마지막 멤버를 기다림)
// STATE: S4 멤버별 A/B 선택 → C-6 투표 현황 (구현하지 않음)
class _VoteStatus extends StatelessWidget {
  final List<String> members;
  final int round;
  const _VoteStatus({required this.members, required this.round});

  @override
  Widget build(BuildContext context) {
    final done = members.length - 1;
    final waiting = members.last;
    return Text(
      '✓ $done of ${members.length} members done · waiting for $waiting',
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}

/// C-2 A/B 선택 카드 — 메뉴판처럼 이모지·종류·가격 (P06 · P02)
class _ChoiceCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  const _ChoiceCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['emoji'], style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(item['name'],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${item['cuisine']} · ${item['price']}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
