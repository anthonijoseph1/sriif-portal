import 'package:flutter/material.dart';
import 'package:sriif/core/ui.dart';
import '../config.dart';
import '../core/widgets.dart';
import '../core/ui.dart';
import '../core/dropzone.dart';

// PROGRESS  –  incubation stage, milestone timeline (newest first), quarterly reports with trend chart.

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});
  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String filter = 'All';
  bool newestFirst = true;
  final open = <Milestone>{}; // milestones whose evidence uploader is expanded

  static const stages = [
    ['Onboarded', Icons.login],
    ['Active', Icons.rocket_launch_outlined],
    ['Graduated', Icons.school_outlined],
    ['Exited', Icons.flag_outlined],
  ];

  String _short(double v) => v >= 10000000
      ? '₹${(v / 10000000).toStringAsFixed(1)} Cr'
      : (v >= 100000 ? '₹${(v / 100000).toStringAsFixed(1)} L' : inr(v));
  String _num(double v) => inr(v).substring(1);

  void _setStatus(Milestone m, String s) {
    m.status = s;
    m.doneOn = s == 'Completed' ? fmt(DateTime.now()) : '';
    store.notices.insert(0, 'Milestone "${m.title}" marked $s.');
    store.log('Milestone ${m.title} → $s');
    store.refresh();
    setState(() {});
  }

  void _addEvidence(Milestone m, List<PickedFile> files) {
    for (final f in files) {
      m.files.add(DocFile('Evidence', f.name, f.size, bytes: f.bytes));
    }
    m.evidence = m.files.map((f) => f.name).join(', ');
    store.log('Evidence added to ${m.title}');
    setState(() => open.remove(m));
    toast(context, '${files.length} file(s) attached to "${m.title}".');
  }

  Future<void> _reportDialog() async {
    final taken = store.reports.map((r) => r.period).toSet();
    final free = Opts.reportPeriods.where((p) => !taken.contains(p)).toList();
    if (free.isEmpty) {
      return toast(context, 'All reporting periods are already submitted.');
    }
    String period = free.first;
    final rev = TextEditingController(),
        users = TextEditingController(),
        fund = TextEditingController(),
        jobs = TextEditingController(),
        achv = TextEditingController();
    final names = <String>[];
    final key = GlobalKey<FormState>();
    String? numCheck(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

    await modalSheet<void>(
      context,
      title: 'Quarterly progress report',
      subtitle: 'Share your numbers with SRIIF and your mentors',
      icon: Icons.assignment_outlined,
      body: (ctx, set) => Form(
        key: key,
        child: LayoutBuilder(
          builder: (c, box) {
            final half = box.maxWidth >= 500
                ? ((box.maxWidth - 16) / 2).floorToDouble()
                : box.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dropdown(
                  'Reporting period',
                  period,
                  free,
                  (v) => set(() => period = v ?? period),
                  icon: Icons.date_range_outlined,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: half,
                      child: TextFormField(
                        controller: rev,
                        keyboardType: TextInputType.number,
                        inputFormatters: [digitsOnly],
                        decoration: deco(
                          'Revenue',
                          prefix: '₹ ',
                          icon: Icons.payments_outlined,
                        ),
                        validator: numCheck,
                      ),
                    ),
                    SizedBox(
                      width: half,
                      child: TextFormField(
                        controller: users,
                        keyboardType: TextInputType.number,
                        inputFormatters: [digitsOnly],
                        decoration: deco(
                          'Users / customers',
                          icon: Icons.people_outline,
                        ),
                        validator: numCheck,
                      ),
                    ),
                    SizedBox(
                      width: half,
                      child: TextFormField(
                        controller: fund,
                        keyboardType: TextInputType.number,
                        inputFormatters: [digitsOnly],
                        decoration: deco(
                          'Funding raised',
                          prefix: '₹ ',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        validator: numCheck,
                      ),
                    ),
                    SizedBox(
                      width: half,
                      child: TextFormField(
                        controller: jobs,
                        keyboardType: TextInputType.number,
                        inputFormatters: [digitsOnly],
                        decoration: deco(
                          'Jobs created',
                          icon: Icons.work_outline,
                        ),
                        validator: numCheck,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: achv,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: deco(
                    'Key achievements',
                    icon: Icons.emoji_events_outlined,
                  ),
                  validator: V.req,
                ),
                const SizedBox(height: 8),
                FileDropZone(
                  compact: true,
                  multiple: true,
                  onFiles: (f) => set(() => names.addAll(f.map((e) => e.name))),
                ),
                if (names.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final n in names)
                          Chip(
                            label: Text(n),
                            onDeleted: () => set(() => names.remove(n)),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: (ctx, set) => [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.send_outlined),
          label: const Text('Submit report'),
          onPressed: () {
            if (!key.currentState!.validate()) return;
            store.reports.add(
              Report(
                period,
                inr(numOf(rev.text)),
                _num(numOf(users.text)),
                inr(numOf(fund.text)),
                _num(numOf(jobs.text)),
                achv.text.trim(),
              ),
            );
            store.notices.insert(0, 'Progress report submitted for $period.');
            store.log('Report submitted: $period');
            Navigator.pop(ctx);
            setState(() {});
            toast(
              context,
              'Report submitted. Your mentor and SRIIF staff will review it.',
            );
          },
        ),
      ],
    );
  }

  // ───────────── UI pieces ─────────────
  Widget _stageBar() {
    final cur = stages.indexWhere((s) => s[0] == store.stage);
    return Panel(
      title: 'Incubation stage',
      icon: Icons.stairs_outlined,
      child: Row(
        children: [
          for (var i = 0; i < stages.length; i++) ...[
            Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: i < cur
                      ? Colors.green
                      : (i == cur ? Brand.primary : Colors.black12),
                  child: Icon(
                    i < cur ? Icons.check : stages[i][1] as IconData,
                    color: i <= cur ? Colors.white : Colors.black38,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stages[i][0] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == cur ? FontWeight.w800 : FontWeight.w500,
                    color: i == cur ? Brand.primary : Colors.black54,
                  ),
                ),
              ],
            ),
            if (i < stages.length - 1)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 22, left: 6, right: 6),
                  decoration: BoxDecoration(
                    color: i < cur ? Colors.green : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _summary(bool wide) {
    final done = store.milestones.where((m) => m.status == 'Completed').length;
    final prog = store.milestones
        .where((m) => m.status == 'In progress')
        .length;
    final over = store.milestones.where((m) => m.overdue).length;
    final upcoming =
        store.milestones.where((m) => m.status != 'Completed').toList()
          ..sort((a, b) => a.when.compareTo(b.when));
    final nextM = upcoming.isEmpty ? null : upcoming.first;
    return Panel(
      child: Wrap(
        spacing: 28,
        runSpacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: store.completion,
                  strokeWidth: 10,
                  backgroundColor: Colors.black12,
                  color: Colors.green,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(store.completion * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'complete',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              StatTile(
                'Completed',
                '$done',
                Icons.check_circle_outline,
                color: Colors.green,
                width: 170,
              ),
              StatTile(
                'In progress',
                '$prog',
                Icons.autorenew,
                color: Colors.orange.shade800,
                width: 170,
              ),
              StatTile(
                'Overdue',
                '$over',
                Icons.warning_amber_outlined,
                color: over > 0 ? Colors.redAccent : Colors.blueGrey,
                width: 170,
              ),
            ],
          ),
          if (nextM != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Brand.primary.withOpacity(.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEXT DEADLINE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.black45,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextM.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      nextM.date,
                      style: TextStyle(
                        color: nextM.overdue ? Colors.redAccent : Brand.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _milestoneRow(Milestone m, bool last) {
    final c = m.status == 'Completed'
        ? Colors.green
        : (m.overdue
              ? Colors.redAccent
              : (m.status == 'In progress' ? Brand.accent : Colors.blueGrey));
    final p = fmt(m.when).split(' ');
    final hasDate = m.when.year < 2100;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 62,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: [
                  Text(
                    hasDate ? p[0] : '–',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Brand.dark,
                    ),
                  ),
                  Text(
                    hasDate ? '${p[1]} ${p[2]}' : '',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: m.status == 'Completed' ? c : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: c, width: 3),
                  ),
                  child: m.status == 'Completed'
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: Colors.black12)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border(
                    left: BorderSide(color: c, width: 4),
                    top: const BorderSide(color: kBorder),
                    right: const BorderSide(color: kBorder),
                    bottom: const BorderSide(color: kBorder),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          m.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        statusChip(m.status),
                        if (m.overdue)
                          tag(
                            'Overdue',
                            color: Colors.redAccent,
                            icon: Icons.warning_amber_outlined,
                          ),
                        if (m.doneOn.isNotEmpty)
                          tag('Completed ${m.doneOn}', color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.desc,
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: 'Not started',
                          label: Text('Not started'),
                        ),
                        ButtonSegment(
                          value: 'In progress',
                          label: Text('In progress'),
                        ),
                        ButtonSegment(
                          value: 'Completed',
                          label: Text('Completed'),
                        ),
                      ],
                      selected: {m.status},
                      onSelectionChanged: (s) => _setStatus(m, s.first),
                    ),
                    if (m.files.isNotEmpty || m.evidence.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (m.files.isEmpty)
                            tag(
                              m.evidence,
                              color: Brand.primary,
                              icon: Icons.attach_file,
                            ),
                          for (final f in m.files)
                            tag(
                              f.name,
                              color: Brand.primary,
                              icon: fileIcon(f.ext),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => setState(
                        () => open.contains(m) ? open.remove(m) : open.add(m),
                      ),
                      icon: Icon(
                        open.contains(m)
                            ? Icons.expand_less
                            : Icons.attach_file,
                        size: 18,
                      ),
                      label: Text(
                        open.contains(m) ? 'Hide uploader' : 'Add evidence',
                      ),
                    ),
                    if (open.contains(m))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: FileDropZone(
                          compact: true,
                          onFiles: (f) => _addEvidence(m, f),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestones() {
    var list = store.milestones
        .where(
          (m) =>
              filter == 'All' ||
              (filter == 'Overdue' ? m.overdue : m.status == filter),
        )
        .toList();
    list.sort(
      (a, b) =>
          newestFirst ? b.when.compareTo(a.when) : a.when.compareTo(b.when),
    );
    int count(String f) => f == 'All'
        ? store.milestones.length
        : store.milestones
              .where((m) => f == 'Overdue' ? m.overdue : m.status == f)
              .length;
    return Panel(
      title: 'Milestones',
      icon: Icons.timeline,
      trailing: TextButton.icon(
        onPressed: () => setState(() => newestFirst = !newestFirst),
        icon: Icon(
          newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
          size: 16,
        ),
        label: Text(newestFirst ? 'Newest first' : 'Oldest first'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in const [
                'All',
                'In progress',
                'Completed',
                'Not started',
                'Overdue',
              ])
                ChoiceChip(
                  label: Text('$f (${count(f)})'),
                  selected: filter == f,
                  onSelected: (_) => setState(() => filter = f),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const EmptyState(
              Icons.flag_outlined,
              'No milestones here',
              'Nothing matches this filter.',
            ),
          for (var i = 0; i < list.length; i++)
            _milestoneRow(list[i], i == list.length - 1),
        ],
      ),
    );
  }

  Widget _reports() {
    final rs = store.reports;
    final last = rs.isEmpty ? null : rs.last;
    final prev = rs.length > 1 ? rs[rs.length - 2] : null;
    String delta(double a, double b) => b == 0
        ? ''
        : '${a >= b ? '▲' : '▼'} ${((a - b).abs() / b * 100).round()}% vs last quarter';
    final maxRev = rs.fold(
      1.0,
      (a, r) => numOf(r.revenue) > a ? numOf(r.revenue) : a,
    );
    return Column(
      children: [
        Panel(
          title: 'Quarterly reports',
          icon: Icons.assignment_outlined,
          trailing: FilledButton.icon(
            onPressed: _reportDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Submit'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (last != null) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatTile(
                      'Revenue',
                      last.revenue,
                      Icons.payments_outlined,
                      color: Colors.green,
                      sub: prev == null
                          ? last.period
                          : delta(numOf(last.revenue), numOf(prev.revenue)),
                      width: 220,
                    ),
                    StatTile(
                      'Users',
                      last.users,
                      Icons.people_outline,
                      sub: prev == null
                          ? ''
                          : delta(numOf(last.users), numOf(prev.users)),
                      width: 220,
                    ),
                    StatTile(
                      'Funding raised',
                      last.funding,
                      Icons.account_balance_wallet_outlined,
                      color: Colors.indigo,
                      width: 220,
                    ),
                    StatTile(
                      'Jobs created',
                      last.jobs,
                      Icons.work_outline,
                      color: Colors.orange.shade800,
                      width: 220,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Revenue trend',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 170,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final r in rs)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _short(numOf(r.revenue)),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 10 + 110 * numOf(r.revenue) / maxRev,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Brand.primary,
                                        Color(0xFF1B6CA8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  r.period.split(' ').first,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 32),
              ],
              if (rs.isEmpty)
                const EmptyState(
                  Icons.assignment_outlined,
                  'No reports yet',
                  'Submit your first quarterly report.',
                ),
              for (final r in rs.reversed)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Brand.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.period,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (r.rating > 0)
                            Text(
                              '★' * r.rating,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                              ),
                            )
                          else
                            tag(
                              'Awaiting review',
                              color: Colors.orange.shade800,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Revenue ${r.revenue} · Users ${r.users} · Funding ${r.funding} · Jobs ${r.jobs}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(r.achv),
                      if (r.comment.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 15,
                                color: Brand.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.comment,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Brand.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PortalScaffold(
    title: 'Progress',
    current: '/portal/progress',
    items: incItems,
    body: () {
      final wide = MediaQuery.of(context).size.width >= 1100;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(
            'Progress',
            'Track your stage, milestones and quarterly numbers.',
          ),
          _stageBar(),
          const SizedBox(height: 18),
          _summary(wide),
          const SizedBox(height: 18),
          wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _milestones()),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _reports()),
                  ],
                )
              : Column(
                  children: [
                    _milestones(),
                    const SizedBox(height: 18),
                    _reports(),
                  ],
                ),
        ],
      );
    },
  );
}
