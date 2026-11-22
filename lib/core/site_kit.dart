import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config.dart';
import 'widgets.dart';

// Building blocks for the public website: animations (Reveal, CountUp, Marquee...),
// section frame, top nav bar, hamburger menu, footer and the simple page frame.

// ═════════════════════════════════════════════════════════════
// HELPERS (you rarely need to edit anything in this file –
// all text, images and numbers live in config.dart)
// ═════════════════════════════════════════════════════════════

/// Set by HomePage so any section can scroll the page, e.g. scrollToSection?.call('team').
void Function(String id)? scrollToSection;

void openLink(BuildContext c, String url) {
  if (url.isEmpty || url == '#') {
    toast(c, 'No link set yet – add it in config.dart');
    return;
  }
  toast(c, 'Opens $url (demo – add the url_launcher package to open real links)');
}

String commas(num v) => v.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}' ',');
String secLabel(String id) => Content.titles[id]?[0] ?? id;
List<String> bl(String? s) => (s ?? '').split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
String two(int i) => (i + 1).toString().padLeft(2, '0');

/// Width of one column so that `maxCols` fit (1 col on phones, 2 on tablets).
double colW(BuildContext c, int maxCols, {double gap = 20}) {
  final w = MediaQuery.of(c).size.width;
  final avail = math.min(w, 1200.0) - 48;
  final cols = w >= 1000 ? maxCols : (w >= 640 ? math.min(2, maxCols) : 1);
  return ((avail - gap * (cols - 1)) / cols).floorToDouble();
}

Widget pill(String t, {Color bg = Brand.accent, Color fg = Colors.black87}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );

Widget initialBox(String name, double size, {Color color = Brand.primary}) => Container(
      width: size,
      height: size,
      color: color,
      child: Center(child: Text(name.isEmpty ? '?' : name[0], style: TextStyle(color: Colors.white, fontSize: size * .42, fontWeight: FontWeight.bold))),
    );

// ───────── animation building blocks ─────────

/// Builds its child with seen = true once it has scrolled into view.
class OnVisible extends StatefulWidget {
  final Widget Function(bool seen) builder;
  const OnVisible({super.key, required this.builder});
  @override
  State<OnVisible> createState() => _OnVisibleState();
}

class _OnVisibleState extends State<OnVisible> {
  bool seen = false;
  ScrollPosition? pos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pos?.removeListener(check);
    pos = Scrollable.maybeOf(context)?.position;
    pos?.addListener(check);
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  void check() {
    if (seen || !mounted) return;
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return;
    if (ro.localToGlobal(Offset.zero).dy < MediaQuery.of(context).size.height - 60) setState(() => seen = true);
  }

  @override
  void dispose() {
    pos?.removeListener(check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(seen);
}

/// Fade + slide up when scrolled into view.
class Reveal extends StatelessWidget {
  final Widget child;
  const Reveal({super.key, required this.child});
  @override
  Widget build(BuildContext context) => OnVisible(
        builder: (seen) => AnimatedOpacity(
          opacity: seen ? 1 : 0,
          duration: const Duration(milliseconds: 700),
          child: AnimatedSlide(offset: seen ? Offset.zero : const Offset(0, .06), duration: const Duration(milliseconds: 700), curve: Curves.easeOut, child: child),
        ),
      );
}

/// Number that counts up from 0 when visible.
class CountUp extends StatelessWidget {
  final Stat stat;
  final TextStyle style;
  const CountUp(this.stat, {super.key, required this.style});
  @override
  Widget build(BuildContext context) => OnVisible(
        builder: (seen) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: seen ? stat.value : 0),
          duration: const Duration(milliseconds: 2200),
          curve: Curves.easeOutCubic,
          builder: (c, v, _) => Text('${stat.prefix}${commas(v)}${stat.suffix}', style: style),
        ),
      );
}

class Hoverable extends StatefulWidget {
  final Widget Function(bool hover) builder;
  const Hoverable({super.key, required this.builder});
  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool h = false;
  @override
  Widget build(BuildContext context) =>
      MouseRegion(onEnter: (_) => setState(() => h = true), onExit: (_) => setState(() => h = false), child: widget.builder(h));
}

