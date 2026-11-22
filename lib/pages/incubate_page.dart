import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';
import '../core/site_kit.dart';

// ═════════════════════════════════════════════════════════════
// INCUBATE (enquiry form)
// ═════════════════════════════════════════════════════════════
class IncubatePage extends StatefulWidget {
  const IncubatePage({super.key});
  @override
  State<IncubatePage> createState() => _IncubatePageState();
}

class _IncubatePageState extends State<IncubatePage> {
  final _k = GlobalKey<FormState>();
  final name = TextEditingController(), startup = TextEditingController(), email = TextEditingController(), phone = TextEditingController(), idea = TextEditingController();
  String stage = 'Idea';

  @override
  Widget build(BuildContext context) => PublicScaffold(
        current: '/incubate',
        body: () => Column(children: [
          const PageHeader('Incubate with SRIIF', 'Learn about the program and send us your application'),
          Box(
            max: 800,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('How it works', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('1. Submit the form below   2. SRIIF screens your application   3. Pitch to the panel   4. Get onboarded and register on the portal.'),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _k,
                    child: Column(children: [
                      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Founder name'), validator: V.req),
                      const SizedBox(height: 12),
                      TextFormField(controller: startup, decoration: const InputDecoration(labelText: 'Startup / idea name'), validator: V.req),
                      const SizedBox(height: 12),
                      TextFormField(controller: email, decoration: const InputDecoration(labelText: 'Email'), validator: V.email),
                      const SizedBox(height: 12),
                      TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Mobile'), validator: V.phone),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          value: stage,
                          decoration: const InputDecoration(labelText: 'Stage'),
                          items: [for (final s in ['Idea', 'Prototype', 'Early revenue', 'Growth']) DropdownMenuItem(value: s, child: Text(s))],
                          onChanged: (v) => stage = v!),
                      const SizedBox(height: 12),
                      TextFormField(controller: idea, maxLines: 4, decoration: const InputDecoration(labelText: 'Describe your idea'), validator: V.req),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                            onPressed: () {
                              if (!_k.currentState!.validate()) return;
                              store.enquiries.add('${startup.text} – ${name.text} ($stage)');
                              showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                        title: const Text('Application received'),
                                        content: const Text('Thank you! The SRIIF team will contact you by email.'),
                                        actions: [TextButton(onPressed: () { Navigator.pop(ctx); go(context, '/'); }, child: const Text('OK'))],
                                      ));
                            },
                            child: const Text('Submit application')),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      );
}
