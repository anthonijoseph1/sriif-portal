import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sriif/core/ui.dart';
import '../config.dart';
import '../core/widgets.dart';

// BILLING  –  amount due, seats, invoices, payment, receipts.

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});
  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  String filter = 'All';

  String _countdown(Invoice i) {
    final d = daysTo(i.due);
    return d > 0
        ? 'Due in $d day${d == 1 ? '' : 's'}'
        : (d == 0 ? 'Due today' : 'Overdue by ${-d} day${d == -1 ? '' : 's'}');
  }

  // ───────────── seat change ─────────────
  Future<void> _seatDialog() async {
    String type = store.seatTypes.first.name, mode = 'Add', reason = '';
    int qty = 1;
    final now = DateTime.now();
    String date = fmt(DateTime(now.year, now.month + 1, 1));
    String? err;
    await modalSheet<void>(
      context,
      title: 'Request seat change',
      subtitle: 'SRIIF will review and confirm your request',
      icon: Icons.event_seat_outlined,
      width: 560,
      body: (ctx, set) {
        final seat = store.seatTypes.firstWhere((s) => s.name == type);
        final have = store.mySeats[type] ?? 0;
        final delta = seat.rate * qty * (mode == 'Add' ? 1 : -1);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Add',
                  icon: Icon(Icons.add),
                  label: Text('Add seats'),
                ),
                ButtonSegment(
                  value: 'Release',
                  icon: Icon(Icons.remove),
                  label: Text('Release seats'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) => set(() {
                mode = s.first;
                qty = 1;
                err = null;
              }),
            ),
            const SizedBox(height: 20),
            dropdown(
              'Seat type',
              type,
              [for (final s in store.seatTypes) s.name],
              (v) => set(() {
                type = v ?? type;
                qty = 1;
              }),
              icon: Icons.event_seat_outlined,
              helper: 'You currently hold $have × $type',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Number of seats',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Stepper2(
                  value: qty,
                  min: 1,
                  max: mode == 'Add' ? 20 : (have == 0 ? 1 : have),
                  onChanged: (v) => set(() => qty = v),
                ),
              ],
            ),
            const SizedBox(height: 18),
            dateField(
              ctx,
              'Effective from',
              date,
              (d) => set(() => date = d),
              first: DateTime.now(),
              last: DateTime.now().add(const Duration(days: 365)),
            ),
            const SizedBox(height: 18),
            TextFormField(
              maxLines: 2,
              onChanged: (v) => reason = v,
              decoration: deco('Reason (optional)', icon: Icons.notes_outlined),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (delta >= 0 ? Colors.orange : Colors.green).withOpacity(
                  .08,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    delta >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: delta >= 0 ? Colors.orange.shade800 : Colors.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Estimated change: ${delta >= 0 ? '+' : '–'}${inr(delta.abs().toDouble())} per month (excl. GST)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            if (err != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  err!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        );
      },
      actions: (ctx, set) => [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.send_outlined),
          label: const Text('Submit request'),
          onPressed: () {
            final have = store.mySeats[type] ?? 0;
            if (mode == 'Release' && qty > have) {
              set(() => err = 'You only hold $have × $type.');
              return;
            }
            final q = qty, t = type, m = mode;
            store.approvals.add(
              Approval(
                'Seat request',
                '${store.me!.startup}: $t ${m == 'Add' ? '+' : '–'}$q from $date${reason.isEmpty ? '' : ' ($reason)'}',
                onApprove: () {
                  final n = (store.mySeats[t] ?? 0) + (m == 'Add' ? q : -q);
                  n <= 0 ? store.mySeats.remove(t) : store.mySeats[t] = n;
                },
              ),
            );
            store.notices.insert(
              0,
              'Seat request submitted: $t ${m == 'Add' ? '+' : '–'}$q',
            );
            store.log('Seat request: $t $m $q');
            Navigator.pop(ctx);
            setState(() {});
            toast(context, 'Seat request sent to SRIIF for approval.');
          },
        ),
      ],
    );
  }

  // ───────────── invoice view ─────────────
  void _view(Invoice i) => modalSheet<void>(
    context,
    title: 'Invoice ${i.no}',
    subtitle: '${i.period}  ·  Due ${fmt(i.due)}',
    icon: Icons.receipt_long_outlined,
    width: 600,
    body: (ctx, set) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BILLED TO',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      color: Colors.black45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    store.profile['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    store.me?.email ?? '',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            statusChip(i.shown),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Brand.surface,
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      'Amount',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              for (final l in i.lines)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: Text(l.key)),
                      Text(inr(l.value)),
                    ],
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Row(
                  children: [
                    const Expanded(child: Text('Subtotal')),
                    Text(inr(i.sub)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('GST (${(Brand.gstRate * 100).round()}%)'),
                    ),
                    Text(inr(i.gst)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Brand.primary.withOpacity(.06),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      inr(i.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Brand.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (i.receipt != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: tag(
              'Paid · Receipt ${i.receipt}',
              color: Colors.green,
              icon: Icons.check_circle_outline,
            ),
          ),
      ],
    ),
    actions: (ctx, set) => [
      TextButton.icon(
        onPressed: () {
          Navigator.pop(ctx);
          toast(context, 'PDF downloaded (simulated).');
        },
        icon: const Icon(Icons.download_outlined),
        label: Text(i.receipt != null ? 'Receipt PDF' : 'Invoice PDF'),
      ),
      if (i.status == 'Due' && !i.pending)
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            _pay(i);
          },
          child: const Text('Pay now'),
        ),
      OutlinedButton(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Close'),
      ),
    ],
  );

  // ───────────── payment ─────────────
  void _pay(Invoice inv) {
    String method = 'UPI', bank = Opts.banks.first, outcome = 'Success';
    bool busy = false;
    final upi = TextEditingController(),
        card = TextEditingController(),
        exp = TextEditingController(),
        cvv = TextEditingController(),
        holder = TextEditingController();
    final key = GlobalKey<FormState>();

    String? expiryCheck(String? v) {
      final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(v ?? '');
      if (m == null) return 'MM/YY';
      final mm = int.parse(m.group(1)!), yy = 2000 + int.parse(m.group(2)!);
      if (mm < 1 || mm > 12) return 'Invalid month';
      if (DateTime(yy, mm + 1, 0).isBefore(DateTime.now())) {
        return 'Card expired';
      }
      return null;
    }

    modalSheet<void>(
      context,
      title: 'Pay ${inr(inv.total)}',
      subtitle: 'Invoice ${inv.no} · ${inv.period}',
      icon: Icons.lock_outline,
      width: 560,
      body: (ctx, set) => Form(
        key: key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a payment method',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final m in const [
                  ['UPI', Icons.qr_code_2],
                  ['Card', Icons.credit_card],
                  ['Net banking', Icons.account_balance],
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: busy
                            ? null
                            : () => set(() => method = m[0] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: method == m[0]
                                ? Brand.primary.withOpacity(.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: method == m[0] ? Brand.primary : kBorder,
                              width: method == m[0] ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                m[1] as IconData,
                                color: method == m[0]
                                    ? Brand.primary
                                    : Colors.black45,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                m[0] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (method == 'UPI')
              TextFormField(
                controller: upi,
                decoration: deco(
                  'UPI ID',
                  icon: Icons.alternate_email,
                  hint: 'name@bank',
                ),
                validator: V.upi,
              ),
            if (method == 'Card') ...[
              TextFormField(
                controller: card,
                keyboardType: TextInputType.number,
                inputFormatters: [GroupFormatter(group: 4, max: 16)],
                decoration: deco(
                  'Card number',
                  icon: Icons.credit_card,
                  hint: '1234 5678 9012 3456',
                ),
                validator: (v) => (v ?? '').replaceAll(' ', '').length == 16
                    ? null
                    : 'Enter 16-digit card number',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: exp,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ExpiryFormatter()],
                      decoration: deco('Expiry', hint: 'MM/YY'),
                      validator: expiryCheck,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: cvv,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: deco('CVV'),
                      validator: (v) =>
                          (v ?? '').length >= 3 ? null : '3–4 digits',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: holder,
                textCapitalization: TextCapitalization.words,
                decoration: deco('Name on card', icon: Icons.person_outline),
                validator: V.req,
              ),
            ],
            if (method == 'Net banking')
              dropdown(
                'Select your bank',
                bank,
                Opts.banks,
                (v) => set(() => bank = v ?? bank),
                icon: Icons.account_balance_outlined,
              ),
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Demo options',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                children: [
                  dropdown(
                    'Simulate gateway result',
                    outcome,
                    const ['Success', 'Failed', 'Pending'],
                    (v) => set(() => outcome = v ?? outcome),
                  ),
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Colors.black38),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Payments are processed securely by the payment gateway (simulated).',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: (ctx, set) => [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.lock_outline),
          label: Text('Pay ${inr(inv.total)}'),
          onPressed: busy
              ? null
              : () async {
                  if (!key.currentState!.validate()) return;
                  set(() => busy = true);
                  await Future.delayed(const Duration(milliseconds: 1300));
                  if (ctx.mounted) Navigator.pop(ctx);
                  _settle(inv, outcome, method);
                },
        ),
      ],
    );
  }

  void _settle(Invoice inv, String outcome, String method) {
    if (!mounted) return;
    if (inv.status == 'Paid') {
      return toast(
        context,
        'Duplicate payment blocked – this invoice is already paid.',
      );
    }
    if (outcome == 'Success') {
      inv.status = 'Paid';
      inv.pending = false;
      inv.paidOn = DateTime.now();
      inv.receipt = 'RCT-${inv.no.split('/').last}';
      store.notices.insert(0, 'Payment received for ${inv.no} via $method');
      store.log('Paid ${inv.no} via $method');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0x1A2E7D32),
                child: Icon(Icons.check_rounded, size: 44, color: Colors.green),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment successful',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${inr(inv.total)} paid via $method',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                'Receipt ${inv.receipt}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                toast(context, 'Receipt downloaded (simulated).');
              },
              child: const Text('Download receipt'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else if (outcome == 'Failed') {
      toast(context, 'Payment failed. Nothing was charged – please try again.');
    } else {
      inv.pending = true;
      toast(
        context,
        'Payment pending. It will be reconciled with gateway records.',
      );
    }
    store.refresh();
    setState(() {});
  }

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) => PortalScaffold(
    title: 'Billing',
    current: '/portal/billing',
    items: incItems,
    body: () {
      final wide = MediaQuery.of(context).size.width >= 1000;
      final dueList = store.invoices.where((i) => i.status == 'Due').toList()
        ..sort((a, b) => a.due.compareTo(b.due));
      final outstanding = dueList.fold(0.0, (a, i) => a + i.total);
      final paidTotal = store.invoices
          .where((i) => i.status == 'Paid')
          .fold(0.0, (a, i) => a + i.total);
      final seatCount = store.mySeats.values.fold(0, (a, b) => a + b);
      final monthly = store.mySeats.entries.fold(
        0.0,
        (a, e) =>
            a +
            store.seatTypes.firstWhere((s) => s.name == e.key).rate * e.value,
      );
      final next = dueList.isEmpty ? null : dueList.first;
      final pendingReq = store.approvals
          .where((a) => a.type == 'Seat request' && a.status == 'Pending')
          .toList();
      final shown = store.invoices.reversed
          .where((i) => filter == 'All' || i.shown == filter)
          .toList();

      final hero = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: next == null
                ? [const Color(0xFF1B8A6B), const Color(0xFF2BB38A)]
                : [Brand.primary, const Color(0xFF1B6CA8)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Wrap(
          spacing: 24,
          runSpacing: 18,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  next == null ? 'You are all paid up 🎉' : 'Amount due',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null ? inr(paidTotal) : inr(outstanding),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? 'Total paid to date'
                      : '${next.no} · ${next.period}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (next != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: tag(
                      _countdown(next),
                      color: daysTo(next.due) < 0
                          ? Colors.redAccent
                          : Brand.accent,
                      icon: Icons.schedule,
                    ),
                  ),
              ],
            ),
            if (next != null)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Brand.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 20,
                      ),
                    ),
                    onPressed: next.pending ? null : () => _pay(next),
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(next.pending ? 'Payment pending' : 'Pay now'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                    ),
                    onPressed: () => _view(next),
                    child: const Text('View invoice'),
                  ),
                ],
              ),
          ],
        ),
      );

      final seats = Panel(
        title: 'My seats',
        icon: Icons.event_seat_outlined,
        trailing: OutlinedButton.icon(
          onPressed: _seatDialog,
          icon: const Icon(Icons.swap_vert, size: 18),
          label: const Text('Request change'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.mySeats.isEmpty)
              const Text(
                'No seats allocated yet.',
                style: TextStyle(color: Colors.black54),
              ),
            for (final e in store.mySeats.entries)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Brand.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Brand.primary.withOpacity(.1),
                      child: const Icon(
                        Icons.chair_alt_outlined,
                        color: Brand.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e.key} × ${e.value}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${inr(store.seatTypes.firstWhere((s) => s.name == e.key).rate.toDouble())} / seat / month',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${inr(store.seatTypes.firstWhere((s) => s.name == e.key).rate * e.value.toDouble())}/mo',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                const Icon(
                  Icons.biotech_outlined,
                  size: 18,
                  color: Colors.black45,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Instrument usage tariff: ${inr(store.instrumentTariff)} per quarter',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
            if (pendingReq.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in pendingReq)
                    tag(
                      'Pending: ${a.detail.split(': ').last}',
                      color: Colors.orange.shade800,
                      icon: Icons.hourglass_empty,
                    ),
                ],
              ),
            ],
          ],
        ),
      );

      final invoices = Panel(
        title: 'Invoices',
        icon: Icons.receipt_long_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in const [
                  'All',
                  'Due',
                  'Overdue',
                  'Pending',
                  'Paid',
                  'Waived',
                ])
                  ChoiceChip(
                    label: Text(f),
                    selected: filter == f,
                    onSelected: (_) => setState(() => filter = f),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (shown.isEmpty)
              const EmptyState(
                Icons.receipt_outlined,
                'No invoices here',
                'Nothing matches this filter.',
              ),
            for (final i in shown)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                ),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor(
                            i.shown,
                          ).withOpacity(.12),
                          child: Icon(
                            i.status == 'Paid'
                                ? Icons.check
                                : Icons.receipt_outlined,
                            color: statusColor(i.shown),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.period,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${i.no} · Due ${fmt(i.due)}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          inr(i.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(width: 12),
                        statusChip(i.shown),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'View',
                          onPressed: () => _view(i),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        IconButton(
                          tooltip: 'Download PDF',
                          onPressed: () =>
                              toast(context, 'PDF downloaded (simulated).'),
                          icon: const Icon(Icons.download_outlined),
                        ),
                        if (i.status == 'Due' && !i.pending)
                          FilledButton(
                            onPressed: () => _pay(i),
                            child: const Text('Pay'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

      final history = Panel(
        title: 'Payment history',
        icon: Icons.history,
        child: store.invoices.where((i) => i.status == 'Paid').isEmpty
            ? const EmptyState(
                Icons.payments_outlined,
                'No payments yet',
                'Your receipts will appear here.',
              )
            : Column(
                children: [
                  for (final i in store.invoices.where(
                    (i) => i.status == 'Paid',
                  ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x1A2E7D32),
                        child: Icon(Icons.check, color: Colors.green),
                      ),
                      title: Text(
                        '${inr(i.total)} · ${i.period}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${i.receipt ?? ''}${i.paidOn == null ? '' : ' · Paid ${fmt(i.paidOn!)}'}',
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            toast(context, 'Receipt downloaded (simulated).'),
                        child: const Text('Receipt'),
                      ),
                    ),
                ],
              ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hero,
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (c, box) {
              final w = wide
                  ? (box.maxWidth - 3 * 16) / 4
                  : (box.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  StatTile(
                    'Paid to date',
                    inr(paidTotal),
                    Icons.check_circle_outline,
                    color: Colors.green,
                    width: w,
                  ),
                  StatTile(
                    'Seats held',
                    '$seatCount',
                    Icons.event_seat_outlined,
                    width: w,
                  ),
                  StatTile(
                    'Seat cost / month',
                    inr(monthly),
                    Icons.calendar_month_outlined,
                    color: Colors.indigo,
                    width: w,
                  ),
                  StatTile(
                    'Instrument tariff',
                    inr(store.instrumentTariff),
                    Icons.biotech_outlined,
                    color: Colors.orange.shade800,
                    sub: 'per quarter',
                    width: w,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: invoices),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [seats, const SizedBox(height: 20), history],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    seats,
                    const SizedBox(height: 18),
                    invoices,
                    const SizedBox(height: 18),
                    history,
                  ],
                ),
        ],
      );
    },
  );
}
