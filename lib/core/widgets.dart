import 'package:flutter/material.dart';
import '../config.dart';
import 'ui.dart';

// Shared building blocks used by many pages (logo, image helper, portal sidebar frame,
// popup form, ticket thread, sidebar menus). Page-specific code lives in pages/.

// ───────── SHARED HELPERS ─────────
void go(BuildContext c, String path) =>
    Navigator.of(c).pushReplacementNamed(path);
void toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

Color statusColor(String s) => switch (s) {
  'Paid' ||
  'Completed' ||
  'Resolved' ||
  'Closed' ||
  'Verified' ||
  'Approved' ||
  'active' => Colors.green,
  'Due' ||
  'In Progress' ||
  'In progress' ||
  'Assigned' ||
  'Pending' ||
  'pending' => Colors.orange,
  'Overdue' || 'Rejected' || 'Open' || 'inactive' || 'deleted' => Colors.red,
  _ => Colors.blueGrey,
};

Widget statusChip(String s) {
  final c = statusColor(s);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: c.withOpacity(.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      s,
      style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

/// Shows an image from a web link (http...) or from assets. Falls back gracefully if missing.
Widget pic(
  String? src, {
  double? h,
  double? w,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  final fb =
      fallback ??
      Container(
        height: h,
        width: w,
        color: Colors.blueGrey.shade50,
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.black26),
        ),
      );
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
    final src = (light && Brand.logoLight.isNotEmpty)
        ? Brand.logoLight
        : Brand.logo;
    final color = light ? Colors.white : Brand.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (src.isEmpty)
          CircleAvatar(
            radius: 17,
            backgroundColor: Brand.accent,
            child: Text(
              Brand.name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          pic(
            src,
            h: Brand.logoHeight,
            fit: BoxFit.contain,
            fallback: const SizedBox.shrink(),
          ),
        if (src.isEmpty || Brand.showNameWithLogo) ...[
          const SizedBox(width: 8),
          Text(
            Brand.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

/// Centers content with a max width.
class Box extends StatelessWidget {
  final Widget child;
  final double max;
  final EdgeInsets pad;
  const Box({
    super.key,
    required this.child,
    this.max = 1100,
    this.pad = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  });
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max),
      child: Padding(padding: pad, child: child),
    ),
  );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
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
  const PortalScaffold({
    super.key,
    required this.title,
    required this.current,
    required this.items,
    required this.body,
  });

  void _notices(BuildContext context) => showDialog(
    context: context,
    builder: (ctx) => Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 64, right: 16),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          elevation: 12,
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        store.notices.clear();
                        store.refresh();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
                const Divider(),
                if (store.notices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('You are all caught up 🎉')),
                  ),
                for (final n in store.notices.take(8))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Brand.primary.withOpacity(.1),
                      child: const Icon(
                        Icons.notifications_none,
                        size: 18,
                        color: Brand.primary,
                      ),
                    ),
                    title: Text(n),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;

    Widget navTile(NavItem i) {
      final on = i.path == current;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => go(context, i.path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: on ? Colors.white.withOpacity(.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: on ? Brand.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Icon(
                  i.icon,
                  size: 21,
                  color: on ? Brand.accent : Colors.white70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    i.label,
                    style: TextStyle(
                      color: on ? Colors.white : Colors.white70,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget side() => Container(
      width: 258,
      color: Brand.dark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => go(context, '/'),
                  child: const BrandLogo(light: true),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(26, 6, 22, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MENU',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(children: [for (final i in items) navTile(i)]),
            ),
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Avatar(
                    bytes: store.role == 'incubatee' ? store.logo : null,
                    name: store.me?.name ?? '',
                    size: 38,
                    radius: 12,
                    color: Brand.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.me?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          store.me == null
                              ? ''
                              : (store.role == 'incubatee'
                                    ? store.me!.startup
                                    : store.role),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Log out',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () {
                      store.logout();
                      go(context, '/');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        backgroundColor: Brand.surface,
        drawer: wide
            ? null
            : Drawer(backgroundColor: Brand.dark, child: side()),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Brand.dark,
            ),
          ),
          actions: [
            if (wide)
              TextButton.icon(
                onPressed: () => go(context, '/'),
                icon: const Icon(Icons.language, size: 18),
                label: const Text('View website'),
              ),
            IconButton(
              tooltip: 'Notifications',
              icon: Badge(
                label: Text('${store.notices.length}'),
                isLabelVisible: store.notices.isNotEmpty,
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => _notices(context),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: kBorder),
          ),
        ),
        body: Row(
          children: [
            if (wide) side(),
            Expanded(
              child: SingleChildScrollView(
                child: Box(
                  max: 1180,
                  pad: EdgeInsets.all(wide ? 32 : 16),
                  child: body(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable popup form. Returns field-label → value, or null if cancelled.
Future<Map<String, String>?> formDialog(
  BuildContext context,
  String title,
  List<String> fields, {
  Map<String, List<String>> options = const {},
  List<String> multiline = const [],
  List<String> optional = const [],
}) {
  final cs = {
    for (final f in fields)
      f: TextEditingController(text: options[f]?.first ?? ''),
  };
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: options.containsKey(f)
                        ? DropdownButtonFormField<String>(
                            initialValue: cs[f]!.text,
                            decoration: InputDecoration(labelText: f),
                            items: [
                              for (final o in options[f]!)
                                DropdownMenuItem(value: o, child: Text(o)),
                            ],
                            onChanged: (v) => cs[f]!.text = v ?? '',
                          )
                        : TextFormField(
                            controller: cs[f],
                            maxLines: multiline.contains(f) ? 3 : 1,
                            decoration: InputDecoration(labelText: f),
                            validator: optional.contains(f) ? null : V.req,
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(ctx, {
                for (final e in cs.entries) e.key: e.value.text.trim(),
              });
            }
          },
          child: const Text('Save'),
        ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  statusChip(t.status),
                  Chip(label: Text(t.cat)),
                  Chip(label: Text('Assignee: ${t.assignee}')),
                ],
              ),
              const Divider(),
              SizedBox(
                height: 220,
                child: ListView(
                  children: [
                    Text(
                      t.desc,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    for (final m in t.thread)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(m),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: c,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (c.text.trim().isEmpty) return;
                      t.thread.add('${store.me!.name}: ${c.text.trim()}');
                      c.clear();
                      set(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}

// ───────── PORTAL SIDEBAR MENUS ─────────
const incItems = [
  NavItem('Dashboard', '/portal/dashboard', Icons.space_dashboard_outlined),
  NavItem('Profile', '/portal/profile', Icons.business_outlined),
  NavItem('Billing', '/portal/billing', Icons.receipt_long_outlined),
  NavItem('Progress', '/portal/progress', Icons.timeline),
  NavItem('Mentors', '/portal/mentors', Icons.psychology_outlined),
  NavItem('Bookings', '/portal/bookings', Icons.event_available_outlined),
  NavItem('Support', '/portal/support', Icons.support_agent),
];

Widget h(String t) => Padding(
  padding: const EdgeInsets.only(top: 20, bottom: 8),
  child: Text(
    t,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
);

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
List<NavItem> get adminItems => store.role == 'admin'
    ? staffItems
    : staffItems.where((i) => mentorPages.contains(i.path)).toList();

const mentorName = 'Dr. Kumar (Mentor)';
const staffName = 'Lakshmi (Staff)';

class AdminPage extends StatelessWidget {
  final String title, path;
  final Widget Function() body;
  const AdminPage(this.title, this.path, this.body, {super.key});
  @override
  Widget build(BuildContext context) => PortalScaffold(
    title: title,
    current: path,
    items: adminItems,
    body: body,
  );
}

Widget kpi(String label, String value, IconData icon) => SizedBox(
  width: 220,
  child: Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Brand.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
