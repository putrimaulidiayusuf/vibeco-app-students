import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'praba_ai_screen.dart';
import 'camera_upload_screen.dart';
import 'clean_rank_screen.dart';
import 'clean_track_screen.dart';
import 'piket_schedule_screen.dart';
import 'profile_screen.dart';
import '../../viewmodels/student/smart_check_viewmodel.dart';
import '../../viewmodels/student/dashboard_viewmodel.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _hideNavbar = false;

  void _setPage(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 1) {
        _hideNavbar = false;
      }
    });
  }

  late AnimationController _animController;
  late Animation<double> _cameraScale;
  late Animation<double> _cameraFloat;

  late final List<Widget> _screens;
  @override
  void initState() {
    super.initState();
    _screens = [
      const SizedBox.shrink(), // 0: home (shown via _buildHomeDashboard)
      CameraUploadScreen(      // 1: camera (from navbar)
        onViewHistory: () {
          _setPage(0);
        },
        onShowCameraChanged: (showCamera) {
          setState(() {
            _hideNavbar = showCamera;
          });
        },
      ),
      const ProfileScreen(),   // 2: profile (from navbar)
    ];

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cameraScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _cameraFloat = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── SLIDE RIGHT-TO-LEFT ROUTE ───
  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SmartCheckViewModel>(
          create: (context) {
            final vm = SmartCheckViewModel();
            if (auth.token != null) {
              vm.loadStatusAndConfig(auth.token!);
            }
            return vm;
          },
        ),
        ChangeNotifierProvider<DashboardViewModel>(
          create: (context) {
            final vm = DashboardViewModel();
            if (auth.token != null) {
              vm.loadScheduleData(auth.token!);
            }
            return vm;
          },
        ),
      ],
      child: Consumer2<SmartCheckViewModel, DashboardViewModel>(
        builder: (context, statusVm, dashVm, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAF8),
            appBar: null,
            body: _currentIndex == 0
                ? _buildHomeDashboard(user, statusVm, dashVm)
                : _screens[_currentIndex],
            bottomNavigationBar: _buildNotchNavBar(),
          );
        },
      ),
    );
  }

  Widget _buildHomeDashboard(
    dynamic user,
    SmartCheckViewModel statusVm,
    DashboardViewModel dashVm,
  ) {
    final initials = user.name.isNotEmpty
        ? user.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'ST';

    // Get today's day name for the Jadwal Piket card
    final todayLabel = dashVm.todayIndonesian;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIXED HEADER
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.emeraldGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _setPage(2),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.emeraldDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo ${user.name}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jaga selalu kebersihan kelasmu ya!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.bar_chart_rounded,
                          title: 'Peringkat',
                          subtitle: 'Kelas & Global',
                          onTap: () => Navigator.push(
                            context,
                            _slideRoute(const CleanRankScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.calendar_today_rounded,
                          title: 'Jadwal Piket',
                          subtitle: todayLabel,
                          onTap: () => Navigator.push(
                            context,
                            _slideRoute(
                              ChangeNotifierProvider<DashboardViewModel>.value(
                                value: dashVm,
                                child: const PiketScheduleScreen(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.history_rounded,
                          title: 'Riwayat',
                          subtitle: 'Laporan Piket',
                          onTap: () => Navigator.push(
                            context,
                            _slideRoute(const CleanTrackScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildFeatureCardWithImage(
                        title: 'Kirim Foto Kelas Anda',
                        subtitle: 'Setor pengerjaan piket anda dan dapatkan penilaian!',
                        buttonText: 'Klik disini',
                        imagePath: 'assets/images/dummy.png',
                        onTap: () => Navigator.push(
                          context,
                          _slideRoute(
                            CameraUploadScreen(
                              asRoute: true,
                              onViewHistory: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildGeofenceCard(statusVm),
                      const SizedBox(height: 20),
                      _buildFeatureCardWithImage(
                        title: 'PRABA AI',
                        subtitle: 'Tanya seputar lingkungan pada PRABA sekarang!',
                        buttonText: 'Coba sekarang!',
                        imagePath: 'assets/images/maskot.png',
                        onTap: () => Navigator.push(
                          context,
                          _slideRoute(const PrabaAiScreen(asRoute: true)),
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150, // Increased height as requested
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A6B4F), Color(0xFF0D4230)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emeraldDark.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with simple circular background (matching reference)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle ?? '',
              style: TextStyle(
                color: subtitle == null ? Colors.transparent : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCardWithImage({
    required String title,
    required String subtitle,
    required String buttonText,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldDark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emeraldDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.emeraldMid, AppColors.primaryGreen],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imagePath,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 120,
                height: 120,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofenceCard(SmartCheckViewModel statusVm) {
    final bool isInsideSchool = statusVm.isInsideGeofence;
    final String distanceStr = statusVm.distance != null
        ? '${statusVm.distance!.toStringAsFixed(0)}m'
        : '-m';

    final Color statusColor = isInsideSchool
        ? AppColors.success
        : AppColors.error;
    final IconData statusIcon = isInsideSchool
        ? Icons.location_on_rounded
        : Icons.location_off_rounded;
    final String statusText = statusVm.isLoading
        ? 'Mengecek lokasi...'
        : (isInsideSchool
              ? 'Di dalam sekolah'
              : 'Di luar sekolah ($distanceStr)');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lokasi Anda (Geofence)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!statusVm.isLoading) {
                final auth = Provider.of<AuthService>(context, listen: false);
                if (auth.token != null) {
                  statusVm.loadStatusAndConfig(auth.token!);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusVm.isLoading
                    ? Icons.sync
                    : (isInsideSchool ? Icons.check : Icons.refresh),
                color: statusColor,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── NOTCH NAVBAR: EXACTLY like reference photo ───
  Widget _buildNotchNavBar() {
    if (_hideNavbar) return const SizedBox.shrink();
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Navbar background with REAL concave notch
          CustomPaint(
            size: Size(screenWidth, 80),
            painter: _NotchNavbarPainter(
              bgColor: Colors.white,
              shadowColor: AppColors.emeraldDark.withValues(alpha: 0.06),
            ),
          ),

          // Nav items positioned inside the navbar
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Beranda (left side)
                _buildNotchNavItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  isActive: _currentIndex == 0,
                  onTap: () => _setPage(0),
                ),

                // Spacer for camera notch area
                const SizedBox(width: 80),

                // Profil (right side)
                _buildNotchNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  isActive: _currentIndex == 2,
                  onTap: () => _setPage(2),
                ),
              ],
            ),
          ),

          // CAMERA BUTTON - Floating above the notch (like reference photo)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _cameraFloat.value),
                    child: Transform.scale(
                      scale: _cameraScale.value,
                      child: GestureDetector(
                        onTap: () => _setPage(1),
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.emeraldDark,
                                AppColors.emeraldMid,
                                AppColors.primaryGreen,
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 0),
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
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

  Widget _buildNotchNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryGreen : Colors.grey[400],
              size: isActive ? 26 : 24,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isActive ? AppColors.primaryGreen : Colors.grey[400],
                fontSize: isActive ? 12 : 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 5 : 0,
              height: isActive ? 5 : 0,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CUSTOM PAINTER: Real concave notch navbar ───
class _NotchNavbarPainter extends CustomPainter {
  final Color bgColor;
  final Color shadowColor;

  _NotchNavbarPainter({required this.bgColor, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final notchRadius = 42.0;
    final notchCenter = width / 2;
    final cornerRadius = 40.0;

    // Shadow path
    final shadowPath = Path();
    shadowPath.moveTo(0, height);
    shadowPath.lineTo(0, cornerRadius);
    shadowPath.quadraticBezierTo(0, 0, cornerRadius, 0);
    shadowPath.lineTo(notchCenter - notchRadius - 15, 0);
    shadowPath.quadraticBezierTo(
      notchCenter - notchRadius,
      0,
      notchCenter - notchRadius + 5,
      8,
    );
    shadowPath.arcToPoint(
      Offset(notchCenter + notchRadius - 5, 8),
      radius: Radius.circular(notchRadius + 5),
      clockwise: false,
    );
    shadowPath.quadraticBezierTo(
      notchCenter + notchRadius,
      0,
      notchCenter + notchRadius + 15,
      0,
    );
    shadowPath.lineTo(width - cornerRadius, 0);
    shadowPath.quadraticBezierTo(width, 0, width, cornerRadius);
    shadowPath.lineTo(width, height);
    shadowPath.close();

    // Draw shadow
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main path
    final path = Path();
    path.moveTo(0, height);
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.lineTo(notchCenter - notchRadius - 10, 0);
    path.quadraticBezierTo(
      notchCenter - notchRadius,
      0,
      notchCenter - notchRadius + 5,
      6,
    );
    path.arcToPoint(
      Offset(notchCenter + notchRadius - 5, 6),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      notchCenter + notchRadius,
      0,
      notchCenter + notchRadius + 10,
      0,
    );
    path.lineTo(width - cornerRadius, 0);
    path.quadraticBezierTo(width, 0, width, cornerRadius);
    path.lineTo(width, height);
    path.close();

    // Draw main shape
    canvas.drawPath(path, Paint()..color = bgColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
