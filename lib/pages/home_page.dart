import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config.dart';
import '../core/widgets.dart';
import '../core/site_kit.dart';

// HOME PAGE = hero + every section below it. Text/images/numbers come from config.dart.

// ═════════════════════════════════════════════════════════════
// HOME PAGE  (hero + all sections listed in siteSections)
// ═════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  final String? scrollTo;
  const HomePage({super.key, this.scrollTo});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final sc = ScrollController();
  final keys = {for (final id in siteSections) id: GlobalKey()};
  static const darkIds = {
    'impact',
    'contact',
  }; // sections with a fixed dark background

  @override
  void initState() {
    super.initState();
    scrollToSection = goTo;
    if (widget.scrollTo != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) goTo(widget.scrollTo!);
      });
    }
  }

  void goTo(String id) {
    if (id == 'top') {
      sc.animateTo(
        0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    final ctx = keys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    if (scrollToSection == goTo) scrollToSection = null;
    sc.dispose();
    super.dispose();
  }

  double get progress {
    if (!sc.hasClients || !sc.position.hasContentDimensions) return 0;
    final max = sc.position.maxScrollExtent;
    return max <= 0 ? 0 : sc.offset / max;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      var light = true;
      final sections = <Widget>[];
      for (final id in siteSections) {
        Color bg;
        if (darkIds.contains(id)) {
          bg = Brand.dark;
        } else {
          bg = light ? Colors.white : Brand.surface;
          light = !light;
        }
        sections.add(
          KeyedSubtree(key: keys[id], child: buildSection(id, context, bg)),
        );
      }
      return Scaffold(
        floatingActionButton: ListenableBuilder(
          listenable: sc,
          builder: (c, _) => (sc.hasClients && sc.offset > 900)
              ? FloatingActionButton.small(
                  backgroundColor: Brand.accent,
                  onPressed: () => goTo('top'),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.black,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: sc,
              child: Column(
                children: [
                  HeroSection(onSection: goTo),
                  ...sections,
                  SiteFooter(onSection: goTo),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ListenableBuilder(
                listenable: sc,
                builder: (c, _) => SiteNav(
                  solid: sc.hasClients && sc.offset > 40,
                  progress: progress,
                  onSection: goTo,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ═════════════════════════════════════════════════════════════
// HERO
// ═════════════════════════════════════════════════════════════
class HeroVideo extends StatefulWidget {
  const HeroVideo({super.key});
  @override
  State<HeroVideo> createState() => _HeroVideoState();
}

class _HeroVideoState extends State<HeroVideo> {
  VideoPlayerController? c;
  bool ok = false;

  @override
  void initState() {
    super.initState();
    final s = Brand.heroVideo;
    if (s.isEmpty) return;
    final ctl = s.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(s))
        : VideoPlayerController.asset(s);
    c = ctl;
    ctl
        .initialize()
        .then((_) {
          ctl.setLooping(true);
          ctl.setVolume(0); // browsers only autoplay muted video
          ctl.play();
          if (mounted) setState(() => ok = true);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      pic(
        Brand.heroImage,
        h: double.infinity,
        w: double.infinity,
        fallback: Container(color: Brand.dark),
      ),
      if (ok)
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: c!.value.size.width,
            height: c!.value.size.height,
            child: VideoPlayer(c!),
          ),
        ),
    ],
  );
}

/// Words typed out and deleted one after another.
class Typewriter extends StatefulWidget {
  final List<String> words;
  final TextStyle style;
  const Typewriter({super.key, required this.words, required this.style});
  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter> {
  int w = 0, n = 0, pause = 0;
  bool del = false;
  Timer? t;

  @override
  void initState() {
    super.initState();
    if (widget.words.isEmpty) return;
    t = Timer.periodic(const Duration(milliseconds: 75), (_) {
      if (!mounted) return;
      final word = widget.words[w];
      setState(() {
        if (pause > 0) {
          pause--;
          return;
        }
        if (!del) {
          n++;
          if (n >= word.length) {
            n = word.length;
            del = true;
            pause = 24;
          }
        } else {
          n--;
          if (n <= 0) {
            n = 0;
            del = false;
            w = (w + 1) % widget.words.length;
            pause = 4;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) return const SizedBox.shrink();
    final word = widget.words[w];
    return Text(
      '${word.substring(0, n.clamp(0, word.length))}▎',
      style: widget.style,
    );
  }
}

/// Glass card that floats gently up and down.
class FloatCard extends StatefulWidget {
  final List<String> data; // [icon, title, subtitle]
  final double phase;
  const FloatCard({super.key, required this.data, this.phase = 1});
  @override
  State<FloatCard> createState() => _FloatCardState();
}

class _FloatCardState extends State<FloatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController ctl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (2600 * widget.phase).round()),
  )..repeat(reverse: true);

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctl,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, (ctl.value - .5) * 14),
      child: child,
    ),
    child: Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Brand.accent,
            child: Icon(iconOf(widget.data[0]), color: Colors.black87),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data[1],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.data[2],
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class HeroSection extends StatelessWidget {
  final void Function(String id) onSection;
  const HeroSection({super.key, required this.onSection});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final narrow = size.width < 700;
    final wide = size.width >= 1000;
    final headStyle = TextStyle(
      color: Colors.white,
      fontSize: narrow ? 38 : 62,
      fontWeight: FontWeight.w800,
      height: 1.08,
      letterSpacing: -1,
    );
    return SizedBox(
      height: narrow ? 1000 : math.max(size.height, 820.0),
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const HeroVideo(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Brand.dark.withOpacity(.65),
                  Brand.primary.withOpacity(.45),
                  Brand.dark.withOpacity(.92),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Box(
              max: 1200,
              pad: EdgeInsets.fromLTRB(24, 110, 24, narrow ? 290 : 150),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 3,
                              color: Brand.accent,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                Site.heroEyebrow,
                                style: const TextStyle(
                                  color: Brand.accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Reveal(child: Text(store.tagline, style: headStyle)),
                        Typewriter(
                          words: Site.heroWords,
                          style: headStyle.copyWith(color: Brand.accent),
                        ),
                        const SizedBox(height: 22),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: const Text(
                            Brand.subTagline,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              height: 1.55,
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Brand.accent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 20,
                                ),
                              ),
                              onPressed: () => go(context, '/incubate'),
                              child: Text(
                                Site.btnPrimary,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 20,
                                ),
                              ),
                              onPressed: () => go(
                                context,
                                store.me == null
                                    ? '/login'
                                    : homeFor(store.me!),
                              ),
                              child: Text(
                                store.me == null
                                    ? Site.btnSecondary
                                    : 'My Portal',
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 20,
                                ),
                              ),
                              onPressed: () => onSection(siteSections.first),
                              icon: const Icon(Icons.arrow_downward, size: 18),
                              label: Text(Site.btnExplore),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(width: 40),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < Site.heroCards.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: 16,
                              left: i.isOdd ? 40 : 0,
                            ),
                            child: FloatCard(
                              data: Site.heroCards[i],
                              phase: 1 + i * .3,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // animated numbers strip
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.38),
                border: const Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Box(
                max: 1200,
                pad: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 20,
                  runSpacing: 18,
                  children: [
                    for (final s in Content.stats)
                      SizedBox(
                        width: narrow ? 150 : 230,
                        child: Column(
                          children: [
                            CountUp(
                              s,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: narrow ? 30 : 42,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
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
}

// ═════════════════════════════════════════════════════════════
// SECTION SWITCH  (ids come from siteSections in config.dart)
// ═════════════════════════════════════════════════════════════
Widget buildSection(String id, BuildContext c, Color bg) {
  switch (id) {
    case 'about':
      return AboutSection(bg: bg);
    case 'why':
      return _why(c, bg);
    case 'impact':
      return _impact(c);
    case 'programs':
      return SectionShell(id: id, bg: bg, child: const ProgramsSection());
    case 'journey':
      return _journey(c, bg);
    case 'facilities':
      return _facilities(c, bg);
    case 'partners':
      return _partners(bg);
    case 'team':
      return _team(c, bg);
    case 'mentors':
      return SectionShell(id: id, bg: bg, child: const MentorSpotlight());
    case 'startups':
      return SectionShell(id: id, bg: bg, child: const StartupsGrid());
    case 'stories':
      return SectionShell(id: id, bg: bg, child: const StoriesSection());
    case 'events':
      return _events(c, bg);
    case 'resources':
      return _resources(c, bg);
    case 'gallery':
      return _gallery(bg);
    case 'faq':
      return _faq(c, bg);
    case 'cta':
      return _cta(c, bg);
    case 'contact':
      return ContactSection(bg: bg);
    default:
      return const SizedBox.shrink();
  }
}

// ═════════════════════════════════════════════════════════════
// ABOUT  – photo collage + Vision / Mission / Governance tabs
// ═════════════════════════════════════════════════════════════
class AboutSection extends StatefulWidget {
  final Color bg;
  const AboutSection({super.key, required this.bg});
  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  String tab = 'Vision';

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final texts = {
      'Vision': Content.vision,
      'Mission': Content.mission,
      'Governance': Content.governance,
    };
    final collage = SizedBox(
      height: 500,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: wide ? 70 : 30,
            bottom: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: pic(
                Content.aboutImage,
                h: double.infinity,
                w: double.infinity,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: 210,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 6),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 18),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: pic(
                  Content.aboutImage2,
                  h: double.infinity,
                  w: double.infinity,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 34,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 16),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Brand.accent, size: 30),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Brand.since,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        Content.stats.isEmpty
                            ? ''
                            : '${Content.stats.first.prefix}${commas(Content.stats.first.value)}${Content.stats.first.suffix} ${Content.stats.first.label.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Content.aboutIntro,
          style: const TextStyle(
            fontSize: 17,
            height: 1.65,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in texts.keys)
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => setState(() => tab = k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: tab == k ? Brand.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: tab == k ? Brand.primary : Colors.black26,
                    ),
                  ),
                  child: Text(
                    k,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: tab == k ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            texts[tab]!,
            key: ValueKey(tab),
            style: const TextStyle(
              fontSize: 20,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Brand.primary,
            ),
          ),
        ),
        const SizedBox(height: 26),
        for (final p in Content.aboutPoints)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Brand.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text(p, style: const TextStyle(fontSize: 16))),
              ],
            ),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => scrollToSection?.call('team'),
          child: const Text('Meet our team  →'),
        ),
      ],
    );
    return SectionShell(
      id: 'about',
      bg: widget.bg,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: Reveal(child: collage)),
                const SizedBox(width: 56),
                Expanded(flex: 6, child: Reveal(child: text)),
              ],
            )
          : Column(
              children: [
                Reveal(child: collage),
                const SizedBox(height: 28),
                Reveal(child: text),
              ],
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// WHY SRIIF  – open grid with numbers (no boxes)
// ═════════════════════════════════════════════════════════════
Widget _why(BuildContext c, Color bg) => SectionShell(
  id: 'why',
  bg: bg,
  child: Wrap(
    spacing: 40,
    runSpacing: 44,
    children: [
      for (var i = 0; i < Content.why.length; i++)
        Reveal(
          child: Hoverable(
            builder: (h) {
              final m = Content.why[i];
              return SizedBox(
                width: colW(c, 3, gap: 40),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.only(top: 22),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: h ? Brand.accent : Colors.black12,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: h
                                  ? Brand.primary
                                  : Brand.primary.withOpacity(.08),
                            ),
                            child: Icon(
                              iconOf(m['icon'] ?? ''),
                              color: h ? Colors.white : Brand.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            two(i),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withOpacity(.07),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        m['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m['desc'] ?? '',
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    ],
  ),
);

// ═════════════════════════════════════════════════════════════
// IMPACT  – dark band with big counting numbers
// ═════════════════════════════════════════════════════════════
Widget _impact(BuildContext c) {
  final narrow = MediaQuery.of(c).size.width < 700;
  return Container(
    color: Brand.dark,
    child: ClipRect(
      child: Stack(
        children: [
          Positioned(
            right: -140,
            top: -140,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Brand.primary.withOpacity(.35),
              ),
            ),
          ),
          Positioned(
            left: -100,
            bottom: -160,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Brand.accent.withOpacity(.10),
              ),
            ),
          ),
          SectionShell(
            id: 'impact',
            bg: Colors.transparent,
            dark: true,
            child: Wrap(
              runSpacing: 48,
              children: [
                for (final s in Content.impact)
                  Reveal(
                    child: SizedBox(
                      width: colW(c, 3, gap: 0),
                      child: Container(
                        padding: const EdgeInsets.only(left: 24),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.white24, width: 1.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(iconOf(s.icon), color: Brand.accent, size: 28),
                            const SizedBox(height: 10),
                            CountUp(
                              s,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: narrow ? 46 : 62,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (s.note.isNotEmpty)
                              Text(
                                s.note,
                                style: const TextStyle(color: Colors.white54),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════
// PROGRAMS  – stage finder: pick a program, see the details
// ═════════════════════════════════════════════════════════════
class ProgramsSection extends StatefulWidget {
  const ProgramsSection({super.key});
  @override
  State<ProgramsSection> createState() => _ProgramsSectionState();
}

class _ProgramsSectionState extends State<ProgramsSection> {
  int sel = 0;

  Widget _tab(int i, Map<String, String> m, bool wide) {
    final on = i == sel;
    if (!wide) {
      return ChoiceChip(
        label: Text(m['title'] ?? ''),
        selected: on,
        onSelected: (_) => setState(() => sel = i),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => sel = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: on ? Brand.primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: on ? Brand.primary : Colors.black12),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: Brand.primary.withOpacity(.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Text(
                two(i),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: on ? Brand.accent : Colors.black26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['title'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: on ? Colors.white : Brand.dark,
                      ),
                    ),
                    Text(
                      m['stage'] ?? '',
                      style: TextStyle(
                        color: on ? Colors.white70 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: on ? Colors.white : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(Map<String, String> m) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, 10)),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              pic(m['img'], fallback: Container(color: Brand.primary)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Brand.dark.withOpacity(.85)],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                bottom: 20,
                right: 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        m['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    pill(m['tag'] ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((m['stage'] ?? '').isNotEmpty)
                pill(
                  m['stage']!,
                  bg: Brand.primary.withOpacity(.1),
                  fg: Brand.primary,
                ),
              const SizedBox(height: 12),
              Text(
                m['desc'] ?? '',
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.55,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  for (final b in bl(m['bullets']))
                    SizedBox(
                      width: 240,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Brand.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(b)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 18,
                      ),
                    ),
                    onPressed: () => go(context, '/incubate'),
                    child: Text(
                      ((m['cta'] ?? '').isEmpty) ? 'Apply now' : m['cta']!,
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 18,
                      ),
                    ),
                    onPressed: () => scrollToSection?.call('faq'),
                    child: const Text('Read FAQs'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final list = Content.programs;
    if (list.isEmpty) return const SizedBox.shrink();
    final m = list[sel.clamp(0, list.length - 1)];
    final wide = MediaQuery.of(context).size.width >= 900;
    final detail = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: ValueKey(sel), child: _detail(m)),
    );
    return wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 380,
                child: Column(
                  children: [
                    for (var i = 0; i < list.length; i++)
                      _tab(i, list[i], true),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(child: detail),
            ],
          )
        : Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < list.length; i++) _tab(i, list[i], false),
                ],
              ),
              const SizedBox(height: 22),
              detail,
            ],
          );
  }
}

// ═════════════════════════════════════════════════════════════
// JOURNEY  – timeline
// ═════════════════════════════════════════════════════════════
Widget _journey(BuildContext c, Color bg) {
  final steps = Content.journey;
  final wide = MediaQuery.of(c).size.width >= 900;
  Widget circle(Map<String, String> m, double r) => CircleAvatar(
    radius: r,
    backgroundColor: Brand.primary,
    child: Icon(iconOf(m['icon'] ?? ''), color: Colors.white, size: r * .9),
  );
  return SectionShell(
    id: 'journey',
    bg: bg,
    child: wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: Reveal(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i == 0
                                    ? Colors.transparent
                                    : Brand.primary.withOpacity(.25),
                              ),
                            ),
                            circle(steps[i], 28),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i == steps.length - 1
                                    ? Colors.transparent
                                    : Brand.primary.withOpacity(.25),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        pill(
                          steps[i]['tag'] ?? '',
                          bg: Brand.accent.withOpacity(.25),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          steps[i]['title'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            steps[i]['desc'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          )
        : Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                Reveal(
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 48,
                          child: Column(
                            children: [
                              circle(steps[i], 22),
                              if (i != steps.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: Brand.primary.withOpacity(.25),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 26),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                pill(
                                  steps[i]['tag'] ?? '',
                                  bg: Brand.accent.withOpacity(.25),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  steps[i]['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  steps[i]['desc'] ?? '',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
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

// ═════════════════════════════════════════════════════════════
// FACILITIES  – bento grid: first item is the big tile
// ═════════════════════════════════════════════════════════════
Widget _bento(
  Map<String, String> m,
  double w,
  double h, {
  bool always = false,
}) => Reveal(
  child: SizedBox(
    width: w,
    height: h,
    child: Hoverable(
      builder: (hov) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedScale(
              scale: hov ? 1.07 : 1,
              duration: const Duration(milliseconds: 500),
              child: pic(m['img'], fallback: Container(color: Brand.primary)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Brand.dark.withOpacity(hov ? .92 : .75),
                  ],
                ),
              ),
            ),
            if ((m['tag'] ?? '').isNotEmpty)
              Positioned(top: 14, left: 14, child: pill(m['tag']!)),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: (hov || always)
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              m['desc'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
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

Widget _facilities(BuildContext c, Color bg) {
  final list = Content.facilities;
  final w = MediaQuery.of(c).size.width;
  final avail = math.min(w, 1200.0) - 48;
  Widget body;
  if (list.isEmpty) {
    body = const SizedBox.shrink();
  } else if (w >= 1000 && list.length > 1) {
    final big = ((avail - 16) * .44).floorToDouble();
    final right = avail - 16 - big;
    final small = ((right - 16) / 2).floorToDouble();
    final rows = ((list.length - 1) / 2).ceil();
    const th = 230.0;
    final bigH = rows * th + (rows - 1) * 16;
    body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bento(list.first, big, bigH, always: true),
        const SizedBox(width: 16),
        SizedBox(
          width: right,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [for (final m in list.skip(1)) _bento(m, small, th)],
          ),
        ),
      ],
    );
  } else {
    final cw = colW(c, 2, gap: 16);
    body = Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [for (final m in list) _bento(m, cw, 240, always: true)],
    );
  }
  return SectionShell(id: 'facilities', bg: bg, child: body);
}

// ═════════════════════════════════════════════════════════════
// PARTNERS  – two rows of scrolling logos
// ═════════════════════════════════════════════════════════════
Widget _partners(Color bg) {
  final p = Content.partners;
  final half = (p.length / 2).ceil();
  Widget logoPill(Map<String, String> m) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.black12),
    ),
    child: Row(
      children: [
        (m['img'] ?? '').isNotEmpty
            ? pic(m['img'], h: 44, w: 44, fit: BoxFit.contain)
            : CircleAvatar(
                radius: 22,
                backgroundColor: Brand.primary.withOpacity(.1),
                child: Text(
                  (m['title'] ?? '?')[0],
                  style: const TextStyle(
                    color: Brand.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m['title'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                m['tag'] ?? '',
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return SectionShell(
    id: 'partners',
    bg: bg,
    bleed: true,
    child: Column(
      children: [
        Marquee(
          itemWidth: 270,
          height: 80,
          seconds: 45,
          children: [for (final m in p.take(half)) logoPill(m)],
        ),
        const SizedBox(height: 16),
        Marquee(
          itemWidth: 270,
          height: 80,
          seconds: 55,
          reverse: true,
          children: [for (final m in p.skip(half)) logoPill(m)],
        ),
      ],
    ),
  );
}

int sel = 0;

// ═════════════════════════════════════════════════════════════
// TEAM  – portrait cards, hover to read more other changees
// ═════════════════════════════════════════════════════════════
Widget _team(BuildContext c, Color bg) {
  final narrow = MediaQuery.of(c).size.width < 640;
  final w = colW(c, 4);
  return SectionShell(
    id: 'team',
    bg: bg,
    child: Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (final m in Content.team)
          Reveal(
            child: SizedBox(
              width: w,
              height: w * 1.28,
              child: Hoverable(
                builder: (hov) {
                  final show = hov || narrow;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedScale(
                          scale: hov ? 1.06 : 1,
                          duration: const Duration(milliseconds: 500),
                          child: pic(
                            m['img'],
                            fallback: initialBox(m['title'] ?? '', 120),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [.35, 1],
                              colors: [
                                Colors.transparent,
                                Brand.dark.withOpacity(show ? .95 : .8),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                m['tag'] ?? '',
                                style: const TextStyle(
                                  color: Brand.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                child: show
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m['desc'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                height: 1.4,
                                              ),
                                            ),
                                            if ((m['link'] ?? '').isNotEmpty)
                                              TextButton.icon(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.zero,
                                                ),
                                                onPressed: () =>
                                                    openLink(c, m['link']!),
                                                icon: const Icon(
                                                  Icons.link,
                                                  size: 18,
                                                ),
                                                label: const Text('LinkedIn'),
                                              ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════
// MENTORS  – spotlight: pick a mentor from the avatar rail
// ═════════════════════════════════════════════════════════════
class MentorSpotlight extends StatefulWidget {
  const MentorSpotlight({super.key});
  @override
  State<MentorSpotlight> createState() => _MentorSpotlightState();
}

class _MentorSpotlightState extends State<MentorSpotlight> {
  int sel = 0;

  @override
  Widget build(BuildContext context) {
    final list = Content.mentors;
    if (list.isEmpty) return const SizedBox.shrink();
    final m = list[sel.clamp(0, list.length - 1)];
    final wide = MediaQuery.of(context).size.width >= 900;
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: wide ? 470 : 360,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            pic(m['img'], fallback: initialBox(m['title'] ?? '', 160)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [.5, 1],
                  colors: [Colors.transparent, Brand.dark.withOpacity(.9)],
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    m['role'] ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pill(m['tag'] ?? ''),
        const SizedBox(height: 16),
        Text(
          m['desc'] ?? '',
          style: const TextStyle(
            fontSize: 21,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: Brand.dark,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in bl(m['bullets']))
              pill(b, bg: Brand.primary.withOpacity(.08), fg: Brand.primary),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
          onPressed: () => go(
            context,
            store.role == 'incubatee' ? '/portal/support' : '/login',
          ),
          icon: const Icon(Icons.calendar_month),
          label: const Text('Request this mentor'),
        ),
      ],
    );
    final rail = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < list.length; i++)
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => setState(() => sel = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: i == sel ? Brand.accent : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: pic(
                  list[i]['img'],
                  h: 60,
                  w: 60,
                  fallback: initialBox(list[i]['title'] ?? '', 60),
                ),
              ),
            ),
          ),
      ],
    );
    final left = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: ValueKey('p$sel'), child: photo),
    );
    final right = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: ValueKey('i$sel'), child: info),
    );
    return wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: left),
              const SizedBox(width: 52),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    right,
                    const SizedBox(height: 34),
                    const Text(
                      'MORE MENTORS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    rail,
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              const SizedBox(height: 20),
              rail,
              const SizedBox(height: 24),
              right,
            ],
          );
  }
}

// ═════════════════════════════════════════════════════════════
// STARTUPS  – search + sector filter + portfolio cards
// ═════════════════════════════════════════════════════════════
const _sectorColors = [
  Color(0xFF0B3C6F),
  Color(0xFF1B8A6B),
  Color(0xFF7B3FA0),
  Color(0xFFC2571A),
  Color(0xFF1F6FEB),
  Color(0xFFB0285A),
];
Color sectorColor(String s) =>
    _sectorColors[s.codeUnits.fold(0, (a, b) => a + b) % _sectorColors.length];

class StartupsGrid extends StatefulWidget {
  const StartupsGrid({super.key});
  @override
  State<StartupsGrid> createState() => _StartupsGridState();
}

class _StartupsGridState extends State<StartupsGrid> {
  String sector = 'All', q = '';

  @override
  Widget build(BuildContext context) {
    // Content.startups + registrations approved in the portal demo
    final all = [...Content.startups];
    for (final u in store.users.where(
      (u) => u.role == 'incubatee' && u.status == 'active',
    )) {
      if (!all.any((s) => s['title'] == u.startup)) {
        all.add(
          item(
            u.startup,
            'New',
            'Recently onboarded startup.',
            year: '${DateTime.now().year}',
            stage: 'Onboarded',
          ),
        );
      }
    }
    final sectors = [
      'All',
      ...{for (final s in all) s['tag'] ?? ''},
    ];
    final shown = all
        .where(
          (s) =>
              (sector == 'All' || s['tag'] == sector) &&
              ((s['title'] ?? '') + (s['desc'] ?? '')).toLowerCase().contains(
                q.toLowerCase(),
              ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: InputDecoration(
                  hintText: 'Search startups',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                ),
              ),
            ),
            for (final s in sectors)
              ChoiceChip(
                label: Text(s),
                selected: sector == s,
                onSelected: (_) => setState(() => sector = s),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Showing ${shown.length} of ${all.length} startups',
          style: const TextStyle(color: Colors.black45),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [for (final m in shown) _startupCard(context, m)],
        ),
      ],
    );
  }

  Widget _startupCard(BuildContext c, Map<String, String> m) {
    final col = sectorColor(m['tag'] ?? '');
    final name = m['title'] ?? '';
    return Reveal(
      child: Lift(
        child: SizedBox(
          width: colW(c, 3),
          child: Material(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => openLink(c, m['link'] ?? ''),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 92,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [col, col.withOpacity(.65)],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -6,
                              bottom: -22,
                              child: Text(
                                name.isEmpty ? '' : name[0],
                                style: TextStyle(
                                  fontSize: 120,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withOpacity(.14),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 18,
                              top: 14,
                              child: pill(
                                m['tag'] ?? '',
                                bg: Colors.white24,
                                fg: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 18,
                        bottom: -28,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: pic(
                              m['img'],
                              h: 56,
                              w: 56,
                              fallback: initialBox(name, 56, color: col),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m['desc'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if ((m['stage'] ?? '').isNotEmpty)
                              pill(
                                m['stage']!,
                                bg: col.withOpacity(.1),
                                fg: col,
                              ),
                            if ((m['year'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  'Since ${m['year']}',
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            const Icon(
                              Icons.north_east,
                              size: 18,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// SUCCESS STORIES  – auto-advancing quote carousel
// ═════════════════════════════════════════════════════════════
class StoriesSection extends StatefulWidget {
  const StoriesSection({super.key});
  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  final pc = PageController();
  int idx = 0;
  Timer? t;

  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 7), (_) {
      final n = Content.stories.length;
      if (!mounted || n < 2 || !pc.hasClients) return;
      pc.animateToPage(
        (idx + 1) % n,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    t?.cancel();
    pc.dispose();
    super.dispose();
  }

  Widget _slide(Map<String, String> m, bool wide) {
    final img = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: pic(m['img'], h: double.infinity, w: double.infinity),
    );
    final text = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.format_quote_rounded, size: 60, color: Brand.accent),
        Text(
          m['desc'] ?? '',
          style: TextStyle(
            fontSize: wide ? 25 : 18,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: Brand.dark,
          ),
        ),
        const SizedBox(height: 22),
        if ((m['name'] ?? '').isNotEmpty)
          Text(
            m['name']!,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        Text(
          '${m['role'] ?? ''}${(m['role'] ?? '').isEmpty ? '' : ', '}${m['title'] ?? ''}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            pill(
              m['tag'] ?? '',
              bg: Brand.primary.withOpacity(.1),
              fg: Brand.primary,
            ),
            if ((m['stat'] ?? '').isNotEmpty) pill(m['stat']!),
          ],
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: wide
          ? Row(
              children: [
                Expanded(flex: 5, child: img),
                const SizedBox(width: 48),
                Expanded(flex: 6, child: text),
              ],
            )
          : Column(
              children: [
                SizedBox(height: 220, width: double.infinity, child: img),
                const SizedBox(height: 18),
                Expanded(child: text),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = Content.stories;
    if (list.isEmpty) return const SizedBox.shrink();
    final wide = MediaQuery.of(context).size.width >= 900;
    return Column(
      children: [
        SizedBox(
          height: wide ? 440 : 720,
          child: PageView(
            controller: pc,
            onPageChanged: (i) => setState(() => idx = i),
            children: [for (final m in list) _slide(m, wide)],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => pc.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            for (var i = 0; i < list.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: i == idx ? 28 : 8,
                decoration: BoxDecoration(
                  color: i == idx ? Brand.accent : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            IconButton(
              onPressed: () => pc.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// EVENTS & NEWS  – agenda list + news panel
// ═════════════════════════════════════════════════════════════
Widget _events(BuildContext c, Color bg) {
  final wide = MediaQuery.of(c).size.width >= 900;

  Widget row(Map<String, String> m) {
    final p = (m['tag'] ?? '').split(' ');
    final big = p.length == 3
        ? p[0]
        : (p.length == 2 ? p[0] : (m['tag'] ?? ''));
    final small = p.length == 3
        ? '${p[1]} ${p[2]}'
        : (p.length == 2 ? p[1] : '');
    return Hoverable(
      builder: (h) => InkWell(
        onTap: () =>
            toast(c, 'Registration for "${m['title']}" opens soon (demo).'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: h ? Brand.primary.withOpacity(.05) : Colors.transparent,
            border: const Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 84,
                child: Column(
                  children: [
                    Text(
                      big,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: big.length <= 2 ? 38 : 16,
                        fontWeight: FontWeight.w800,
                        color: Brand.primary,
                      ),
                    ),
                    Text(
                      small,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((m['place'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 15,
                              color: Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m['place']!,
                              style: const TextStyle(color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      m['desc'] ?? '',
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: h ? Brand.accent : Colors.transparent,
                  border: Border.all(color: h ? Brand.accent : Colors.black12),
                ),
                child: const Icon(Icons.north_east, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final events = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Upcoming events',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      for (final m in Content.events) Reveal(child: row(m)),
    ],
  );
  final news = Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Brand.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latest news',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final m in store.news)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: pic(
                    m['img'],
                    h: 60,
                    w: 60,
                    fallback: Container(
                      width: 60,
                      height: 60,
                      color: Brand.accent.withOpacity(.25),
                      child: const Icon(Icons.newspaper, color: Brand.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['tag'] ?? '',
                        style: const TextStyle(
                          color: Brand.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        m['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      Text(
                        m['desc'] ?? '',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
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
  );
  return SectionShell(
    id: 'events',
    bg: bg,
    child: wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: events),
              const SizedBox(width: 48),
              Expanded(flex: 2, child: Reveal(child: news)),
            ],
          )
        : Column(children: [events, const SizedBox(height: 32), news]),
  );
}

// ═════════════════════════════════════════════════════════════
// RESOURCES  – list rows
// ═════════════════════════════════════════════════════════════
Widget _resources(BuildContext c, Color bg) => SectionShell(
  id: 'resources',
  bg: bg,
  child: Wrap(
    spacing: 40,
    children: [
      for (final m in Content.resources)
        Reveal(
          child: SizedBox(
            width: colW(c, 2, gap: 40),
            child: Hoverable(
              builder: (h) => InkWell(
                onTap: () => openLink(c, m['link'] ?? ''),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: h
                        ? Brand.primary.withOpacity(.04)
                        : Colors.transparent,
                    border: const Border(
                      bottom: BorderSide(color: Colors.black12),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: h
                            ? Brand.accent
                            : Brand.primary.withOpacity(.08),
                        child: Icon(
                          iconOf(m['icon'] ?? ''),
                          color: h ? Colors.black87 : Brand.primary,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (m['tag'] ?? '').toUpperCase(),
                              style: const TextStyle(
                                color: Brand.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              m['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              m['desc'] ?? '',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSlide(
                        offset: h ? const Offset(.3, 0) : Offset.zero,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  ),
);

// ═════════════════════════════════════════════════════════════
// GALLERY  – scrolling photo strip
// ═════════════════════════════════════════════════════════════
Widget _gallery(Color bg) => SectionShell(
  id: 'gallery',
  bg: bg,
  bleed: true,
  child: Marquee(
    itemWidth: 320,
    height: 210,
    seconds: 60,
    children: [
      for (final g in Content.gallery)
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: pic(g, h: 210, w: 320),
        ),
    ],
  ),
);

// ═════════════════════════════════════════════════════════════
// FAQ
// ═════════════════════════════════════════════════════════════
Widget _faq(BuildContext c, Color bg) {
  final wide = MediaQuery.of(c).size.width >= 900;
  final side = Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Brand.primary,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.forum_outlined, color: Brand.accent, size: 36),
        const SizedBox(height: 14),
        const Text(
          'Still have questions?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Our team is happy to talk through your idea.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Brand.accent,
            foregroundColor: Colors.black,
          ),
          onPressed: () => scrollToSection?.call('contact'),
          child: const Text('Contact us'),
        ),
      ],
    ),
  );
  final list = Column(
    children: [
      for (final f in Content.faqs)
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Theme(
            data: Theme.of(c).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(
                f['title'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
              expandedAlignment: Alignment.centerLeft,
              children: [
                Text(
                  f['desc'] ?? '',
                  style: const TextStyle(color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
    ],
  );
  return SectionShell(
    id: 'faq',
    bg: bg,
    child: wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: side),
              const SizedBox(width: 56),
              Expanded(child: list),
            ],
          )
        : Column(children: [list, const SizedBox(height: 28), side]),
  );
}

// ═════════════════════════════════════════════════════════════
// CTA BANNER
// ═════════════════════════════════════════════════════════════
Widget _cta(BuildContext c, Color bg) {
  final narrow = MediaQuery.of(c).size.width < 700;
  return Container(
    color: bg,
    padding: const EdgeInsets.only(bottom: 96),
    child: Box(
      max: 1200,
      pad: const EdgeInsets.symmetric(horizontal: 24),
      child: Reveal(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Brand.primary, Color(0xFF1B6CA8)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -80,
                  top: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.08),
                    ),
                  ),
                ),
                Positioned(
                  right: 120,
                  bottom: -120,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Brand.accent.withOpacity(.18),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(narrow ? 28 : 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Text(
                          Site.ctaTitle,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: narrow ? 28 : 44,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Text(
                          Site.ctaSub,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 17,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Brand.accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 20,
                              ),
                            ),
                            onPressed: () => go(c, '/incubate'),
                            child: Text(
                              Site.ctaButton,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 20,
                              ),
                            ),
                            onPressed: () => scrollToSection?.call('contact'),
                            child: Text(Site.ctaButton2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════
// CONTACT (dark)
// ═════════════════════════════════════════════════════════════
class ContactSection extends StatefulWidget {
  final Color bg;
  const ContactSection({super.key, required this.bg});
  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  final _k = GlobalKey<FormState>();
  final n = TextEditingController(),
      e = TextEditingController(),
      m = TextEditingController();

  InputDecoration _d(String l) => InputDecoration(
    labelText: l,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.white.withOpacity(.08),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(.25)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Brand.accent),
    ),
  );

  @override
  Widget build(BuildContext context) => SectionShell(
    id: 'contact',
    bg: Brand.dark,
    dark: true,
    child: Wrap(
      spacing: 48,
      runSpacing: 32,
      children: [
        SizedBox(
          width: colW(context, 2, gap: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in const [
                [Icons.place, Brand.address],
                [Icons.email, Brand.email],
                [Icons.phone, Brand.phone],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white12,
                        child: Icon(
                          r[0] as IconData,
                          color: Brand.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            r[1] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Map placeholder – replace with a screenshot, e.g. pic('assets/map.png', h: 160)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 160,
                  color: Colors.white12,
                  child: const Center(
                    child: Text(
                      'Map placeholder',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final s in Site.socials)
                    ActionChip(
                      label: Text(s[0]),
                      onPressed: () => openLink(context, s[1]),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 18,
                  ),
                ),
                onPressed: () => go(context, '/incubate'),
                child: Text(
                  Site.contactCta,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: colW(context, 2, gap: 48),
          child: Form(
            key: _k,
            child: Column(
              children: [
                TextFormField(
                  controller: n,
                  style: const TextStyle(color: Colors.white),
                  decoration: _d('Name'),
                  validator: V.req,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: e,
                  style: const TextStyle(color: Colors.white),
                  decoration: _d('Email'),
                  validator: V.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: m,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: _d('Message'),
                  validator: V.req,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () {
                      if (_k.currentState!.validate()) {
                        toast(context, 'Message sent (demo).');
                        n.clear();
                        e.clear();
                        m.clear();
                      }
                    },
                    child: const Text('Send message'),
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
