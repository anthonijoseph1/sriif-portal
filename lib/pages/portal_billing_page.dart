import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ BILLING (FR-BIL) ═════════════════
class BillingPage extends StatefulWidget {
  const BillingPage({super.key});
  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  Future<void> requestSeats() async {
    final r = await formDialog(
      context,
      'Request seat change',
      ['Seat type', 'Change (+ add / – remove)'],
      options: {
        'Seat type': [for (final s in store.seatTypes) s.name],
      },
    );
    if (r == null) return;
    final q = int.tryParse(r['Change (+ add / – remove)']!);
    if (q == null || q == 0)
      return toast(context, 'Enter a number like 2 or -1');
    final t = r['Seat type']!;
    store.approvals.add(
      Approval(
        'Seat request',
        '${store.me!.startup}: $t ${q > 0 ? '+' : ''}$q',
        onApprove: () {
          final n = (store.mySeats[t] ?? 0) + q;
          n <= 0 ? store.mySeats.remove(t) : store.mySeats[t] = n;
        },
      ),
    );
    store.refresh();
    toast(context, 'Seat request sent to SRIIF.');
  }

  void view(Invoice i) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Invoice ${i.no}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${store.me!.startup} · ${i.period} · Due ${fmt(i.due)}'),
            const Divider(),
            for (final l in i.lines)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(l.key)),
                  Text(inr(l.value)),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('Subtotal'), Text(inr(i.sub))],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GST (${(Brand.gstRate * 100).round()}%)'),
                Text(inr(i.gst)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  inr(i.total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (i.receipt != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Receipt: ${i.receipt}',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            toast(context, 'PDF download is simulated in this prototype.');
          },
          child: Text(i.receipt != null ? 'Download receipt' : 'Download PDF'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  void pay(Invoice inv) {
    String method = 'UPI', outcome = 'Success';
    bool busy = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text('Pay ${inr(inv.total)}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment gateway (demo)'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    for (final m in ['UPI', 'Net banking', 'Card'])
                      ButtonSegment(value: m, label: Text(m)),
                  ],
                  selected: {method},
                  onSelectionChanged: (s) => set(() => method = s.first),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: outcome,
                  decoration: const InputDecoration(
                    labelText: 'Simulate gateway result',
                  ),
                  items: [
                    for (final o in ['Success', 'Failed', 'Pending'])
                      DropdownMenuItem(value: o, child: Text(o)),
                  ],
                  onChanged: (v) => set(() => outcome = v!),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      set(() => busy = true);
                      await Future.delayed(const Duration(seconds: 1));
                      if (ctx.mounted) Navigator.pop(ctx);
                      settle(inv, outcome, method);
                    },
              child: const Text('Pay now'),
            ),
          ],
        ),
      ),
    );
  }

  void settle(Invoice inv, String outcome, String method) {
    if (!mounted) return;
    if (inv.status == 'Paid')
      return toast(
        context,
        'Duplicate payment blocked – invoice already paid.',
      );
    if (outcome == 'Success') {
      inv.status = 'Paid';
      inv.pending = false;
      inv.receipt = 'RCT-${inv.no.split('/').last}';
      store.notices.insert(0, 'Payment received for ${inv.no} via $method');
      toast(context, 'Payment successful. Receipt ${inv.receipt} issued.');
    } else if (outcome == 'Failed') {
      toast(context, 'Payment failed. Nothing was charged – please retry.');
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

  @override
  Widget build(BuildContext context) => PortalScaffold(
    title: 'Billing',
    current: '/portal/billing',
    items: incItems,
    body: () => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        h('My seats'),
        Card(
          child: Column(
            children: [
              for (final e in store.mySeats.entries)
                ListTile(
                  leading: const Icon(Icons.event_seat),
                  title: Text('${e.key} × ${e.value}'),
                  trailing: Text(
                    '${inr(store.seatTypes.firstWhere((s) => s.name == e.key).rate.toDouble())} / month each',
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.biotech),
                title: const Text('Instrument usage tariff'),
                trailing: Text('${inr(store.instrumentTariff)} / quarter'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: requestSeats,
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('Request more / fewer seats'),
                ),
              ),
            ],
          ),
        ),
        h('Invoices (generated on the 1st of every quarter)'),
        for (final i in store.invoices.reversed)
          Card(
            child: ListTile(
              title: Text('${i.no} · ${i.period}'),
              subtitle: Text('Total ${inr(i.total)} · Due ${fmt(i.due)}'),
              trailing: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  statusChip(i.shown),
                  OutlinedButton(
                    onPressed: () => view(i),
                    child: Text(i.receipt != null ? 'Receipt' : 'View'),
                  ),
                  if (i.status == 'Due' && !i.pending)
                    FilledButton(
                      onPressed: () => pay(i),
                      child: const Text('Pay'),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
