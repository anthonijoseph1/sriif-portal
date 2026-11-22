import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ PROFILE (FR-PRO) ═════════════════
class F {
  final String key, label;
  final bool sens; // sensitive → needs admin approval to change
  final int lines;
  final String? Function(String?)? check;
  const F(this.key, this.label, {this.sens = false, this.lines = 1, this.check});
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _k = GlobalKey<FormState>();
  // EDIT: add or remove profile fields here
  final groups = <String, List<F>>{
    'Startup details': [
      const F('name', 'Startup / legal name', sens: true), const F('legal', 'Legal entity type'), const F('inc', 'Incorporation date'),
      const F('address', 'Registered address'), const F('website', 'Website'), const F('sector', 'Sector / domain'),
      const F('stage', 'Stage'), const F('desc', 'Short description', lines: 3),
    ],
    'Pitch': [
      const F('problem', 'Problem', lines: 2), const F('solution', 'Solution', lines: 2), const F('market', 'Target market'),
      const F('model', 'Business model'), const F('traction', 'Traction'), const F('funding', 'Funding sought'), const F('video', 'Pitch video link (optional)'),
    ],
    'Statutory & compliance': [
      F('pan', 'PAN', sens: true, check: V.pan), F('gstin', 'GSTIN', sens: true, check: V.gstin),
      const F('cin', 'CIN / registration no.'), const F('dpiit', 'DPIIT recognition no.'), const F('bank', 'Bank details'),
    ],
  };
  late final cs = {for (final g in groups.values) for (final f in g) f.key: TextEditingController(text: store.profile[f.key] ?? '')};

  void save() {
    if (!_k.currentState!.validate()) return;
    int direct = 0, approval = 0;
    for (final g in groups.values) {
      for (final f in g) {
        final nv = cs[f.key]!.text.trim(), old = store.profile[f.key] ?? '';
        if (nv == old) continue;
        if (f.sens && old.isNotEmpty) {
          store.approvals.add(Approval('Profile change', '${f.label}: "$old" → "$nv"', onApprove: () => store.profile[f.key] = nv));
          approval++;
        } else {
          store.profile[f.key] = nv;
          direct++;
        }
      }
    }
    store.log('Profile updated');
    toast(context, 'Saved $direct change(s). $approval sensitive change(s) sent for admin approval.');
  }

  Future<void> upload() async {
    final r = await formDialog(context, 'Upload document', ['Document type', 'File name', 'Size (MB)'], options: {'Document type': Content.docTypes});
    if (r == null) return;
    final ext = r['File name']!.split('.').last.toLowerCase();
    final mb = double.tryParse(r['Size (MB)']!) ?? 99;
    if (!['pdf', 'jpg', 'jpeg', 'png', 'docx', 'pptx'].contains(ext)) return toast(context, 'File type not allowed (PDF, JPG, PNG, DOCX, PPTX).');
    if (mb > 10) return toast(context, 'File is larger than 10 MB.');
    final d = {'type': r['Document type']!, 'file': r['File name']!, 'status': 'Pending'};
    store.docs.add(d);
    store.approvals.add(Approval('Document', '${d['type']} – ${d['file']}', onApprove: () => d['status'] = 'Verified'));
    setState(() {});
    toast(context, 'Uploaded and malware scan passed (simulated). Awaiting verification.');
  }

  Future<void> addMember() async {
    final r = await formDialog(context, 'Add team member', ['Name', 'Role', 'Email', 'Phone', 'LinkedIn']);
    if (r == null) return;
    store.team.add({'name': r['Name']!, 'role': r['Role']!, 'email': r['Email']!, 'phone': r['Phone']!, 'linkedin': r['LinkedIn']!});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => PortalScaffold(
        title: 'Startup Profile',
        current: '/portal/profile',
        items: incItems,
        body: () {
          final total = groups.values.fold<int>(0, (a, g) => a + g.length);
          final filled = cs.values.where((c) => c.text.trim().isNotEmpty).length;
          final pct = (filled + (store.docs.length > 3 ? 3 : store.docs.length)) / (total + 3);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome, ${store.me!.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: LinearProgressIndicator(value: pct, minHeight: 8)),
              const SizedBox(width: 12),
              Text('${(pct * 100).round()}% complete'),
            ]),
            Form(
              key: _k,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final g in groups.entries) ...[
                  h(g.key),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(spacing: 16, runSpacing: 14, children: [
                        for (final f in g.value)
                          SizedBox(
                            width: f.lines > 1 ? 600 : 290,
                            child: TextFormField(
                              controller: cs[f.key],
                              maxLines: f.lines,
                              onChanged: (_) => setState(() {}),
                              validator: f.check,
                              decoration: InputDecoration(labelText: f.label, helperText: f.sens ? 'Changes need admin approval' : null),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('Save profile')),
              ]),
            ),
            h('Founders & team'),
            Card(child: Column(children: [
              for (final m in store.team) ListTile(leading: const Icon(Icons.person), title: Text('${m['name']} – ${m['role']}'), subtitle: Text('${m['email']} · ${m['phone']} · ${m['linkedin']}')),
              Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: addMember, icon: const Icon(Icons.add), label: const Text('Add member'))),
            ])),
            h('Document vault'),
            Card(child: Column(children: [
              for (final d in store.docs) ListTile(leading: const Icon(Icons.description), title: Text(d['type']!), subtitle: Text(d['file']!), trailing: statusChip(d['status']!)),
              Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: upload, icon: const Icon(Icons.upload_file), label: const Text('Upload document'))),
            ])),
          ]);
        },
      );
}
