import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/ranking_model.dart';
import '../../viewmodels/student/clean_rank_viewmodel.dart';

class CleanRankScreen extends StatefulWidget {
  const CleanRankScreen({super.key});

  @override
  State<CleanRankScreen> createState() => _CleanRankScreenState();
}

class _CleanRankScreenState extends State<CleanRankScreen> with TickerProviderStateMixin {
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
  Widget _buildPodiumItem({
    required ClassRanking ranking,
    required double height,
    required LinearGradient pedestalGradient,
    required String medalText,
    required bool isCurrentUserClass,
    required int position,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (position * 150)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Medal Badge floating
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Text(
              medalText,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(height: 6),
          // Class Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentUserClass ? AppColors.primaryGreen : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentUserClass ? Colors.white : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              ranking.className,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: position == 1 ? 14 : 12,
                color: isCurrentUserClass ? Colors.white : AppColors.emeraldDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          // Score
          Text(
            '${ranking.score.toStringAsFixed(0)} pts',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCurrentUserClass ? AppColors.primaryGreen : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          // Pedestal
          Container(
            width: 85,
            height: height,
            decoration: BoxDecoration(
              gradient: pedestalGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: pedestalGradient.colors.first.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
              border: isCurrentUserClass
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '#$position',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<ClassRanking> rankings, String? currentUserClass) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    final first = rankings[0];
    final second = rankings.length > 1 ? rankings[1] : null;
    final third = rankings.length > 2 ? rankings[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _buildPodiumItem(
              ranking: second,
              height: 90,
              pedestalGradient: const LinearGradient(
                colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              medalText: '🥈',
              isCurrentUserClass: currentUserClass == second.className,
              position: 2,
            )
          else
            const SizedBox(width: 85),

          // 1st Place
          _buildPodiumItem(
            ranking: first,
            height: 125,
            pedestalGradient: const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            medalText: '👑',
            isCurrentUserClass: currentUserClass == first.className,
            position: 1,
          ),

          // 3rd Place
          if (third != null)
            _buildPodiumItem(
              ranking: third,
              height: 70,
              pedestalGradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFD84315)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              medalText: '🥉',
              isCurrentUserClass: currentUserClass == third.className,
              position: 3,
            )
          else
            const SizedBox(width: 85),
        ],
      ),
    );
  }

  // ─── CLASS RANKINGS TAB LIST ───
  Widget _buildClassRankingList(CleanRankViewModel viewModel, List<ClassRanking> rankings, String? currentUserClass) {
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
                Icon(Icons.leaderboard_rounded, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada peringkat untuk periode ini',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Remaining rankings starting from index 3
    final listItems = rankings.length > 3 ? rankings.sublist(3) : <ClassRanking>[];

    return RefreshIndicator(
      onRefresh: () => _refreshAll(viewModel),
      color: AppColors.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Podium for top 3
          _buildPodium(rankings, currentUserClass),
          const SizedBox(height: 24),

          if (listItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Peringkat Kelas Lainnya',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.emeraldDark,
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isCurrentUserClass ? const Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrentUserClass ? AppColors.primaryGreen : Colors.grey.shade100,
                      width: isCurrentUserClass ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCurrentUserClass
                            ? AppColors.primaryGreen
                            : const Color(0xFFF0F2F0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          rank.rank.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrentUserClass ? Colors.white : AppColors.emeraldDark,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          rank.className,
                          style: TextStyle(
                            fontWeight: isCurrentUserClass ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                        if (isCurrentUserClass) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'KELAS SAYA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Text(
                      '${rank.score.toStringAsFixed(0)} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isCurrentUserClass ? AppColors.primaryGreen : AppColors.emeraldMid,
                        fontSize: 15,
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
  Widget _buildClassDayPodiumItem({
    required PiketDayRanking ranking,
    required double height,
    required LinearGradient pedestalGradient,
    required String medalText,
    required int position,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (position * 150)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Medal Badge floating
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Text(
              medalText,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(height: 6),
          // Day name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              ranking.dayNameId,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.emeraldDark,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Score
          Text(
            '${ranking.averageScore.toStringAsFixed(1)} pts',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          // Pedestal
          Container(
            width: 85,
            height: height,
            decoration: BoxDecoration(
              gradient: pedestalGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: pedestalGradient.colors.first.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: Text(
                '#$position',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDayPodium(List<PiketDayRanking> rankings) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    final first = rankings[0];
    final second = rankings.length > 1 ? rankings[1] : null;
    final third = rankings.length > 2 ? rankings[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _buildClassDayPodiumItem(
              ranking: second,
              height: 90,
              pedestalGradient: const LinearGradient(
                colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              medalText: '🥈',
              position: 2,
            )
          else
            const SizedBox(width: 85),

          // 1st Place
          _buildClassDayPodiumItem(
            ranking: first,
            height: 125,
            pedestalGradient: const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            medalText: '👑',
            position: 1,
          ),

          // 3rd Place
          if (third != null)
            _buildClassDayPodiumItem(
              ranking: third,
              height: 70,
              pedestalGradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFD84315)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              medalText: '🥉',
              position: 3,
            )
          else
            const SizedBox(width: 85),
        ],
      ),
    );
  }

  // ─── CLEANEST PIKET DAYS TAB LIST ───
  Widget _buildClassRankingListBreakdown(CleanRankViewModel viewModel, List<PiketDayRanking> rankings) {
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
                Icon(Icons.cleaning_services_rounded, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada data piket terverifikasi',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final listItems = rankings.length > 3 ? rankings.sublist(3) : <PiketDayRanking>[];

    return RefreshIndicator(
      onRefresh: () => _refreshAll(viewModel),
      color: AppColors.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _buildClassDayPodium(rankings),
          const SizedBox(height: 24),

          if (listItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Hari Piket Lainnya',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.emeraldDark,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listItems.length,
              itemBuilder: (context, index) {
                final rank = listItems[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F2F0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          rank.rank.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      rank.dayNameId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                    subtitle: Text('${rank.piketCount} piket diverifikasi'),
                    trailing: Text(
                      '${rank.averageScore.toStringAsFixed(1)} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                        fontSize: 15,
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
  Widget _buildClassRankingTabContainer(CleanRankViewModel viewModel, String? currentUserClass) {
    return Column(
      children: [
        // Premium capsule Sub-TabBar (Daily, Weekly, Monthly)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _classPeriodTabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
              _buildClassRankingList(viewModel, viewModel.dailyRankings, currentUserClass),
              _buildClassRankingList(viewModel, viewModel.weeklyRankings, currentUserClass),
              _buildClassRankingList(viewModel, viewModel.monthlyRankings, currentUserClass),
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
            body: Column(
              children: [
                // ─── PREMIUM GRADIENT HEADER WITH TABBAR ───
                Container(
                  width: double.infinity,
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        children: [
                          const Text(
                            'Peringkat Kebersihan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Kompetisi kebersihan kelas dan hari piket',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Main sliding TabBar
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TabBar(
                              controller: _mainTabController,
                              labelColor: AppColors.emeraldDark,
                              unselectedLabelColor: Colors.white,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(21),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              dividerColor: Colors.transparent,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              tabs: const [
                                Tab(text: 'Peringkat Kelas'),
                                Tab(text: 'Hari Terbersih'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ─── MAIN TAB CONTENT ───
                Expanded(
                  child: viewModel.error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                                const SizedBox(height: 12),
                                Text(
                                  viewModel.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _refreshAll(viewModel),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : TabBarView(
                          controller: _mainTabController,
                          children: [
                            _buildClassRankingTabContainer(viewModel, currentUserClass),
                            _buildClassRankingListBreakdown(viewModel, viewModel.classRankings),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