/// Card lifts slightly on hover.
class Lift extends StatelessWidget {
  final Widget child;
  const Lift({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Hoverable(
        builder: (h) => AnimatedContainer(duration: const Duration(milliseconds: 200), transform: Matrix4.translationValues(0, h ? -6 : 0, 0), child: child),
      );
}

/// Endlessly scrolling row (logo walls, photo strips).
class Marquee extends StatefulWidget {
  final List<Widget> children;
  final double itemWidth, height, gap;
  final int seconds;
  final bool reverse;
  const Marquee({super.key, required this.children, required this.itemWidth, required this.height, this.gap = 16, this.seconds = 40, this.reverse = false});
  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController ctl = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds))..repeat();

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    final total = (widget.itemWidth + widget.gap) * widget.children.length;
    final reps = (MediaQuery.of(context).size.width / total).ceil() + 1;
    return ClipRect(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          child: AnimatedBuilder(
            animation: ctl,
            builder: (_, child) {
              final v = widget.reverse ? 1 - ctl.value : ctl.value;
              return Transform.translate(offset: Offset(-v * total, 0), child: child);
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var r = 0; r < reps; r++)
                for (final ch in widget.children)
                  Padding(padding: EdgeInsets.only(right: widget.gap), child: SizedBox(width: widget.itemWidth, height: widget.height, child: ch)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Common frame for every section: label, title, sub-text, then the content.
class SectionShell extends StatelessWidget {
  final String id;
  final Color bg;
  final bool dark, bleed; // bleed = content goes edge to edge (marquees)
  final Widget child;
  const SectionShell({super.key, required this.id, required this.bg, required this.child, this.dark = false, this.bleed = false});

  @override
  Widget build(BuildContext context) {
    final t = Content.titles[id] ?? [id, id, ''];
    final narrow = MediaQuery.of(context).size.width < 700;
    final header = Reveal(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 28, height: 3, color: Brand.accent),
          const SizedBox(width: 10),
          Text(t[0].toUpperCase(), style: TextStyle(color: dark ? Brand.accent : Brand.primary, fontWeight: FontWeight.w800, letterSpacing: 2.2, fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(t[1], style: TextStyle(fontSize: narrow ? 28 : 42, fontWeight: FontWeight.w800, height: 1.12, letterSpacing: -.5, color: dark ? Colors.white : Brand.dark)),
        ),
        if (t[2].isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: Text(t[2], style: TextStyle(fontSize: 16, height: 1.5, color: dark ? Colors.white70 : Colors.black54))),
        ],
      ]),
    );
    return Container(
      width: double.infinity,
      color: bg,
      child: Column(children: [
        Box(
          max: 1200,
          pad: EdgeInsets.fromLTRB(24, 96, 24, bleed ? 44 : 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            header,
            if (!bleed) ...[const SizedBox(height: 48), child],
          ]),
        ),
        if (bleed) child,
        const SizedBox(height: 96),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// NAV BAR (transparent over hero, white + scroll-progress line after)
// ═════════════════════════════════════════════════════════════
class SiteNav extends StatelessWidget {
  final bool solid;
  final double progress; // 0..1 page scroll
  final void Function(String id) onSection;
  const SiteNav({super.key, required this.solid, required this.onSection, this.progress = 0});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final fg = solid ? Brand.primary : Colors.white;
    final loggedIn = store.me != null;
    return Material(
      type: MaterialType.transparency,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 70,
        decoration: BoxDecoration(color: solid ? Colors.white : Colors.transparent, boxShadow: solid ? [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12)] : []),
        child: Stack(children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                InkWell(onTap: () => onSection('top'), child: BrandLogo(light: !solid)),
                const Spacer(),
                if (w >= 1000)
                  for (final id in Site.navQuick.where(siteSections.contains))
                    TextButton(onPressed: () => onSection(id), child: Text(secLabel(id), style: TextStyle(color: fg, fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                if (w >= 560) ...[
                  FilledButton(style: FilledButton.styleFrom(backgroundColor: Brand.accent, foregroundColor: Colors.black), onPressed: () => go(context, '/incubate'), child: const Text('Incubate')),
                  const SizedBox(width: 8),
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: fg, side: BorderSide(color: fg)),
                      onPressed: () => go(context, loggedIn ? homeFor(store.me!) : '/login'),
                      child: Text(loggedIn ? 'My Portal' : 'Login')),
                ],
                IconButton(tooltip: 'Menu', icon: Icon(Icons.menu_rounded, color: fg, size: 30), onPressed: () => openMenu(context, onSection)),
              ]),
            ),
          ),
          if (solid)
            Positioned(left: 0, right: 0, bottom: 0, child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: progress.clamp(0.0, 1.0), child: Container(height: 3, color: Brand.accent)))),
        ]),
      ),
    );
  }
}

