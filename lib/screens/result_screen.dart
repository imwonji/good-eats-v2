import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets/states.dart';

/// 화면 D AI 추천 — json-server에 미리 정해 둔 (가짜) 추천 결과.
/// No real recommendation algorithm is implemented.
class ResultScreen extends StatelessWidget {
  final dynamic group;
  const ResultScreen({super.key, required this.group});

  void _share(BuildContext context, dynamic rec) {
    // D-5 P01 공유 완료 알림 (가짜 — 보내거나 저장하지 않음)
    // STATE: S6 그룹 공유 여부 → D-5 (구현하지 않음)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, size: 40),
        title: const Text('Sent to the group!'),
        content: Text(
            'Everyone in "${group['name']}" can now see ${rec['place']}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tonight's AI pick")),
      body: FutureBuilder<List<dynamic>>(
        // STATE: S5 추천 결과·매치 점수 → D-1, D-3 (구현하지 않음)
        // json-server GET /recommendations?groupId=n
        future: Api.recommendation(group['id'] as int),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(
                message: "Combining everyone's taste..."); // P01
          }
          if (snap.hasError) {
            return ErrorView(
              message: 'Is the mock server running?\n(${snap.error})',
              onRetry: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => ResultScreen(group: group)),
              ),
            ); // P09
          }
          if (snap.data!.isEmpty) {
            return const EmptyView(
              icon: Icons.search_off_rounded,
              title: 'No place fits everyone yet',
              hint: 'Try raising the budget or widening the area\n'
                  'in group settings.',
            ); // P10
          }
          return _ResultBody(
              rec: snap.data!.first, onShare: (r) => _share(context, r));
        },
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final dynamic rec;
  final void Function(dynamic) onShare;
  const _ResultBody({required this.rec, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final reasons = (rec['reasons'] as List).cast<String>();
    final fits = rec['memberFit'] as List;
    final scheme = Theme.of(context).colorScheme;

    // D-1 P08 오늘의 추천 식당 — 긴 목록 대신 답 하나
    final pickCard = Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text('${rec['matchScore']}% group match',
                    style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(rec['place'],
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(rec['cuisine']),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(
                  avatar: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(rec['price'])),
              Chip(
                  avatar: const Icon(Icons.directions_walk, size: 18),
                  label: Text(rec['distance'])),
            ]),
          ],
        ),
      ),
    );

    // D-2 P10 추천 이유 — AI가 왜 골랐는지 쉬운 말로
    final whyCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why this place',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final r in reasons)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    // D-3 P01 멤버별 만족도 — 모두에게 얼마나 맞는지 공개
    final fitCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How it fits each member',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final f in fits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text(f['name'])),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (f['fit'] as num) / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${f['fit']}%'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    // D-6 P03 백업 후보 — 추천이 꽉 찼거나 마음에 안 들 때 바로 고를 2곳 (셀프 논증 쟁점 2 수정)
    final backups = (rec['backups'] as List?) ?? const [];
    final backupCard = Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('If it\'s full — backup picks',
                style: Theme.of(context).textTheme.titleSmall),
            for (final b in backups)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restaurant_outlined, size: 20),
                title: Text(b['place']),
                subtitle: Text('${b['cuisine']} · ${b['distance']}'),
                trailing: Text('${b['matchScore']}%'),
              ),
          ],
        ),
      ),
    );

    // D-4 P03 그룹에 보내기 · 다시 고르기 — 결과를 거부할 자유
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => onShare(rec),
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send to group'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Not feeling it — pick again'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (isWide(c)) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(children: [
                    pickCard,
                    const SizedBox(height: 12),
                    if (backups.isNotEmpty) backupCard,
                    const SizedBox(height: 16),
                    actions,
                  ]),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(children: [
                    whyCard,
                    const SizedBox(height: 12),
                    fitCard,
                  ]),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            pickCard,
            const SizedBox(height: 12),
            if (backups.isNotEmpty) ...[backupCard, const SizedBox(height: 12)],
            whyCard,
            const SizedBox(height: 12),
            fitCard,
            const SizedBox(height: 20),
            actions,
          ],
        );
      },
    );
  }
}
