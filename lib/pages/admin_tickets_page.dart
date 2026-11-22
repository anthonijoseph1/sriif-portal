import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ TICKETS (FR-TKT-005) ═════════════════
class AdminTickets extends StatefulWidget {
  const AdminTickets({super.key});
  @override
  State<AdminTickets> createState() => _AdminTicketsState();
}

class _AdminTicketsState extends State<AdminTickets> {
  @override
  Widget build(BuildContext context) => AdminPage('Tickets', '/admin/tickets', () {
        final list = store.role == 'mentor' ? store.tickets.where((t) => t.assignee == mentorName).toList() : store.tickets;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          h(store.role == 'mentor' ? 'Tickets assigned to you' : 'All tickets'),
          if (list.isEmpty) const Text('No tickets assigned yet. (Log in as admin to assign one to the mentor.)'),
          for (final t in list)
            Card(child: ListTile(
              title: Text('#${t.id} · ${t.subject}'),
              subtitle: Text('${t.cat} · ${t.priority}'),
              onTap: () => showTicket(context, t),
              trailing: Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (store.role == 'admin')
                  DropdownButton<String>(
                      value: t.assignee,
                      items: [for (final a in ['Unassigned', staffName, mentorName]) DropdownMenuItem(value: a, child: Text(a))],
                      onChanged: (v) {
                        t.assignee = v!;
                        if (t.status == 'Open' && v != 'Unassigned') t.status = 'Assigned';
                        store.log('Ticket #${t.id} assigned to $v');
                        setState(() {});
                      }),
                DropdownButton<String>(
                    value: t.status,
                    items: [for (final s in ['Open', 'Assigned', 'In Progress', 'Resolved', 'Closed']) DropdownMenuItem(value: s, child: Text(s))],
                    onChanged: (v) {
                      t.status = v!;
                      store.notices.insert(0, 'Ticket #${t.id} is now $v – email sent.');
                      store.log('Ticket #${t.id} status → $v');
                      setState(() {});
                    }),
              ]),
            )),
        ]);
      });
}