/// Slide-in hamburger menu.
void openMenu(BuildContext context, void Function(String id) onSection) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'menu',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, __) {
      final items = ['top', ...siteSections.where((s) => !Site.hideFromMenu.contains(s))];
      final loggedIn = store.me != null;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Brand.dark,
          child: SizedBox(
            width: math.min(440, MediaQuery.of(ctx).size.width),
            height: double.infinity,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const BrandLogo(light: true), const Spacer(), IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx))]),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(children: [
                      for (var i = 0; i < items.length; i++)
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            onSection(items[i]);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(children: [
                              SizedBox(width: 38, child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(color: Brand.accent, fontWeight: FontWeight.bold))),
                              Text(items[i] == 'top' ? 'Home' : secLabel(items[i]), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Brand.accent, foregroundColor: Colors.black, padding: const EdgeInsets.all(16)),
                        onPressed: () { Navigator.pop(ctx); go(context, '/incubate'); },
                        child: Text(Site.btnPrimary)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), padding: const EdgeInsets.all(16)),
                        onPressed: () { Navigator.pop(ctx); go(context, loggedIn ? homeFor(store.me!) : '/login'); },
                        child: Text(loggedIn ? 'My Portal' : Site.btnSecondary)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, a, _, child) =>
        SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child),
  );
}

// ═════════════════════════════════════════════════════════════
// FOOTER
// ═════════════════════════════════════════════════════════════
class SiteFooter extends StatelessWidget {
  final void Function(String id) onSection;
  const SiteFooter({super.key, required this.onSection});

  @override
  Widget build(BuildContext context) {
    final email = TextEditingController();
    final links = siteSections.where((s) => !Site.hideFromMenu.contains(s)).take(7);
    return Container(
      width: double.infinity,
      color: const Color(0xFF05172B),
      child: Box(
        max: 1200,
        pad: const EdgeInsets.fromLTRB(24, 64, 24, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 70, runSpacing: 32, children: [
            SizedBox(
              width: 320,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const BrandLogo(light: true),
                const SizedBox(height: 12),
                const Text(Brand.fullName, style: TextStyle(color: Colors.white70, height: 1.5)),
                const SizedBox(height: 18),
                Text(Site.newsletterText, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: email,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Your email',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Brand.accent)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Brand.accent, foregroundColor: Colors.black),
                      onPressed: () {
                        if (V.email(email.text) != null) return toast(context, 'Enter a valid email');
                        toast(context, 'Subscribed (demo).');
                        email.clear();
                      },
                      child: const Text('Join')),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Explore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              for (final id in links) InkWell(onTap: () => onSection(id), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(secLabel(id), style: const TextStyle(color: Colors.white70)))),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('For founders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              for (final l in const [['Apply to incubate', '/incubate'], ['Incubatee login', '/login']]) InkWell(onTap: () => go(context, l[1]), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(l[0], style: const TextStyle(color: Colors.white70)))),
            ]),
            SizedBox(
              width: 300,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(Brand.address, style: TextStyle(color: Colors.white70, height: 1.4)),
                const SizedBox(height: 6),
                const Text(Brand.email, style: TextStyle(color: Colors.white70)),
                const Text(Brand.phone, style: TextStyle(color: Colors.white70)),
              ]),
            ),
          ]),
          const SizedBox(height: 36),
          const Divider(color: Colors.white24),
          Text('© ${DateTime.now().year} ${Brand.fullName} · Prototype – demo data only', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      ),
    );
  }
}

/// Simple frame for Login / Incubate pages: solid nav + footer.
class PublicScaffold extends StatelessWidget {
  final String current;
  final Widget Function() body;
  const PublicScaffold({super.key, required this.current, required this.body});
  @override
  Widget build(BuildContext context) {
    void onSection(String id) => go(context, id == 'top' ? '/' : '/$id');
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        body: Column(children: [
          SiteNav(solid: true, onSection: onSection),
          Expanded(child: SingleChildScrollView(child: Column(children: [body(), SiteFooter(onSection: onSection)]))),
        ]),
      ),
    );
  }
}
