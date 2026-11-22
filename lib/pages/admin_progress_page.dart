import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ PROGRESS (FR-PRG-002/006/007) ═════════════════
class AdminProgress extends StatefulWidget {
  const AdminProgress({super.key});
  @override
  State<AdminProgress> createState() => _AdminProgressState();
}

class _AdminProgressState extends State<AdminProgress> {
  Future<void> addMilestone() async {
    final r = await formDialog(context, 'New milestone for GreenLeaf Agritech', ['Title', 'Description', 'Target date']);
    if (r == null) return;
    store.milestones.add(Milestone(r['Title']!, r['Description']!, r['Target date']!));
    store.log('Milestone added: ${r['Title']}');
    setState(() {});
  }

  Future<void> review(Report r) async {
    final f = await formDialog(context, 'Review ${r.period}', ['Comment', 'Rating (1-5)']);
    if (f == null) return;
    r.comment = f['Comment']!;
    r.rating = (int.tryParse(f['Rating (1-5)']!) ?? 0).clamp(0, 5);
    store.log('Reviewed report ${r.period}');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => AdminPage('Progress', '/admin/progress', () => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h('GreenLeaf Agritech'),
        Row(children: [
          const Text('Incubation stage: '),
          DropdownButton<String>(
              value: store.stage,
              items: [for (final s in ['Onboarded', 'Active', 'Graduated', 'Exited']) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) { store.stage = v!; store.log('Stage set to $v'); setState(() {}); }),
          const SizedBox(width: 16),
          Text('${(store.completion * 100).round()}% milestones complete'),
        ]),
        h('Milestones'),
        for (final m in store.milestones) Card(child: ListTile(title: Text(m.title), subtitle: Text('${m.desc} · Target ${m.date}${m.evidence.isEmpty ? '' : '\nEvidence: ${m.evidence}'}'), trailing: statusChip(m.status))),
        TextButton.icon(onPressed: addMilestone, icon: const Icon(Icons.add), label: const Text('Define milestone')),
        h('Quarterly reports'),
        for (final r in store.reports)
          Card(child: ListTile(
            title: Text('${r.period} · Revenue ${r.revenue} · Users ${r.users} · Funding ${r.funding}'),
            subtitle: Text('${r.achv}\n${r.comment.isEmpty ? 'Not reviewed' : '${r.comment}  ${'★' * r.rating}'}'),
            isThreeLine: true,
            trailing: OutlinedButton(onPressed: () => review(r), child: const Text('Review')),
          )),
      ]));
}
