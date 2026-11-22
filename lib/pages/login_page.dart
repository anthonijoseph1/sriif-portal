import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';
import '../core/site_kit.dart';

// ═════════════════════════════════════════════════════════════
// LOGIN + REGISTER (OTP)
// ═════════════════════════════════════════════════════════════
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool register = false;
  final id = TextEditingController();
  final _k = GlobalKey<FormState>();
  final fn = TextEditingController(), sn = TextEditingController(), em = TextEditingController(), ph = TextEditingController();
  bool emailOk = false, phoneOk = false;

  AppUser? find(String v) {
    v = v.trim().toLowerCase();
    for (final u in store.users) {
      if (u.email.toLowerCase() == v || u.phone == v) return u;
    }
    return null;
  }

  String? loginCheck() {
    if (id.text.trim().isEmpty) return 'Enter your email or phone';
    final u = find(id.text);
    if (u == null) return 'No account found. Please register.';
    if (u.status == 'pending') return 'Your account is awaiting SRIIF approval.';
    if (u.status != 'active') return 'Account is deactivated. Contact SRIIF.';
    return null;
  }

  @override
  Widget build(BuildContext context) => PublicScaffold(
        current: '/login',
        body: () => Box(
          max: 520,
          child: Column(children: [
            SegmentedButton<bool>(
              segments: const [ButtonSegment(value: false, label: Text('Login')), ButtonSegment(value: true, label: Text('Register'))],
              selected: {register},
              onSelectionChanged: (s) => setState(() => register = s.first),
            ),
            const SizedBox(height: 16),
            Card(child: Padding(padding: const EdgeInsets.all(20), child: register ? _registerForm() : _loginForm())),
            const SizedBox(height: 12),
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text('DEMO LOGINS (OTP ${Brand.demoOtp})\n'
                    'Incubatee: demo@startup.in\nMentor: mentor@sriif.in\nSRIIF Staff / Admin: admin@sriif.in'),
              ),
            ),
          ]),
        ),
      );

  Widget _loginForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Incubatee / Staff Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        TextField(controller: id, decoration: const InputDecoration(labelText: 'Email or mobile number')),
        const SizedBox(height: 12),
        OtpBox(
          key: const ValueKey('login-otp'),
          label: 'Login',
          beforeSend: loginCheck,
          onVerified: () {
            final u = find(id.text)!;
            store.login(u);
            go(context, homeFor(u));
          },
        ),
      ]);

  Widget _registerForm() => Form(
        key: _k,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Register your startup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextFormField(controller: fn, decoration: const InputDecoration(labelText: 'Founder name'), validator: V.req),
          const SizedBox(height: 12),
          TextFormField(controller: sn, decoration: const InputDecoration(labelText: 'Startup name'), validator: V.req),
          const SizedBox(height: 12),
          TextFormField(controller: em, decoration: const InputDecoration(labelText: 'Email'), validator: V.email),
          const SizedBox(height: 12),
          OtpBox(key: const ValueKey('reg-email'), label: 'Email', beforeSend: () => V.email(em.text), onVerified: () => setState(() => emailOk = true)),
          const SizedBox(height: 12),
          TextFormField(controller: ph, decoration: const InputDecoration(labelText: 'Mobile number'), validator: V.phone),
          const SizedBox(height: 12),
          OtpBox(key: const ValueKey('reg-phone'), label: 'Phone', beforeSend: () => V.phone(ph.text), onVerified: () => setState(() => phoneOk = true)),
          const SizedBox(height: 16),
          const Text('Account activates once the email OR phone OTP is verified, then SRIIF staff approve it.', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: (emailOk || phoneOk)
                ? () {
                    if (!_k.currentState!.validate()) return;
                    if (find(em.text) != null || find(ph.text) != null) {
                      toast(context, 'Email or phone is already registered.');
                      return;
                    }
                    final u = AppUser(fn.text.trim(), sn.text.trim(), em.text.trim(), ph.text.trim(), 'incubatee', 'pending');
                    store.users.add(u);
                    store.approvals.add(Approval('Registration', '${u.startup} – ${u.name} (${u.email})', onApprove: () => u.status = 'active'));
                    store.refresh();
                    toast(context, 'Registered! Waiting for SRIIF approval. (Log in as admin@sriif.in to approve.)');
                    setState(() { register = false; emailOk = phoneOk = false; });
                  }
                : null,
            child: const Text('Submit registration'),
          ),
        ]),
      );
}

/// OTP widget with expiry (10 min), 3 resends and 5-attempt lockout (FR-AUTH-005). Demo OTP shown on screen.
class OtpBox extends StatefulWidget {
  final String label;
  final String? Function()? beforeSend;
  final VoidCallback onVerified;
  const OtpBox({super.key, required this.label, required this.onVerified, this.beforeSend});
  @override
  State<OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<OtpBox> {
  final c = TextEditingController();
  bool sent = false, done = false;
  int resends = 0, fails = 0;
  DateTime? sentAt, lockUntil;
  String? msg;

  bool get locked => lockUntil != null && DateTime.now().isBefore(lockUntil!);

  void send() {
    if (locked) return setState(() => msg = 'Too many wrong attempts. Try again in a few minutes.');
    final err = widget.beforeSend?.call();
    if (err != null) return setState(() => msg = err);
    if (sent && resends >= Brand.otpMaxResend) return setState(() => msg = 'Resend limit reached.');
    setState(() {
      if (sent) resends++;
      sent = true;
      sentAt = DateTime.now();
      c.clear();
      msg = 'OTP sent. (Demo OTP: ${Brand.demoOtp})';
    });
  }

  void verify() {
    if (locked) return setState(() => msg = 'Locked. Try again in a few minutes.');
    if (DateTime.now().difference(sentAt!).inMinutes >= Brand.otpExpiryMin) return setState(() => msg = 'OTP expired. Please resend.');
    if (c.text.trim() == Brand.demoOtp) {
      setState(() => done = true);
      widget.onVerified();
    } else {
      setState(() {
        fails++;
        if (fails >= Brand.otpMaxFail) {
          lockUntil = DateTime.now().add(const Duration(minutes: 5));
          fails = 0;
          msg = 'Too many wrong attempts. Locked for 5 minutes.';
        } else {
          msg = 'Wrong OTP. ${Brand.otpMaxFail - fails} attempts left.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (done) return Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 8), Text('${widget.label} verified')]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!sent)
        OutlinedButton(onPressed: send, child: Text('Send ${widget.label} OTP'))
      else
        Row(children: [
          Expanded(child: TextField(controller: c, maxLength: 6, decoration: InputDecoration(labelText: '${widget.label} OTP', counterText: ''))),
          const SizedBox(width: 8),
          FilledButton(onPressed: verify, child: const Text('Verify')),
          TextButton(onPressed: send, child: Text('Resend (${Brand.otpMaxResend - resends})')),
        ]),
      if (msg != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(msg!, style: const TextStyle(fontSize: 12, color: Colors.black54))),
    ]);
  }
}
