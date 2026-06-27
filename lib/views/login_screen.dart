import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/services/auth_service.dart';
import '../viewmodels/login_viewmodel.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _ctrl;

  late final Animation<double> _cardExpand;
  late final Animation<double> _logoMove;
  late final Animation<double> _formOpacity;
  late final Animation<double> _formSlide;
  final List<Animation<double>> _fields = [];

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _cardExpand = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.60, curve: Curves.easeInOutCubic),
      ),
    );

    _logoMove = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.60, curve: Curves.easeInOut),
      ),
    );

    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.80, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(LoginViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await viewModel.login(
      identifier: _identifierController.text,
      password: _passwordController.text,
      authService: authService,
    );

    if (mounted) {
      if (success) {
        final user = authService.user;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat datang, ${user?.name ?? ""}!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const ValueKey('error_message'),
            content: Text(
              viewModel.errorMessage ?? 'Gagal masuk. Silakan coba lagi.',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _field(int index, Widget child) {
    if (index >= _fields.length) return child;
    return AnimatedBuilder(
      animation: _fields[index],
      builder: (context, child) {
        final v = _fields[index].value;
        return Transform.translate(
          offset: Offset(0, (1 - v) * 18),
          child: Opacity(opacity: v, child: child),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ChangeNotifierProvider<LoginViewModel>(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: const Color(0xFF06241B),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF06241B),
                    Color(0xFF0F4D3A),
                  ],
                ),
              ),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  final pCard = _cardExpand.value;
                  final pLogo = _logoMove.value;

                  final cardW = lerpDouble(150, size.width - 48, pCard)!;
                  final cardH = lerpDouble(150, 640, pCard)!;

                  // ── Logo ikut diturunkan: dari 55 ke 40 (sebelumnya 22) ──
                  final logoTop = lerpDouble(55, 65, pLogo)!;

                  final formOp = _formOpacity.value;
                  final formSl = _formSlide.value;

                  return Center(
                    child: Container(
                      width: cardW,
                      height: cardH,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(60),
                          bottomRight: Radius.circular(60),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12 + (pCard * 0.08)),
                            blurRadius: 20 + (pCard * 20),
                            offset: const Offset(0, 15),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(60),
                          bottomRight: Radius.circular(60),
                        ),
                        child: Stack(
                          children: [
                            // ═══════════════════════════════════════
                            // FORM (lebih ke bawah, jarak dari logo diperbesar)
                            // ═══════════════════════════════════════
                            Positioned.fill(
                              top: 132,
                              child: Opacity(
                                opacity: formOp,
                                child: IgnorePointer(
                                  ignoring: formOp < 0.3,
                                  child: Transform.translate(
                                    offset: Offset(0, formSl),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 24),

                                            // ── NAMA APLIKASI "VibEco" ──
                                            _field(
                                              0,
                                              Center(
                                                child: ShaderMask(
                                                  shaderCallback: (bounds) {
                                                    return const LinearGradient(
                                                      colors: [
                                                        Color(0xFF06241B),
                                                        Color(0xFF0F4D3A),
                                                        Color(0xFF06241B),
                                                      ],
                                                      stops: [0.0, 0.5, 1.0],
                                                    ).createShader(bounds);
                                                  },
                                                  child: const Text(
                                                    'VibEco',
                                                    style: TextStyle(
                                                      fontSize: 34,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 4,
                                                      color: Colors.white,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black12,
                                                          blurRadius: 8,
                                                          offset: Offset(0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // ── Tagline ──
                                            _field(
                                              1,
                                              Center(
                                                child: Text(
                                                  'Smart Eco Management',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1.2,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 32),

                                            // ── Title ──
                                            _field(
                                              2,
                                              Text(
                                                'Masuk ke Akun',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(
                                                        0xFF06241B,
                                                      ),
                                                      fontSize: 20,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 24),

                                            // ── NIS ──
                                            _field(
                                              3,
                                              TextFormField(
                                                key: const ValueKey(
                                                  'username_field',
                                                ),
                                                controller:
                                                    _identifierController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'NIS (Nomor Induk Siswa)',
                                                  hintText: 'Masukkan NIS',
                                                  prefixIcon: const Icon(
                                                    Icons.badge_rounded,
                                                    color: Color(0xFF0F4D3A),
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      16,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      16,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      16,
                                                    ),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFF0F4D3A),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.grey.shade50,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                                ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return 'NIS wajib diisi';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // ── Password ──
                                            _field(
                                              4,
                                              TextFormField(
                                                key: const ValueKey(
                                                  'password_field',
                                                ),
                                                controller:
                                                    _passwordController,
                                                obscureText:
                                                    viewModel.obscurePassword,
                                                decoration: InputDecoration(
                                                  labelText: 'Kata Sandi',
                                                  hintText:
                                                      'Masukkan Kata Sandi',
                                                  prefixIcon: const Icon(
                                                    Icons.lock_rounded,
                                                    color: Color(0xFF0F4D3A),
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      viewModel.obscurePassword
                                                          ? Icons
                                                              .visibility_off_rounded
                                                          : Icons
                                                              .visibility_rounded,
                                                      color: Colors.grey,
                                                    ),
                                                    onPressed: viewModel
                                                        .togglePasswordVisibility,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      16,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      16,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      16,
                                                    ),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFF0F4D3A),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.grey.shade50,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                                ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Kata sandi wajib diisi';
                                                  }
                                                  if (value.length < 4) {
                                                    return 'Kata sandi minimal 4 karakter';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 32),

                                            // ── Button ──
                                            _field(
                                              5,
                                              viewModel.isLoading
                                                  ? const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Color(
                                                          0xFF0F4D3A,
                                                        ),
                                                        strokeWidth: 3,
                                                      ),
                                                    )
                                                  : ElevatedButton(
                                                      key: const ValueKey(
                                                        'login_button',
                                                      ),
                                                      onPressed: () =>
                                                          _handleLogin(viewModel),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                          0xFF0F4D3A,
                                                        ),
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          vertical: 16,
                                                        ),
                                                        shape:
                                                            const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                              30,
                                                            ),
                                                            bottomRight:
                                                                Radius.circular(
                                                              30,
                                                            ),
                                                          ),
                                                        ),
                                                        elevation: 0,
                                                      ),
                                                      child: const Text(
                                                        'Masuk',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(height: 24),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ═══════════════════════════════════════
                            // LOGO (ikut diturunkan, seimbang dengan form)
                            // ═══════════════════════════════════════
                            Positioned(
                              top: logoTop,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Image.asset(
                                  'assets/images/dummy.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}