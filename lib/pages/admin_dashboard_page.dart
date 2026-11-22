import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ DASHBOARD (FR-ADM-008) ═════════════════
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) => AdminPage('Dashboard', '/admin/dashboard', () {
        final billed = store.invoices.where((i) => i.status != 'Waived').fold(0.0, (a, i) => a + i.total);
        final collected = store.invoices.where((i) => i.status == 'Paid').fold(0.0, (a, i) => a + i.total);
        final overdue = store.invoices.where((i) => i.shown == 'Overdue').fold(0.0, (a, i) => a + i.total);
        final seats = store.mySeats.values.fold(0, (a, b) => a + b) + store.othersSeats;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hello, ${store.me!.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            kpi('Total startups', '${store.users.where((u) => u.role == 'incubatee' && u.status == 'active').length}', Icons.apartment),
            kpi('Seat occupancy', '$seats / ${store.totalSeats}', Icons.event_seat),
            kpi('Revenue billed', inr(billed), Icons.receipt),
            kpi('Collected', inr(collected), Icons.payments),
            kpi('Overdue', inr(overdue), Icons.warning_amber),
            kpi('Open tickets', '${store.tickets.where((t) => t.status != 'Resolved' && t.status != 'Closed').length}', Icons.support_agent),
            kpi('Milestones done', '${(store.completion * 100).round()}%', Icons.flag),
            kpi('Pending approvals', '${store.approvals.where((a) => a.status == 'Pending').length}', Icons.pending_actions),
            kpi('Website enquiries', '${store.enquiries.length}', Icons.mail),
          ]),
          if (store.enquiries.isNotEmpty) ...[h('Latest enquiries'), for (final e in store.enquiries.reversed.take(5)) ListTile(dense: true, leading: const Icon(Icons.mail_outline), title: Text(e))],
        ]);
      });
}
