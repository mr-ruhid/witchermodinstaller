import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _particleController;
  late AnimationController _fallingIconController;
  late AnimationController _bgScaleController;
  late AnimationController _logoRevealController;
  late AnimationController _glowController; // Əlavə olundu: Logonun arxasındakı aura üçün

  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 1. Yüklənmə faizi və əsas vaxt animasiyası (Vaxt 8 saniyəyə artırıldı)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _progressController.addListener(() {
      setState(() {});
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Yüklənmə bitdikdə Ana Səhifəyə keç
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    _progressController.forward();

    // 2. Arxa planın yüngülcə yaxınlaşması (Daha dinamik və az quru görünməsi üçün)
    _bgScaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    _bgScaleController.forward();

    // 3. Əsas Logonun yanaraq gəlməsi animasiyası
    _logoRevealController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // 3 saniyə ərzində yanaraq açılır
    );
    _logoRevealController.forward();

    // 3.1 Logonun arxasındakı duman/alov effekti (Daimi nəfəs alır)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 4. Alov və kül qığılcımları animasiyası
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    // Ekranda daha çox və sıx qığılcımlar (150 ədəd)
    for (int i = 0; i < 150; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.001 + _random.nextDouble() * 0.004,
        size: 1.0 + _random.nextDouble() * 3.5,
        opacity: _random.nextDouble(),
      ));
    }

    _particleController.addListener(() {
      _updateParticles();
    });
    _particleController.repeat();

    // 5. Göydən yanan şəkildə düşən ikon animasiyası
    _fallingIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _fallingIconController.repeat();
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.y -= particle.speed;
      particle.x += (_random.nextDouble() - 0.5) * 0.003;

      if (particle.y < 0) {
        particle.y = 1.0;
        particle.x = _random.nextDouble();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _progressController.dispose();
    _particleController.dispose();
    _fallingIconController.dispose();
    _bgScaleController.dispose();
    _logoRevealController.dispose();
    _glowController.dispose(); // Əlavə olundu
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final int percentage = (_progressController.value * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Arxa Plan Şəkli (Yüngül Zoom effekti ilə birlikdə)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgScaleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_bgScaleController.value * 0.1), // 10% yaxınlaşır
                  child: Image.asset(
                    'assets/images/loading_bg.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('Arxa plan şəkli tapılmadı', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                );
              },
            ),
          ),

          // 1.1 Sinematik Kölgə (Qaranlıqlaşdırıcı qat ki, alovlar və yazılar daha yaxşı görünsün)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // 2. Alov Qığılcımları və Kül Effekti
          Positioned.fill(
            child: CustomPaint(
              painter: ParticlePainter(_particles),
            ),
          ),

          // 3. Göydən düşən yanan ikon
          AnimatedBuilder(
            animation: _fallingIconController,
            builder: (context, child) {
              final double fallingY = -100 + (_fallingIconController.value * (size.height + 200));
              final double wobble = sin(_fallingIconController.value * pi * 4) * 30;

              return Positioned(
                left: (size.width * 0.65) + wobble,
                top: fallingY,
                child: Transform.rotate(
                  angle: _fallingIconController.value * pi * 2,
                  child: const Icon(
                    Icons.whatshot,
                    color: Colors.deepOrangeAccent,
                    size: 40,
                    shadows: [
                      Shadow(color: Colors.red, blurRadius: 20),
                      Shadow(color: Colors.orange, blurRadius: 40),
                    ],
                  ),
                ),
              );
            },
          ),

          // 4. Sağ Tərəfdəki Boşluğa Yanaraq Gələn Əsas Logo (logohead.webp)
          Positioned(
            top: size.height * 0.1,
            right: size.width * 0.05,
            child: SizedBox(
              width: size.width * 0.4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 4.1 Logonun arxasındakı qaranlıq duman və alov aurası
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoRevealController, _glowController]),
                    builder: (context, child) {
                      final double reveal = _logoRevealController.value;
                      final double pulse = _glowController.value * 0.15; // 0.0-dan 0.15-ə qədər böyüyür

                      return Opacity(
                        opacity: reveal.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 1.0 + pulse,
                          child: Container(
                            width: size.width * 0.35,
                            height: size.width * 0.15,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(100),
                              gradient: RadialGradient(
                                colors: [
                                  Colors.black.withOpacity(0.9), // Tünd mərkəz (kölgə yaradır ki, logo seçilsin)
                                  Colors.deepOrange.withOpacity(0.5), // Alovlu aura
                                  Colors.redAccent.withOpacity(0.2), // Kənar qırmızı duman
                                  Colors.transparent,
                                ],
                                stops: const [0.2, 0.6, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 4.2 Əsas Logo Animasiyası
                  AnimatedBuilder(
                    animation: _logoRevealController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (Rect bounds) {
                          // Alov effekti ilə şəklin kəsilərək açılması
                          return LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: const [
                              Colors.white, // Tam görünən hissə
                              Colors.orangeAccent, // Yanan kənar
                              Colors.red, // Alovlu uc
                              Colors.transparent, // Hələ görünməyən hissə
                            ],
                            stops: [
                              0.0,
                              (_logoRevealController.value - 0.2).clamp(0.0, 1.0),
                              (_logoRevealController.value).clamp(0.0, 1.0),
                              (_logoRevealController.value + 0.1).clamp(0.0, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: Image.asset(
                          'assets/images/logohead.webp', // Format .webp olaraq dəyişdirildi
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. Yüklənmə Logosu (İçi dolan effekt) və Faiz Yazısı
          Positioned(
            bottom: size.height * 0.08,
            right: size.width * 0.05,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Yüklənmə faizi mətni (Qədimi və Qızılı Stil)
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Color(0xFFE5C07B), // Qədimi qızılı/sarımtıl rəng
                    fontSize: 45,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 3.0,
                    fontFamily: 'serif', // Qədimi serif şrifti
                    shadows: [
                      Shadow(color: Colors.redAccent, blurRadius: 15),
                      Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(2, 2)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // İçi dolan logo animasiyası (lbar2 solğun, lbar1 əsl rənglidir)
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Solğun arxa plan logosu (lbar2)
                      Image.asset(
                        'assets/images/lbar2.png',
                        fit: BoxFit.contain,
                        color: Colors.white.withOpacity(0.2), // Solğunluq effekti
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.download, size: 40, color: Colors.grey),
                      ),
                      // Rəngli ön logo (lbar1 - Aşağıdan yuxarı dolur)
                      ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          heightFactor: _progressController.value, // Dolma miqdarı
                          child: Image.asset(
                            'assets/images/lbar1.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
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
    );
  }
}

// --- PARTICLE SİSTEMİ (Qığılcım və kül üçün) ---

class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.shader = RadialGradient(
        colors: [
          Colors.orangeAccent.withOpacity(particle.opacity),
          Colors.red.withOpacity(particle.opacity * 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(particle.x * size.width, particle.y * size.height),
        radius: particle.size * 2,
      ));

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}