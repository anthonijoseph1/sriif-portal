import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';
import 'package:flutter/services.dart';

// ═════════════════ REPORTS & AUDIT (FR-ADM-009/010) ═════════════════
class AdminReports extends StatelessWidget {
  const AdminReports({super.key});

  void export(BuildContext c, String name, List<List<String>> rows) {
    final csv = rows.map((r) => r.map((x) => '"${x.replaceAll('"', "'")}"').join(',')).join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    store.log('Exported $name report');
    toast(c, '$name report copied as CSV – paste into Excel. (PDF export is simulated.)');
  }

  @override
  Widget build(BuildContext context) => AdminPage('Reports & Audit', '/admin/reports', () {
        final reports = <String, List<List<String>>>{
          'Startup list': [['Startup', 'Founder', 'Email', 'Status'], for (final u in store.users.where((u) => u.role == 'incubatee')) [u.startup, u.name, u.email, u.status]],
          'Billing': [['Invoice', 'Period', 'Total', 'Status'], for (final i in store.invoices) [i.no, i.period, i.total.toStringAsFixed(0), i.shown]],
          'Collections': [['Invoice', 'Amount', 'Receipt'], for (final i in store.invoices.where((i) => i.status == 'Paid')) [i.no, i.total.toStringAsFixed(0), i.receipt ?? '']],
          'Progress': [['Milestone', 'Target', 'Status'], for (final m in store.milestones) [m.title, m.date, m.status]],
          'Tickets': [['ID', 'Category', 'Subject', 'Status', 'Assignee'], for (final t in store.tickets) ['${t.id}', t.cat, t.subject, t.status, t.assignee]],
        };
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          h('Export reports'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final e in reports.entries) OutlinedButton.icon(onPressed: () => export(context, e.key, e.value), icon: const Icon(Icons.download), label: Text(e.key)),
          ]),
          h('Audit log (read-only)'),
          if (store.audit.isEmpty) const Text('No actions yet.'),
          for (final a in store.audit.take(50)) ListTile(dense: true, leading: const Icon(Icons.history, size: 18), title: Text(a, style: const TextStyle(fontSize: 13))),
        ]);
      });
}
