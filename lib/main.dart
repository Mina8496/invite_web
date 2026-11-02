import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

// ================= عدّل بياناتك هنا =================
const groomEn = 'Nassem', brideEn = 'Christina';
final weddingDate = DateTime(2026, 11, 15, 17, 00);
const parents = ['السيد / سمير فؤاد ملك', 'السيد / ناجح فايز بشرى'];
const quote = 'عمر واحد...\nواخترتك معايا';
const photos = ['assets/couple_1.jpeg', 'assets/couple_2.jpeg'];
const cards = ['assets/card_rose.jpeg', 'assets/card_green.jpeg'];

class Venue {
  final String event, place, when, mapUrl;
  const Venue(this.event, this.place, this.when, this.mapUrl);
}

// حط رابط جوجل ماب في آخر كل مكان. لو فاضي زرار الخريطة بيتقفل.
const venues = [
  Venue(
    'صلاة الإكليل',
    'كاتدرائية القديس مارمرقس الرسول\nبرزقة الدير المحرق',
    'الأحد 15.11.2026 - الساعة 5:00 مساءً',
    'https://maps.app.goo.gl/aqqy4UiPGPnCx5N39',
  ),
  Venue(
    'حفل الحنة المشتركة',
    'شارع مصنع البلاط امام المطافى',
    'الجمعة 13.11.2026',
    'https://maps.app.goo.gl/QnWBsyB8ZCUU4qiy7',
  ),
];
// =====================================================

const bgTop = Color(0xFFFBF3F5), bgBottom = Color(0xFFF2D9E0);
const wine = Color(0xFF9B1B48),
    ink = Color(0xFF4A2530),
    gold = Color(0xFFC29B45);
const petal = Color(0xFFE8A3B5);

// أبعاد صورة الظرف ومكان مركز الختم (من assets/envelope.jpg)
const _iw = 900.0, _ih = 1629.0, _sealX = 0.529, _sealY = 0.554;

TextStyle ar(double s, {FontWeight w = FontWeight.w400}) =>
    GoogleFonts.amiri(fontSize: s, color: ink, fontWeight: w, height: 1.6);
TextStyle scriptFont(double s) =>
    GoogleFonts.greatVibes(fontSize: s, color: wine);

String fmtDate(String sep) =>
    '${weddingDate.day.toString().padLeft(2, '0')}$sep${weddingDate.month.toString().padLeft(2, '0')}$sep${weddingDate.year}';

Widget img(String path, {BoxFit fit = BoxFit.cover}) => Image.asset(
  path,
  fit: fit,
  errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0x22000000)),
);

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'دعوة زفاف',
    builder: (_, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const InvitePage(),
  ),
);

