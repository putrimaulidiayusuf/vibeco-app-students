import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/ranking_model.dart';
import '../../viewmodels/student/clean_rank_viewmodel.dart';

class CleanRankScreen extends StatefulWidget {
  const CleanRankScreen({super.key});

  @override
  State<CleanRankScreen> createState() => _CleanRankScreenState();
}

class _CleanRankScreenState extends State<CleanRankScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _classPeriodTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _classPeriodTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _classPeriodTabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll(CleanRankViewModel viewModel) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;
    if (token == null) return;
    await viewModel.fetchAllData(token);
  }

  // ─── PODIUM COMPONENT (TOP 3 CLASSES) ───
  Widget _buildPodium(List<ClassRanking> rankings, String? currentUserClass) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    final first = rankings[0];
    final second = rankings.length > 1 ? rankings[1] : null;
    final third = rankings.length > 2 ? rankings[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldDark.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            AnimatedPodiumItem(
              key: ValueKey('class_${second.className}_2'),
              title: second.className,
              score: second.score,
              scoreText: '${second.score.toStringAsFixed(0)} pts',
              position: 2,
              isCurrentUser: currentUserClass == second.className,
              icon: Icons.eco_rounded,
              iconColor: AppColors.emeraldMid.withValues(alpha: 0.7),
              height: 100,
              pedestalGradient: const LinearGradient(
                colors: [
                  Color(0xFFE8ECEF),
                  Color(0xFFB0BEC5),
                  Color(0xFF607D8B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              medalText: '🥈',
            )
          else
            const SizedBox(width: 85),

          // 1st Place
          AnimatedPodiumItem(
            key: ValueKey('class_${first.className}_1'),
            title: first.className,
            score: first.score,
            scoreText: '${first.score.toStringAsFixed(0)} pts',
            position: 1,
            isCurrentUser: currentUserClass == first.className,
            icon: Icons.eco_rounded,
            iconColor: AppColors.primaryGreen,
            height: 140,
            pedestalGradient: const LinearGradient(
              colors: [
                Color(0xFFFFDF00),
                Color(0xFFD4AF37),
                Color(0xFF996515),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            medalText: '👑',
          ),

          // 3rd Place
          if (third != null)
            AnimatedPodiumItem(
              key: ValueKey('class_${third.className}_3'),
              title: third.className,
              score: third.score,
              scoreText: '${third.score.toStringAsFixed(0)} pts',
              position: 3,
              isCurrentUser: currentUserClass == third.className,
              icon: Icons.eco_rounded,
              iconColor: AppColors.emeraldMid.withValues(alpha: 0.7),
              height: 80,
              pedestalGradient: const LinearGradient(
                colors: [
                  Color(0xFFFFCC80),
                  Color(0xFFCA6F1E),
                  Color(0xFF7E5109),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              medalText: '🥉',
            )
          else
            const SizedBox(width: 85),
        ],
      ),
    );
  }

  // ─── CLASS RANKINGS TAB LIST ───
  Widget _buildClassRankingList(
    CleanRankViewModel viewModel,
    List<ClassRanking> rankings,
    String? currentUserClass,
  ) {
    if (viewModel.isLoading && rankings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (rankings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.leaderboard_rounded,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada peringkat untuk periode ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Remaining rankings starting from index 3
    final listItems = rankings.length > 3
        ? rankings.sublist(3)
        : <ClassRanking>[];

    return RefreshIndicator(
      onRefresh: () => _refreshAll(viewModel),
      color: AppColors.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Podium for top 3
          _buildPodium(rankings, currentUserClass),
          const SizedBox(height: 24),

          if (listItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Peringkat Kelas Lainnya',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.emeraldDark,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listItems.length,
              itemBuilder: (context, index) {
                final rank = listItems[index];
                final isCurrentUserClass = currentUserClass == rank.className;

                return AnimatedRankingRow(
                  index: index,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isCurrentUserClass
                          ? AppColors.primaryGreen.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrentUserClass
                            ? AppColors.primaryGreen.withValues(alpha: 0.3)
                            : Colors.grey.shade100,
                        width: isCurrentUserClass ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emeraldDark.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCurrentUserClass
                              ? AppColors.primaryGreen
                              : const Color(0xFFE8F0EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            rank.rank.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: isCurrentUserClass
                                  ? Colors.white
                                  : AppColors.emeraldDark,
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            rank.className,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: isCurrentUserClass
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                          if (isCurrentUserClass) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Kelas Saya',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryDark,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            color: isCurrentUserClass
                                ? AppColors.primaryGreen
                                : AppColors.emeraldMid.withValues(alpha: 0.6),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${rank.score.toStringAsFixed(0)} pts',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: isCurrentUserClass
                                  ? AppColors.primaryGreen
                                  : AppColors.emeraldMid,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─── CLASS PICK PICKET DAY PODIUM (TOP 3 PIKET DAYS) ───
  Widget _buildClassDayPodium(List<PiketDayRanking> rankings) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    final first = rankings[0];
    final second = rankings.length > 1 ? rankings[1] : null;
    final third = rankings.length > 2 ? rankings[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldDark.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            AnimatedPodiumItem(
              key: ValueKey('day_${second.dayNameId}_2'),
              title: second.dayNameId,
              score: second.averageScore,
              scoreText: '${second.averageScore.toStringAsFixed(1)} pts',
              position: 2,
              isCurrentUser: false,
              icon: Icons.star_rounded,
              iconColor: AppColors.warning,
              height: 100,
              pedestalGradient: const LinearGradient(
                colors: [
                  Color(0xFFE8ECEF),
                  Color(0xFFB0BEC5),
                  Color(0xFF607D8B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              medalText: '🥈',
            )
          else
            const SizedBox(width: 85),

          // 1st Place
          AnimatedPodiumItem(
            key: ValueKey('day_${first.dayNameId}_1'),
            title: first.dayNameId,
            score: first.averageScore,
            scoreText: '${first.averageScore.toStringAsFixed(1)} pts',
            position: 1,
            isCurrentUser: false,
            icon: Icons.star_rounded,
            iconColor: AppColors.warning,
            height: 140,
            pedestalGradient: const LinearGradient(
              colors: [
                Color(0xFFFFDF00),
                Color(0xFFD4AF37),
                Color(0xFF996515),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            medalText: '👑',
          ),

          // 3rd Place
          if (third != null)
            AnimatedPodiumItem(
              key: ValueKey('day_${third.dayNameId}_3'),
              title: third.dayNameId,
              score: third.averageScore,
              scoreText: '${third.averageScore.toStringAsFixed(1)} pts',
              position: 3,
              isCurrentUser: false,
              icon: Icons.star_rounded,
              iconColor: AppColors.warning,
              height: 80,
              pedestalGradient: const LinearGradient(
                colors: [
                  Color(0xFFFFCC80),
                  Color(0xFFCA6F1E),
                  Color(0xFF7E5109),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              medalText: '🥉',
            )
          else
            const SizedBox(width: 85),
        ],
      ),
    );
  }

  // ─── CLEANEST PIKET DAYS TAB LIST ───
  Widget _buildClassRankingListBreakdown(
    CleanRankViewModel viewModel,
    List<PiketDayRanking> rankings,
  ) {
    if (viewModel.isLoading && rankings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (rankings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cleaning_services_rounded,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data piket terverifikasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final listItems = rankings.length > 3
        ? rankings.sublist(3)
        : <PiketDayRanking>[];

    return RefreshIndicator(
      onRefresh: () => _refreshAll(viewModel),
      color: AppColors.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _buildClassDayPodium(rankings),
          const SizedBox(height: 24),

          if (listItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Hari Piket Lainnya',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.emeraldDark,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listItems.length,
              itemBuilder: (context, index) {
                final rank = listItems[index];

                return AnimatedRankingRow(
                  index: index,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emeraldDark.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            rank.rank.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        rank.dayNameId,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                      subtitle: Text(
                        '${rank.piketCount} piket diverifikasi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${rank.averageScore.toStringAsFixed(1)} pts',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─── CLASS LIST TAB PERIOD CONTAINER (DAILY, WEEKLY, MONTHLY) ───
  Widget _buildClassRankingTabContainer(
    CleanRankViewModel viewModel,
    String? currentUserClass,
  ) {
    return Column(
      children: [
        // Premium capsule Sub-TabBar (Daily, Weekly, Monthly)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _classPeriodTabController,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: AppColors.emeraldMid.withValues(alpha: 0.6),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Harian'),
                Tab(text: 'Mingguan'),
                Tab(text: 'Bulanan'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _classPeriodTabController,
            children: [
              _buildClassRankingList(
                viewModel,
                viewModel.dailyRankings,
                currentUserClass,
              ),
              _buildClassRankingList(
                viewModel,
                viewModel.weeklyRankings,
                currentUserClass,
              ),
              _buildClassRankingList(
                viewModel,
                viewModel.monthlyRankings,
                currentUserClass,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final currentUserClass = auth.user?.className;

    return ChangeNotifierProvider<CleanRankViewModel>(
      create: (context) {
        final vm = CleanRankViewModel();
        if (auth.token != null) {
          vm.fetchAllData(auth.token!);
        }
        return vm;
      },
      child: Consumer<CleanRankViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAF8),
            appBar: AppBar(
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.emeraldGradient,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peringkat Kebersihan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Kompetisi kebersihan kelas dan hari piket',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: TabBar(
                  controller: _mainTabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                  indicatorColor: Colors.white,
                  indicatorWeight: 3.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Peringkat Kelas'),
                    Tab(text: 'Hari Terbersih'),
                  ],
                ),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: viewModel.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            viewModel.error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _refreshAll(viewModel),
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              'Coba Lagi',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _mainTabController,
                    children: [
                      _buildClassRankingTabContainer(
                        viewModel,
                        currentUserClass,
                      ),
                      _buildClassRankingListBreakdown(
                        viewModel,
                        viewModel.classRankings,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ─── STYLISH ANIMATED PODIUM ITEM (TOP 3 PIKET DAYS OR CLASSES) ───
class AnimatedPodiumItem extends StatefulWidget {
  final String title;
  final double score;
  final String scoreText;
  final int position;
  final bool isCurrentUser;
  final IconData icon;
  final Color iconColor;
  final double height;
  final LinearGradient pedestalGradient;
  final String medalText;

  const AnimatedPodiumItem({
    super.key,
    required this.title,
    required this.score,
    required this.scoreText,
    required this.position,
    required this.isCurrentUser,
    required this.icon,
    required this.iconColor,
    required this.height,
    required this.pedestalGradient,
    required this.medalText,
  });

  @override
  State<AnimatedPodiumItem> createState() => _AnimatedPodiumItemState();
}

class _AnimatedPodiumItemState extends State<AnimatedPodiumItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Stagger heights and entry by position (Order: 1 -> 2 -> 3):
    // Rank 1 starts at 0.0, ends height at 0.6
    // Rank 2 starts at 0.2, ends height at 0.8
    // Rank 3 starts at 0.4, ends height at 1.0
    double start = 0.0;
    if (widget.position == 2) {
      start = 0.2;
    } else if (widget.position == 3) {
      start = 0.4;
    }

    _heightAnimation = Tween<double>(begin: 0.0, end: widget.height).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, start + 0.6, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start + 0.3, start + 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start + 0.2, start + 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedPodiumItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.score != widget.score) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentHeight = _heightAnimation.value;
        final currentOpacity = _opacityAnimation.value;
        final currentSlide = _slideAnimation.value;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Floating items above the pedestal
            Opacity(
              opacity: currentOpacity,
              child: Transform.translate(
                offset: Offset(0, currentSlide),
                child: Column(
                  children: [
                    // Medal / Crown Circle Badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.position == 1
                              ? const Color(0xFFFFD43B)
                              : (widget.position == 2
                                  ? const Color(0xFFC0C0C0)
                                  : const Color(0xFFCD7F32)),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emeraldDark.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.medalText,
                        style: TextStyle(
                          fontSize: widget.position == 1 ? 26 : 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title Card (Class / Day name)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      constraints: const BoxConstraints(maxWidth: 95),
                      decoration: BoxDecoration(
                        gradient: widget.isCurrentUser
                            ? const LinearGradient(
                                colors: [
                                  AppColors.primaryGreen,
                                  AppColors.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: widget.isCurrentUser ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isCurrentUser
                              ? Colors.white
                              : AppColors.primaryGreen.withValues(alpha: 0.12),
                          width: widget.isCurrentUser ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emeraldDark.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: widget.position == 1 ? 12 : 10.5,
                          color: widget.isCurrentUser
                              ? Colors.white
                              : AppColors.emeraldDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Score
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          size: 12,
                          color: widget.isCurrentUser
                              ? AppColors.primaryGreen
                              : widget.iconColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.scoreText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.isCurrentUser
                                ? AppColors.primaryGreen
                                : AppColors.emeraldDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Pedestal Bar Chart/Graph
            Container(
              width: 85,
              height: currentHeight,
              decoration: BoxDecoration(
                gradient: widget.pedestalGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.pedestalGradient.colors[1].withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: widget.isCurrentUser
                    ? Border.all(color: Colors.white, width: 2.5)
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.7,
                      ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle vertical glass shine reflection effect
                  Positioned(
                    left: 4,
                    top: 4,
                    bottom: 4,
                    width: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                  Text(
                    '#${widget.position}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: widget.position == 1 ? 26 : 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.95),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── STAGGERED LIST ROW ENTRANCE ANIMATION ───
class AnimatedRankingRow extends StatefulWidget {
  final int index;
  final Widget child;

  const AnimatedRankingRow({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<AnimatedRankingRow> createState() => _AnimatedRankingRowState();
}

class _AnimatedRankingRowState extends State<AnimatedRankingRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Stagger based on index
    // Delay is 80ms per index, capped at 480ms max delay
    final delayMs = (widget.index * 80).clamp(0, 480);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
