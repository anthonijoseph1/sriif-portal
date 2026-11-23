import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';

// Modern building blocks for the portal pages: cards, tiles, avatars, inputs, formatters.

const kBorder = Color(0xFFE3E9F2);

String kb(int bytes) => bytes < 1024 * 1024
    ? '${(bytes / 1024).round()} KB'
    : '${(bytes / 1048576).toStringAsFixed(1)} MB';
int daysTo(DateTime d) => DateTime(d.year, d.month, d.day)
    .difference(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    )
    .inDays;
String greeting() {
  final h = DateTime.now().hour;
  return h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
}

IconData fileIcon(String ext) => switch (ext) {
  'pdf' => Icons.picture_as_pdf_outlined,
  'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image_outlined,
  'doc' || 'docx' => Icons.description_outlined,
  'ppt' || 'pptx' => Icons.slideshow_outlined,
  _ => Icons.insert_drive_file_outlined,
};

// ───────── page heading ─────────
class PageTitle extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> actions;
  const PageTitle(
    this.title,
    this.subtitle, {
    super.key,
    this.actions = const [],
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Brand.dark,
                letterSpacing: -.5,
              ),
            ),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                ),
              ),
          ],
        ),
        if (actions.isNotEmpty)
          Wrap(spacing: 10, runSpacing: 8, children: actions),
      ],
    ),
  );
}

// ───────── white card with optional header ─────────
class Panel extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const Panel({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0B3C6F),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Brand.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: Brand.primary),
                ),
              Expanded(
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Brand.dark,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
        ],
        child,
      ],
    ),
  );
}

// ───────── KPI tile ─────────
class StatTile extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final double width;
  const StatTile(
    this.label,
    this.value,
    this.icon, {
    super.key,
    this.sub = '',
    this.color = Brand.primary,
    this.width = 250,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kBorder),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Brand.dark,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ───────── avatar (photo or initial) ─────────
class Avatar extends StatelessWidget {
  final Uint8List? bytes;
  final String name;
  final double size;
  final double radius;
  final Color color;
  const Avatar({
    super.key,
    this.bytes,
    required this.name,
    this.size = 48,
    this.radius = 999,
    this.color = Brand.primary,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius == 999 ? size : radius),
    child: bytes != null
        ? Image.memory(bytes!, width: size, height: size, fit: BoxFit.cover)
        : Container(
            width: size,
            height: size,
            color: color.withOpacity(.12),
            child: Center(
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: size * .42,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final Widget? action;
  const EmptyState(this.icon, this.title, this.sub, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Brand.primary.withOpacity(.08),
            child: Icon(icon, size: 30, color: Brand.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 16), child: action),
        ],
      ),
    ),
  );
}

Widget tag(String t, {Color color = Brand.primary, IconData? icon}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            t,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );

// ───────── inputs ─────────
InputDecoration deco(
  String label, {
  String? hint,
  IconData? icon,
  String? prefix,
  Widget? suffix,
  String? helper,
  bool filled = true,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  helperText: helper,
  helperMaxLines: 2,
  prefixText: prefix,
  prefixIcon: icon == null ? null : Icon(icon, size: 20),
  suffixIcon: suffix,
  filled: filled,
  fillColor: const Color(0xFFF8FAFD),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: kBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: kBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Brand.primary, width: 1.6),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.redAccent),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
  ),
);

Widget dropdown(
  String label,
  String? value,
  List<String> items,
  ValueChanged<String?> onChanged, {
  String? Function(String?)? validator,
  IconData? icon,
  String? helper,
}) => DropdownButtonFormField<String>(
  initialValue: (value != null && items.contains(value)) ? value : null,
  isExpanded: true,
  decoration: deco(label, icon: icon, helper: helper),
  items: [
    for (final o in items)
      DropdownMenuItem(
        value: o,
        child: Text(o, overflow: TextOverflow.ellipsis),
      ),
  ],
  onChanged: onChanged,
  validator: validator,
);

/// Read-only field that opens a date picker. `value` is 'd Mon yyyy'.
DateTime? _parseDisplayDate(String value) {
  final match = RegExp(
    r'^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})$',
  ).firstMatch(value.trim());
  if (match == null) return null;

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months.indexOf(
    match.group(2)!.substring(0, 1).toUpperCase() +
        match.group(2)!.substring(1).toLowerCase(),
  );
  final day = int.tryParse(match.group(1)!);
  final year = int.tryParse(match.group(3)!);
  if (month < 0 || day == null || year == null) return null;

  final date = DateTime(year, month + 1, day);
  return date.year == year && date.month == month + 1 && date.day == day
      ? date
      : null;
}

Widget dateField(
  BuildContext context,
  String label,
  String value,
  ValueChanged<String> onPicked, {
  DateTime? first,
  DateTime? last,
  String? Function(String?)? validator,
  String? helper,
}) {
  return TextFormField(
    key: ValueKey('date-$label-$value'),
    initialValue: value,
    readOnly: true,
    validator: validator,
    decoration: deco(
      label,
      icon: Icons.calendar_month_outlined,
      helper: helper,
      suffix: const Icon(Icons.arrow_drop_down),
    ),
    onTap: () async {
      final now = DateTime.now();
      final init = _parseDisplayDate(value) ?? now;
      final d = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: first ?? DateTime(1990),
        lastDate: last ?? DateTime(now.year + 5),
      );
      if (d != null) onPicked(fmt(d));
    },
  );
}

/// Quantity stepper  [-] 3 [+]
class Stepper2 extends StatelessWidget {
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const Stepper2({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );
}

// ───────── formatters ─────────
class UpperFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}

/// Groups digits: groups of `group`, max `max` digits (Aadhaar 4-4-4, card 4-4-4-4).
class GroupFormatter extends TextInputFormatter {
  final int group, max;
  GroupFormatter({this.group = 4, this.max = 12});
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var d = n.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > max) d = d.substring(0, max);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % group == 0) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var d = n.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 4) d = d.substring(0, 4);
    final t = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

final digitsOnly = FilteringTextInputFormatter.digitsOnly;

/// Confirm popup. Returns true if the user confirmed.
Future<bool> confirmDialog(
  BuildContext c,
  String title,
  String body, {
  String yes = 'Delete',
  Color color = Colors.redAccent,
}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Modern dialog frame: gradient header, scrollable body, footer buttons.
Future<T?> modalSheet<T>(
  BuildContext context, {
  required String title,
  String subtitle = '',
  IconData icon = Icons.edit_outlined,
  required Widget Function(BuildContext, StateSetter) body,
  required List<Widget> Function(BuildContext, StateSetter) actions,
  double width = 640,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: MediaQuery.of(ctx).size.height * .92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Brand.primary, Color(0xFF1B6CA8)],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: body(ctx, set),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final a in actions(ctx, set))
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: a,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
