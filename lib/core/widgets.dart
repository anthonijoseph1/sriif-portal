import 'package:flutter/material.dart';
import '../config.dart';

// Shared building blocks used by many pages (logo, image helper, portal sidebar frame,
// popup form, ticket thread, sidebar menus). Page-specific code lives in pages/.

// ───────── SHARED HELPERS ─────────
void go(BuildContext c, String path) => Navigator.of(c).pushReplacementNamed(path);
void toast(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

Color statusColor(String s) => switch (s) {
      'Paid' || 'Completed' || 'Resolved' || 'Closed' || 'Verified' || 'Approved' || 'active' => Colors.green,
      'Due' || 'In Progress' || 'In progress' || 'Assigned' || 'Pending' || 'pending' => Colors.orange,
      'Overdue' || 'Rejected' || 'Open' || 'inactive' || 'deleted' => Colors.red,
      _ => Colors.blueGrey,
    };

Widget statusChip(String s) {
  final c = statusColor(s);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: c.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
    child: Text(s, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

/// Shows an image from a web link (http...) or from assets. Falls back gracefully if missing.
Widget pic(String? src, {double? h, double? w, BoxFit fit = BoxFit.cover, Widget? fallback}) {
  final fb = fallback ??
      Container(height: h, width: w, color: Colors.blueGrey.shade50, child: const Center(child: Icon(Icons.image_outlined, color: Colors.black26)));
  if (src == null || src.isEmpty) return fb;
  Widget err(BuildContext _, Object __, StackTrace? ___) => fb;
  return src.startsWith('http')
      ? Image.network(src, height: h, width: w, fit: fit, errorBuilder: err)
      : Image.asset(src, height: h, width: w, fit: fit, errorBuilder: err);
}

class BrandLogo extends StatelessWidget {
  final bool light; // true on dark backgrounds
  const BrandLogo({super.key, this.light = false});
  @override
  Widget build(BuildContext context) {
    final src = (light && Brand.logoLight.isNotEmpty) ? Brand.logoLight : Brand.logo;
    final color = light ? Colors.white : Brand.primary;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (src.isEmpty)
        CircleAvatar(radius: 17, backgroundColor: Brand.accent, child: Text(Brand.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
      else
        pic(src, h: Brand.logoHeight, fit: BoxFit.contain, fallback: const SizedBox.shrink()),
      if (src.isEmpty || Brand.showNameWithLogo) ...[
        const SizedBox(width: 8),
        Text(Brand.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      ],
    ]);
  }
}

/// Centers content with a max width.
class Box extends StatelessWidget {
  final Widget child;
  final double max;
  final EdgeInsets pad;
  const Box({super.key, required this.child, this.max = 1100, this.pad = const EdgeInsets.symmetric(horizontal: 24, vertical: 32)});
  @override
  Widget build(BuildContext context) =>
      Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: max), child: Padding(padding: pad, child: child)));
}

class PageHeader extends StatelessWidget {
  final String title, sub;
  const PageHeader(this.title, this.sub, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Brand.primary,
        child: Box(
          pad: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ]),
        ),
      );
}

// ───────── PORTAL FRAME (sidebar) ─────────
class NavItem {
  final String label, path;
  final IconData icon;
  const NavItem(this.label, this.path, this.icon);
}

class PortalScaffold extends StatelessWidget {
  final String title, current;
  final List<NavItem> items;
  final Widget Function() body;
  const PortalScaffold({super.key, required this.title, required this.current, required this.items, required this.body});

  void _notices(BuildContext context) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Notifications'),
          content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final n in store.notices.take(8)) ListTile(dense: true, leading: const Icon(Icons.notifications_none), title: Text(n)),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 820;
    Widget menu() => ListView(children: [
          for (final i in items)
            ListTile(leading: Icon(i.icon), title: Text(i.label), selected: i.path == current, onTap: () => go(context, i.path)),
        ]);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: Brand.primary,
          foregroundColor: Colors.white,
          title: Row(children: [const BrandLogo(light: true), const SizedBox(width: 12), if (wide) Text('| $title')]),
          actions: [
            IconButton(
                tooltip: 'Notifications',
                icon: Badge(label: Text('${store.notices.length}'), isLabelVisible: store.notices.isNotEmpty, child: const Icon(Icons.notifications_outlined)),
                onPressed: () => _notices(context)),
            if (wide) Center(child: Text(store.me?.name ?? '')),
            IconButton(tooltip: 'Logout', icon: const Icon(Icons.logout), onPressed: () { store.logout(); go(context, '/'); }),
          ],
        ),
        drawer: wide ? null : Drawer(child: menu()),
        body: Row(children: [
          if (wide) SizedBox(width: 230, child: Material(color: Colors.white, child: menu())),
          Expanded(child: SingleChildScrollView(child: Box(max: 1000, pad: const EdgeInsets.all(20), child: body()))),
        ]),
      ),
    );
  }
}

