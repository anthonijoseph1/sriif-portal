import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ STARTUPS & APPROVALS (FR-ADM-002/003) ═════════════════
class AdminStartups extends StatefulWidget {
  const AdminStartups({super.key});
  @override
  State<AdminStartups> createState() => _AdminStartupsState();
}

class _AdminStartupsState extends State<AdminStartups> {
  void setStatus(AppUser u, String s) {
    u.status = s;
    store.log('User ${u.email} set to $s');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => AdminPage('Startups & Approvals', '/admin/startups', () {
        final pending = store.approvals.where((a) => a.status == 'Pending').toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          h('Pending approvals (registrations, profile changes, documents, seats)'),
          if (pending.isEmpty) const Text('Nothing pending.'),
          for (final a in pending)
            Card(child: ListTile(
              leading: Chip(label: Text(a.type)),
              title: Text(a.detail),
              trailing: Wrap(spacing: 6, children: [
                FilledButton(onPressed: () { a.onApprove?.call(); a.status = 'Approved'; store.log('Approved ${a.type}: ${a.detail}'); setState(() {}); }, child: const Text('Approve')),
                OutlinedButton(onPressed: () { a.status = 'Rejected'; store.log('Rejected ${a.type}: ${a.detail}'); setState(() {}); }, child: const Text('Reject')),
              ]),
            )),
          h('Users'),
          for (final u in store.users)
            Card(child: ListTile(
              title: Text('${u.name} · ${u.role == 'incubatee' ? u.startup : u.role}'),
              subtitle: Text('${u.email} · ${u.phone}'),
              trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                statusChip(u.status),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'reset') { store.log('Access reset for ${u.email}'); toast(context, 'Reset link sent to ${u.email} (simulated).'); }
                    else { setStatus(u, v); }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'active', child: Text('Activate')),
                    PopupMenuItem(value: 'inactive', child: Text('Deactivate')),
                    PopupMenuItem(value: 'deleted', child: Text('Delete (soft)')),
                    PopupMenuItem(value: 'reset', child: Text('Reset access')),
                  ],
                ),
              ]),
            )),
        ]);
      });
}
