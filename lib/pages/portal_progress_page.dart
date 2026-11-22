import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ PROGRESS (FR-PRG) ═════════════════
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});
  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  Future<void> report() async {
    final r = await formDialog(context, 'Quarterly progress report', ['Period', 'Revenue', 'Users / customers', 'Funding raised', 'Jobs created', 'Key achievements'],
        multiline: ['Key achievements']);
    if (r == null) return;
    store.reports.add(Report(r['Period']!, r['Revenue']!, r['Users / customers']!, r['Funding raised']!, r['Jobs created']!, r['Key achievements']!));
    store.notices.insert(0, 'Progress report submitted for ${r['Period']}');
    store.refresh();
  }

  Future<void> evidence(Milestone m) async {
    final r = await formDialog(context, 'Attach evidence', ['Evidence (file name or link)']);
    if (r != null) { m.evidence = r.values.first; store.refresh(); }
  }

  @override
  Widget build(BuildContext context) => PortalScaffold(
        title: 'Progress',
        current: '/portal/progress',
        items: incItems,
        body: () => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Progress', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Chip(label: Text('Stage: ${store.stage}')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: LinearProgressIndicator(value: store.completion, minHeight: 10)),
            const SizedBox(width: 12),
            Text('${(store.completion * 100).round()}% milestones done'),
          ]),
          h('Milestone timeline'),
          for (var i = 0; i < store.milestones.length; i++) _timelineRow(store.milestones[i], i == store.milestones.length - 1),
          h('Quarterly reports'),
          for (final r in store.reports)
            Card(child: ListTile(
              title: Text('${r.period} · Revenue ${r.revenue} · Users ${r.users} · Funding ${r.funding} · Jobs ${r.jobs}'),
              subtitle: Text('${r.achv}${r.comment.isEmpty ? '' : '\nMentor/staff: ${r.comment}  ${'★' * r.rating}'}'),
            )),
          Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: report, icon: const Icon(Icons.add), label: const Text('Submit quarterly report'))),
        ]),
      );

  Widget _timelineRow(Milestone m, bool last) {
    final c = statusColor(m.status == 'Not started' ? '' : m.status);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: 30, child: Column(children: [
          Icon(m.status == 'Completed' ? Icons.check_circle : Icons.radio_button_unchecked, color: c),
          if (!last) Expanded(child: Container(width: 2, color: Colors.black12)),
        ])),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${m.desc} · Target ${m.date}'),
                if (m.evidence.isNotEmpty) Text('Evidence: ${m.evidence}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  DropdownButton<String>(
                      value: m.status,
                      items: [for (final s in ['Not started', 'In progress', 'Completed']) DropdownMenuItem(value: s, child: Text(s))],
                      onChanged: (v) { m.status = v!; store.refresh(); }),
                  TextButton.icon(onPressed: () => evidence(m), icon: const Icon(Icons.attach_file), label: const Text('Attach evidence')),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
