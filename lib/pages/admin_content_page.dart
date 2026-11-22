import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ CONTENT & NOTICES (FR-WEB-009, FR-ADM-007/011) ═════════════════
class AdminContent extends StatefulWidget {
  const AdminContent({super.key});
  @override
  State<AdminContent> createState() => _AdminContentState();
}

class _AdminContentState extends State<AdminContent> {
  late final tag = TextEditingController(text: store.tagline), ban = TextEditingController(text: store.banner);
  bool email = true, sms = false, portal = true;
  final msg = TextEditingController();

  @override
  Widget build(BuildContext context) => AdminPage('Content & Notices', '/admin/content', () => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h('Edit website content (no code needed)'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          TextField(controller: tag, decoration: const InputDecoration(labelText: 'Home page headline')),
          const SizedBox(height: 12),
          TextField(controller: ban, decoration: const InputDecoration(labelText: 'Top banner (empty = hidden)')),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            FilledButton(onPressed: () { store.tagline = tag.text; store.banner = ban.text; store.log('Website content edited'); toast(context, 'Website updated – open Home to see it.'); }, child: const Text('Publish changes')),
            OutlinedButton(
                onPressed: () async {
                  final r = await formDialog(context, 'Add news item', ['Title', 'Date', 'Summary']);
                  if (r != null) { store.news.insert(0, {'title': r['Title']!, 'tag': r['Date']!, 'desc': r['Summary']!}); store.log('News added: ${r['Title']}'); toast(context, 'News published.'); }
                },
                child: const Text('Add news item')),
          ]),
        ]))),
        h('Send announcement'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: msg, maxLines: 3, decoration: const InputDecoration(labelText: 'Message to all startups')),
          Wrap(spacing: 12, children: [
            FilterChip(label: const Text('Email'), selected: email, onSelected: (v) => setState(() => email = v)),
            FilterChip(label: const Text('SMS'), selected: sms, onSelected: (v) => setState(() => sms = v)),
            FilterChip(label: const Text('In-portal'), selected: portal, onSelected: (v) => setState(() => portal = v)),
          ]),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: () {
                if (msg.text.trim().isEmpty) return;
                if (portal) store.notices.insert(0, 'Announcement: ${msg.text.trim()}');
                store.log('Announcement sent (${[if (email) 'email', if (sms) 'sms', if (portal) 'portal'].join(', ')})');
                msg.clear();
                toast(context, 'Announcement sent (email/SMS simulated).');
              },
              child: const Text('Send')),
        ]))),
      ]));
}
