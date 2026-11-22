import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ SUPPORT (FR-TKT) ═════════════════
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});
  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  Future<void> newTicket() async {
    final r = await formDialog(
      context,
      'Raise a ticket',
      ['Category', 'Priority', 'Subject', 'Description', 'Expertise needed (Mentor Request)', 'Preferred time slots (Mentor Request)', 'Attachment name (optional)'],
      options: {'Category': Content.ticketCategories, 'Priority': ['Low', 'Medium', 'High']},
      multiline: ['Description'],
      optional: ['Expertise needed (Mentor Request)', 'Preferred time slots (Mentor Request)', 'Attachment name (optional)'],
    );
    if (r == null) return;
    var desc = r['Description']!;
    if (r['Category'] == 'Mentor Request') {
      if (r['Expertise needed (Mentor Request)']!.isEmpty || r['Preferred time slots (Mentor Request)']!.isEmpty) {
        return toast(context, 'Mentor requests need expertise area and preferred time slots.');
      }
      desc += '\nExpertise: ${r['Expertise needed (Mentor Request)']}\nSlots: ${r['Preferred time slots (Mentor Request)']}';
    }
    final t = Ticket(store.nextTicket++, r['Category']!, r['Subject']!, r['Priority']!, desc);
    store.tickets.insert(0, t);
    store.notices.insert(0, 'Ticket #${t.id} created – email sent.');
    store.refresh();
    toast(context, 'Ticket #${t.id} created. Email notification sent (simulated).');
  }

  @override
  Widget build(BuildContext context) => PortalScaffold(
        title: 'Support',
        current: '/portal/support',
        items: incItems,
        body: () => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Support & Mentor Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            FilledButton.icon(onPressed: newTicket, icon: const Icon(Icons.add), label: const Text('New ticket')),
          ]),
          const SizedBox(height: 12),
          for (final t in store.tickets)
            Card(child: ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: Text('#${t.id} · ${t.subject}'),
              subtitle: Text('${t.cat} · ${t.priority} · ${t.assignee}'),
              trailing: statusChip(t.status),
              onTap: () => showTicket(context, t),
            )),
        ]),
      );
}