class InvitePage extends StatefulWidget {
  const InvitePage({super.key});
  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> with TickerProviderStateMixin {
  final _player = AudioPlayer();
  final _cardsCtrl = PageController(viewportFraction: .86);
  late final _petals = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5000),
  )..repeat();
  late final _gateCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  late final _enter = CurvedAnimation(
    parent: _gateCtrl,
    curve: const Interval(.45, 1, curve: Curves.easeOut),
  );
  Timer? _timer;
  Duration _left = Duration.zero;
  int _photo = 0, _ticks = 0;
  bool _opened = false, _gateDone = false, _playing = false;

  @override
  void initState() {
    super.initState();
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 100,
    );
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _player.setReleaseMode(ReleaseMode.loop);
    _gateCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted)
        setState(() => _gateDone = true);
    });
  }

  void _tick() {
    final d = weddingDate.difference(DateTime.now());
    setState(() {
      _left = d.isNegative ? Duration.zero : d;
      if (++_ticks % 5 == 0) _photo = (_photo + 1) % photos.length;
    });
  }

  Future<void> _open() async {
    setState(() => _opened = true);
    _gateCtrl.forward();
    try {
      await _player.play(AssetSource('songwed.mp3'));
      if (mounted) setState(() => _playing = true);
    } catch (_) {}
  }

  Future<void> _toggleMusic() async {
    try {
      _playing ? await _player.pause() : await _player.resume();
      if (mounted) setState(() => _playing = !_playing);
    } catch (_) {}
  }

  void _zoom(String path) => showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: InteractiveViewer(child: Image.asset(path)),
    ),
  );

  @override
  void dispose() {
    _timer?.cancel();
    _petals.dispose();
    _pulse.dispose();
    _shine.dispose();
    _gateCtrl.dispose();
    _cardsCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: Stack(
          children: [
            if (_opened)
              Positioned.fill(
                child: FadeTransition(opacity: _enter, child: _content()),
              ),
            if (_opened)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: PetalPainter(_petals)),
                ),
              ),
            if (!_gateDone)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _opened,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _gate(),
                    ),
                  ),
                ),
              ),
            if (_opened)
              Positioned(
                top: 12,
                left: 12,
                child: SafeArea(
                  child: IconButton.filledTonal(
                    onPressed: _toggleMusic,
                    color: wine,
                    icon: Icon(_playing ? Icons.volume_up : Icons.volume_off),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ظرف الدعوة: الختم الذهبي بيتفتح نصين والظرف ينفلق ويكشف الدعوة
  Widget _gate() => GestureDetector(
    onTap: _open,
    child: SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _iw,
          height: _ih,
          child: AnimatedBuilder(
            animation: Listenable.merge([_gateCtrl, _pulse]),
            builder: (_, __) {
              final t = Curves.easeInOutCubic.transform(_gateCtrl.value);
              const f = _sealY;
              Widget half(Alignment al, double factor) => ClipRect(
                child: Align(
                  alignment: al,
                  heightFactor: factor,
                  child: Image.asset(
                    'assets/envelope.jpg',
                    width: _iw,
                    height: _ih,
                    fit: BoxFit.fill,
                  ),
                ),
              );
              final glow = (1 - t) * (.15 + .35 * _pulse.value);
              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Transform.translate(
                      offset: Offset(0, -t * (_ih * f + 60)),
                      child: half(Alignment.topCenter, f),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Transform.translate(
                      offset: Offset(0, t * (_ih * (1 - f) + 60)),
                      child: half(Alignment.bottomCenter, 1 - f),
                    ),
                  ),
                  Positioned(
                    left: _iw * _sealX - 290,
                    top: _ih * _sealY - 290,
                    child: IgnorePointer(
                      child: Container(
                        width: 580,
                        height: 580,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: gold.withValues(alpha: glow),
                              blurRadius: 90,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _iw * _sealX - 450,
                    top: _ih * _sealY - 450,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 900,
                        height: 900,
                        child: CustomPaint(
                          painter: BurstPainter(
                            _gateCtrl.value,
                            _pulse.value,
                            _opened,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 150,
                    child: Opacity(
                      opacity: (1 - t) * (.55 + .45 * _pulse.value),
                      child: Transform.translate(
                        offset: Offset(0, -26 * _pulse.value),
                        child: Text(
                          'اضغط لفتح دعوتك',
                          textAlign: TextAlign.center,
                          style: ar(44, w: FontWeight.bold).copyWith(
                            shadows: const [
                              Shadow(color: Colors.white, blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _content() => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 48),
          child: Column(
            children: [
              _heroCard(),
              const SizedBox(height: 12),
              _scrollCue(),
              const SizedBox(height: 40),
              Reveal(child: _inviteText()),
              const SizedBox(height: 56),
              Reveal(child: _countdown()),
              const SizedBox(height: 56),
              Reveal(dy: .2, child: _gallery()),
              const SizedBox(height: 56),
              Reveal(child: _cardsCarousel()),
              const SizedBox(height: 56),
              Text('تفاصيل الحفل', style: ar(30, w: FontWeight.bold)),
              for (final v in venues) ...[
                const SizedBox(height: 24),
                Reveal(child: _venue(v)),
              ],
              const SizedBox(height: 64),
              Reveal(child: _footer()),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _scrollCue() => AnimatedBuilder(
    animation: _pulse,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, 12 * _pulse.value),
      child: const Icon(
        Icons.keyboard_double_arrow_down,
        color: gold,
        size: 34,
      ),
    ),
  );

  // لمعة بتعدي على الكارت كل كام ثانية
  Widget _shineOver(Widget child) => Stack(
    children: [
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _shine,
              builder: (_, __) {
                final v = (_shine.value / .4).clamp(0.0, 1.0);
                return FractionalTranslation(
                  translation: Offset(-.4 + 1.5 * v, 0),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: .35,
                    heightFactor: 1,
                    child: Transform(
                      transform: Matrix4.skewX(-.4),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0x77FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ],
  );

  Widget _frame(Widget child) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: gold, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2E9B1B48),
          blurRadius: 30,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: child,
  );

  Widget _heroCard() => TweenAnimationBuilder<double>(
    tween: Tween(begin: 1.08, end: 1),
    duration: const Duration(milliseconds: 3200),
    curve: Curves.easeOutCubic,
    builder: (_, s, child) => Transform.scale(scale: s, child: child),
    child: _frame(
      _shineOver(
        AspectRatio(
          aspectRatio: 1822 / 2576,
          child: img('assets/card_names.png'),
        ),
      ),
    ),
  );

  Widget _divider() => Row(
    children: [
      const Expanded(child: Divider(color: gold)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(Icons.favorite, color: gold, size: 16),
      ),
      const Expanded(child: Divider(color: gold)),
    ],
  );

  Widget _inviteText() => Column(
    children: [
      Text('وبهذه المناسبة يتشرف كلاً من', style: ar(22)),
      const SizedBox(height: 12),
      _divider(),
      const SizedBox(height: 12),
      Row(
        children: [
          for (final p in parents)
            Expanded(
              child: Text(
                p,
                textAlign: TextAlign.center,
                style: ar(24, w: FontWeight.bold),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text('بدعوة سيادتكم والعائلة لحضور', style: ar(22)),
      Text(
        'حفل زفاف',
        style: ar(36, w: FontWeight.bold).copyWith(color: wine),
      ),
    ],
  );

  Widget _countdown() {
    Widget cell(int v, String l) => Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (c, a) => SlideTransition(
            position: Tween(
              begin: const Offset(0, -.6),
              end: Offset.zero,
            ).animate(a),
            child: FadeTransition(opacity: a, child: c),
          ),
          child: Text(
            v.toString().padLeft(2, '0'),
            key: ValueKey(v),
            style: ar(42, w: FontWeight.bold).copyWith(color: wine),
          ),
        ),
        Text(l, style: ar(15)),
      ],
    );
    final sep = Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
      child: Text(':', style: ar(36)),
    );
    return Column(
      children: [
        Text('العد التنازلي لفرحتنا', style: ar(26, w: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.ltr,
          children: [
            cell(_left.inDays, 'يوم'),
            sep,
            cell(_left.inHours % 24, 'ساعة'),
            sep,
            cell(_left.inMinutes % 60, 'دقيقة'),
            sep,
            cell(_left.inSeconds % 60, 'ثانية'),
          ],
        ),
      ],
    );
  }

  // صور العروسين في قوس بتتبدل تلقائي
  Widget _gallery() {
    const arch = BorderRadius.vertical(top: Radius.circular(999));
    return Column(
      children: [
        ScaleTransition(
          scale: Tween(
            begin: .85,
            end: 1.3,
          ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
          child: const Icon(Icons.favorite, color: wine, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          quote,
          textAlign: TextAlign.center,
          style: ar(30, w: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: gold, width: 2),
            borderRadius: arch,
          ),
          child: AspectRatio(
            aspectRatio: .8,
            child: ClipRRect(
              borderRadius: arch,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 1400),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_photo),
                  tween: Tween(begin: 1.0, end: 1.15),
                  duration: const Duration(seconds: 5),
                  builder: (_, sc, child) =>
                      Transform.scale(scale: sc, child: child),
                  child: SizedBox.expand(child: img(photos[_photo])),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardsCarousel() => Column(
    children: [
      Text('كروت الدعوة', style: ar(30, w: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('اضغط على الكارت لتكبيره', style: ar(15)),
      const SizedBox(height: 16),
      SizedBox(
        height: 540,
        child: PageView(
          controller: _cardsCtrl,
          children: [
            for (final c in cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: GestureDetector(
                  onTap: () => _zoom(c),
                  child: _frame(img(c)),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _venue(Venue v) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xCCFFFFFF),
      border: Border.all(color: gold),
    ),
    child: Column(
      children: [
        const Icon(Icons.location_on, color: wine, size: 34),
        Text(
          v.event,
          style: ar(28, w: FontWeight.bold).copyWith(color: wine),
        ),
        const SizedBox(height: 4),
        Text(v.place, textAlign: TextAlign.center, style: ar(21)),
        const SizedBox(height: 8),
        Text(
          v.when,
          textAlign: TextAlign.center,
          style: ar(20, w: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: wine,
            side: const BorderSide(color: wine),
          ),
          onPressed: v.mapUrl.isEmpty
              ? null
              : () => launchUrl(Uri.parse(v.mapUrl)),
          icon: const Icon(Icons.map_outlined),
          label: Text('افتح الخريطة', style: ar(18).copyWith(color: wine)),
        ),
      ],
    ),
  );

  Widget _footer() => Column(
    children: [
      Text('في انتظاركم', style: ar(26)),
      const SizedBox(height: 8),
      Text('$groomEn & $brideEn', style: scriptFont(48)),
      Text(
        fmtDate('.'),
        style: ar(
          26,
          w: FontWeight.bold,
        ).copyWith(letterSpacing: 4, color: gold),
      ),
    ],
  );
}

class _Petal {
  final double x, phase, size;
  final int laps;
  _Petal(this.x, this.phase, this.size, this.laps);
}

class PetalPainter extends CustomPainter {
  PetalPainter(this.t) : super(repaint: t);
  final Animation<double> t;
  static final _rnd = math.Random(7);
  static final _petals = List.generate(
    36,
    (i) => _Petal(
      _rnd.nextDouble(),
      _rnd.nextDouble(),
      8 + _rnd.nextDouble() * 8,
      1 + i % 3,
    ),
  );

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()..color = petal.withAlpha(150);
    for (final p in _petals) {
      final a = 2 * math.pi * p.laps * t.value + p.phase * 6;
      final y = ((t.value * p.laps + p.phase) % 1) * (s.height + 40) - 20;
      final x = p.x * s.width + math.sin(a) * 24;
      c.save();
      c.translate(x, y);
      c.rotate(a);
      c.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 1.5,
        ),
        paint,
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PetalPainter old) => false;
}

// يظهر القسم بحركة لما توصله بالسكرول
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.dy = .12});
  final Widget child;
  final double dy;
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  final _key = UniqueKey();
  bool _shown = false;

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: _key,
    onVisibilityChanged: (i) {
      if (!_shown && i.visibleFraction > .12 && mounted)
        setState(() => _shown = true);
    },
    child: AnimatedSlide(
      offset: _shown ? Offset.zero : Offset(0, widget.dy),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        scale: _shown ? 1 : .94,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _shown ? 1 : 0,
          duration: const Duration(milliseconds: 900),
          child: widget.child,
        ),
      ),
    ),
  );
}

// موجات دهبية حوالين الختم قبل الفتح، وانفجار قصاصات ذهبية ووردية عند الفتح
class BurstPainter extends CustomPainter {
  BurstPainter(this.t, this.pulse, this.opened);
  final double t, pulse;
  final bool opened;
  static final _r = math.Random(3);
  static final _ps = List.generate(
    80,
    (i) => <double>[
      _r.nextDouble() * 2 * math.pi,
      250 + _r.nextDouble() * 650,
      6 + _r.nextDouble() * 10,
      _r.nextDouble(),
    ],
  );

  @override
  void paint(Canvas c, Size s) {
    final o = Offset(s.width / 2, s.height / 2);
    if (!opened) {
      for (var k = 0; k < 2; k++) {
        final p = (pulse + k * .5) % 1;
        c.drawCircle(
          o,
          270 + 180 * p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = gold.withValues(alpha: (1 - p) * .55),
        );
      }
      return;
    }
    if (t < .25) {
      c.drawCircle(
        o,
        280 + 900 * t,
        Paint()..color = gold.withValues(alpha: (1 - t / .25) * .7),
      );
    }
    final e = Curves.easeOutCubic.transform(t);
    const cols = [gold, wine, petal, Colors.white];
    for (var i = 0; i < _ps.length; i++) {
      final q = _ps[i];
      final d = q[1] * e;
      final pos =
          o +
          Offset(math.cos(q[0]) * d, math.sin(q[0]) * d + 700 * t * t * q[3]);
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(q[0] + t * 8 * q[3]);
      c.drawRect(
        Rect.fromCenter(center: Offset.zero, width: q[2], height: q[2] * .5),
        Paint()..color = cols[i % 4].withValues(alpha: (1 - t).clamp(0.0, 1.0)),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BurstPainter old) => true;
}
