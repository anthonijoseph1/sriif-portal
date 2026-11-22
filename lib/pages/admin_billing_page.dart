import 'package:flutter/material.dart';
import '../config.dart';
import '../core/widgets.dart';

// ═════════════════ SEATS & BILLING (FR-ADM-005, FR-BIL-001/003/004) ═════════════════
class AdminBilling extends StatefulWidget {
  const AdminBilling({super.key});
  @override
  State<AdminBilling> createState() => _AdminBillingState();
}

class _AdminBillingState extends State<AdminBilling> {
  Future<void> editRate(Seat s) async {
    final r = await formDialog(context, 'Rate for ${s.name}', ['Monthly rate (₹)']);
    final v = int.tryParse(r?.values.first ?? '');
    if (v != null) { s.rate = v; store.log('Rate of ${s.name} set to $v'); setState(() {}); }
  }

  Future<void> addSeat() async {
    final r = await formDialog(context, 'New seat type', ['Name', 'Monthly rate (₹)']);
    final v = int.tryParse(r?['Monthly rate (₹)'] ?? '');
    if (r != null && v != null) { store.seatTypes.add(Seat(r['Name']!, v)); store.log('Seat type ${r['Name']} added'); setState(() {}); }
  }

  Future<void> tariff() async {
    final r = await formDialog(context, 'Instrument tariff per quarter', ['Amount (₹)']);
    final v = double.tryParse(r?.values.first ?? '');
    if (v != null) { store.instrumentTariff = v; store.log('Instrument tariff set to $v'); setState(() {}); }
  }

  Future<void> allocate() async {
    final r = await formDialog(context, 'Allocate seats to ${store.me == null ? '' : 'GreenLeaf Agritech'}', ['Seat type', 'Quantity (0 removes)'],
        options: {'Seat type': [for (final s in store.seatTypes) s.name]});
    final q = int.tryParse(r?['Quantity (0 removes)'] ?? '');
    if (r != null && q != null) {
      q <= 0 ? store.mySeats.remove(r['Seat type']) : store.mySeats[r['Seat type']!] = q;
      store.log('Allocated ${r['Seat type']} × $q to GreenLeaf Agritech');
      setState(() {});
    }
  }

  Future<void> adjust() async {
    final r = await formDialog(context, 'One-time charge / discount', ['Description', 'Amount (₹) – negative for discount']);
    final v = double.tryParse(r?['Amount (₹) – negative for discount'] ?? '');
    if (r != null && v != null) { store.adjustments.add(MapEntry(r['Description']!, v)); store.log('Adjustment queued: ${r['Description']} $v'); setState(() {}); }
  }

  void generate() {
    final p = store.quarters[store.qIndex % store.quarters.length];
    final lines = <MapEntry<String, double>>[
      for (final e in store.mySeats.entries)
        MapEntry('${e.key} × ${e.value} (3 months)', (store.seatTypes.firstWhere((s) => s.name == e.key).rate * e.value * 3).toDouble()),
      MapEntry('Instrument usage tariff', store.instrumentTariff),
      ...store.adjustments,
    ];
    store.invCounter++;
    final no = 'SRIIF/26-27/${store.invCounter.toString().padLeft(4, '0')}';
    store.invoices.add(Invoice(no, p, DateTime.now().add(const Duration(days: 15)), lines));
    store.adjustments.clear();
    store.qIndex++;
    store.notices.insert(0, 'Invoice $no generated for $p – email sent.');
    store.log('Generated invoice $no for $p');
    toast(context, 'Invoice $no generated. Email sent (simulated).');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => AdminPage('Seats & Billing', '/admin/billing', () => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h('Seat types & monthly rates'),
        Card(child: Column(children: [
          for (final s in store.seatTypes) ListTile(title: Text(s.name), subtitle: Text('${inr(s.rate.toDouble())} / month'), trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => editRate(s))),
          ListTile(title: const Text('Instrument usage tariff'), subtitle: Text('${inr(store.instrumentTariff)} / quarter'), trailing: IconButton(icon: const Icon(Icons.edit), onPressed: tariff)),
          Wrap(spacing: 8, children: [
            TextButton.icon(onPressed: addSeat, icon: const Icon(Icons.add), label: const Text('Add seat type')),
            TextButton.icon(onPressed: allocate, icon: const Icon(Icons.event_seat), label: const Text('Allocate seats')),
          ]),
        ])),
        h('Generate quarterly invoice'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Next period: ${store.quarters[store.qIndex % store.quarters.length]}'),
          for (final a in store.adjustments) Text('Pending adjustment: ${a.key} (${inr(a.value)})'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            OutlinedButton(onPressed: adjust, child: const Text('Add charge / discount')),
            FilledButton(onPressed: generate, child: const Text('Generate invoice')),
          ]),
        ]))),
        h('All invoices'),
        for (final i in store.invoices.reversed)
          Card(child: ListTile(
            title: Text('${i.no} · ${i.period}'),
            subtitle: Text('${inr(i.total)} · Due ${fmt(i.due)}${i.pending ? ' · gateway pending' : ''}'),
            trailing: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              statusChip(i.shown),
              if (i.status == 'Due') TextButton(onPressed: () { i.status = 'Paid'; i.pending = false; i.receipt = 'RCT-${i.no.split('/').last}'; store.log('Reconciled/marked paid ${i.no}'); setState(() {}); }, child: Text(i.pending ? 'Reconcile' : 'Mark paid')),
              if (i.status == 'Due') TextButton(onPressed: () { i.status = 'Waived'; store.log('Waived ${i.no}'); setState(() {}); }, child: const Text('Waive')),
            ]),
          )),
      ]));
}