/// Reusable popup form. Returns field-label → value, or null if cancelled.
Future<Map<String, String>?> formDialog(BuildContext context, String title, List<String> fields,
    {Map<String, List<String>> options = const {}, List<String> multiline = const [], List<String> optional = const []}) {
  final cs = {for (final f in fields) f: TextEditingController(text: options[f]?.first ?? '')};
  final key = GlobalKey<FormState>();
  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final f in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: options.containsKey(f)
                      ? DropdownButtonFormField<String>(
                          value: cs[f]!.text,
                          decoration: InputDecoration(labelText: f),
                          items: [for (final o in options[f]!) DropdownMenuItem(value: o, child: Text(o))],
                          onChanged: (v) => cs[f]!.text = v ?? '')
                      : TextFormField(
                          controller: cs[f],
                          maxLines: multiline.contains(f) ? 3 : 1,
                          decoration: InputDecoration(labelText: f),
                          validator: optional.contains(f) ? null : V.req),
                ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(ctx, {for (final e in cs.entries) e.key: e.value.text.trim()});
            },
            child: const Text('Save')),
      ],
    ),
  );
}

/// Ticket thread popup – used by incubatee, mentor and admin.
void showTicket(BuildContext context, Ticket t) {
  final c = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text('#${t.id} · ${t.subject}'),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, children: [statusChip(t.status), Chip(label: Text(t.cat)), Chip(label: Text('Assignee: ${t.assignee}'))]),
            const Divider(),
            SizedBox(
              height: 220,
              child: ListView(children: [
                Text(t.desc, style: const TextStyle(fontStyle: FontStyle.italic)),
                for (final m in t.thread) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(m)),
              ]),
            ),
            Row(children: [
              Expanded(child: TextField(controller: c, decoration: const InputDecoration(hintText: 'Type a message'))),
              IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (c.text.trim().isEmpty) return;
                    t.thread.add('${store.me!.name}: ${c.text.trim()}');
                    c.clear();
                    set(() {});
                  }),
            ]),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    ),
  );
}

// ───────── PORTAL SIDEBAR MENUS ─────────
const incItems = [
  NavItem('Profile', '/portal/profile', Icons.business),
  NavItem('Billing', '/portal/billing', Icons.receipt_long),
  NavItem('Progress', '/portal/progress', Icons.timeline),
  NavItem('Support', '/portal/support', Icons.support_agent),
];

Widget h(String t) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));

const staffItems = [
  NavItem('Dashboard', '/admin/dashboard', Icons.dashboard),
  NavItem('Startups & Approvals', '/admin/startups', Icons.apartment),
  NavItem('Seats & Billing', '/admin/billing', Icons.receipt_long),
  NavItem('Progress', '/admin/progress', Icons.timeline),
  NavItem('Tickets', '/admin/tickets', Icons.support_agent),
  NavItem('Content & Notices', '/admin/content', Icons.campaign),
  NavItem('Reports & Audit', '/admin/reports', Icons.assessment),
];

/// Pages a mentor login may open.
const mentorPages = ['/admin/dashboard', '/admin/progress', '/admin/tickets'];

/// Mentors only see Dashboard, Progress and Tickets.
List<NavItem> get adminItems =>
    store.role == 'admin' ? staffItems : staffItems.where((i) => mentorPages.contains(i.path)).toList();

const mentorName = 'Dr. Kumar (Mentor)';
const staffName = 'Lakshmi (Staff)';

class AdminPage extends StatelessWidget {
  final String title, path;
  final Widget Function() body;
  const AdminPage(this.title, this.path, this.body, {super.key});
  @override
  Widget build(BuildContext context) => PortalScaffold(title: title, current: path, items: adminItems, body: body);
}

Widget kpi(String label, String value, IconData icon) => SizedBox(
      width: 220,
      child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Icon(icon, color: Brand.primary, size: 32),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ])),
      ]))),
    );
