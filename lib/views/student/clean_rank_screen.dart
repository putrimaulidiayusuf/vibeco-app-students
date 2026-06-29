import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
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
  late TabController _globalTabController;
  CleanRankViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _globalTabController = TabController(length: 3, vsync: this);
    
    _mainTabController.addListener(_handleMainTabSelection);
    _globalTabController.addListener(_handleGlobalTabSelection);
    
    // Initial fetch after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _viewModel != null) {
        _fetchRankings();
      }
    });
  }

  @override
  void dispose() {
    _mainTabController.removeListener(_handleMainTabSelection);
    _globalTabController.removeListener(_handleGlobalTabSelection);
    _mainTabController.dispose();
    _globalTabController.dispose();
    super.dispose();
  }

  void _handleMainTabSelection() {
    if (_mainTabController.indexIsChanging && _viewModel != null) {
      _fetchRankings();
    }
  }

  void _handleGlobalTabSelection() {
    if (_globalTabController.indexIsChanging && _viewModel != null) {
      _fetchRankings();
    }
  }

  String _getGlobalInterval() {
    switch (_globalTabController.index) {
      case 1:
        return 'weekly';
      case 2:
        return 'monthly';
      default:
        return 'daily';
    }
  }

  Future<void> _fetchRankings() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;
    if (token == null || _viewModel == null) return;

    if (_mainTabController.index == 0) {
      await _viewModel!.fetchClassRankings(token);
    } else {
      final interval = _getGlobalInterval();
      await _viewModel!.fetchRankings(token, interval);
    }
  }

  Widget _buildPodiumItem({
    required ClassRanking ranking,
    required double height,
    required Color color,
    required String medalText,
    required bool isCurrentUserClass,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          ranking.className,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isCurrentUserClass ? 16 : 14,
            color: isCurrentUserClass ? AppTheme.primaryDark : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${ranking.score.toStringAsFixed(0)} pts',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 8),
        Container(
          width: 85,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusMedium),
              topRight: Radius.circular(AppTheme.radiusMedium),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
            border: isCurrentUserClass
                ? Border.all(color: AppTheme.primaryDark, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              medalText,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<ClassRanking> rankings, String? currentUserClass) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    final first = rankings[0];
    final second = rankings.length > 1 ? rankings[1] : null;
    final third = rankings.length > 2 ? rankings[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _buildPodiumItem(
              ranking: second,
              height: 100,
              color: AppTheme.silver,
              medalText: '🥈',
              isCurrentUserClass: currentUserClass == second.className,
            )
          else
            const SizedBox(width: 85),

          // 1st Place
          _buildPodiumItem(
            ranking: first,
            height: 140,
            color: AppTheme.gold,
            medalText: '🥇',
            isCurrentUserClass: currentUserClass == first.className,
          ),

          // 3rd Place
          if (third != null)
            _buildPodiumItem(
              ranking: third,
              height: 80,
              color: AppTheme.bronze,
              medalText: '🥉',
              isCurrentUserClass: currentUserClass == third.className,
            )
          else
            const SizedBox(width: 85),
        ],
      ),
    );
  }

  Widget _buildRankingList(CleanRankViewModel viewModel, List<ClassRanking> rankings, String? currentUserClass) {
    if (viewModel.isLoading && rankings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rankings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Center(
            child: Column(
              children: [
                Icon(Icons.leaderboard_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Belum ada peringkat untuk periode ini.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
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
      onRefresh: _fetchRankingsForTab,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // Podium for top 3
          _buildPodium(rankings, currentUserClass),
          const SizedBox(height: 20),

          if (listItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text(
                'Peringkat Kelas Lainnya',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listItems.length,
              itemBuilder: (context, index) {
                final rank = listItems[index];
                final isCurrentUserClass = currentUserClass == rank.className;

                return Card(
                  color: isCurrentUserClass ? AppTheme.surfaceGreen : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    side: isCurrentUserClass
                        ? const BorderSide(color: AppTheme.primaryGreen, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCurrentUserClass ? AppTheme.primaryGreen : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          rank.rank.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrentUserClass ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      rank.className,
                      style: TextStyle(
                        fontWeight: isCurrentUserClass ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: Text(
                      '${rank.score.toStringAsFixed(0)} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        fontSize: 16,
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

  Widget _buildClassPodiumItem({
    required PiketDayRanking ranking,
    required double height,
    required Color color,
    required String medalText,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          ranking.dayNameId,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${ranking.averageScore.toStringAsFixed(1)} pts',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 8),
        Container(
          width: 85,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusMedium),
              topRight: Radius.circular(AppTheme.radiusMedium),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Center(
            child: Text(
              medalText,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassPodium(List<PiketDayRanking> rankings) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    final first = rankings[0];
    final second = rankings.length > 1 ? rankings[1] : null;
    final third = rankings.length > 2 ? rankings[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _buildClassPodiumItem(
              ranking: second,
              height: 100,
              color: AppTheme.silver,
              medalText: '🥈',
            )
          else
            const SizedBox(width: 85),

          // 1st Place
          _buildClassPodiumItem(
            ranking: first,
            height: 140,
            color: AppTheme.gold,
            medalText: '🥇',
          ),

          // 3rd Place
          if (third != null)
            _buildClassPodiumItem(
              ranking: third,
              height: 80,
              color: AppTheme.bronze,
              medalText: '🥉',
            )
          else
            const SizedBox(width: 85),
        ],
      ),
    );
  }

  Widget _buildClassRankingList(CleanRankViewModel viewModel, List<PiketDayRanking> rankings) {
    if (viewModel.isLoading && rankings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rankings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Center(
            child: Column(
              children: [
                Icon(Icons.leaderboard_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Belum ada data peringkat kelas.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final listItems = rankings.length > 3 ? rankings.sublist(3) : <PiketDayRanking>[];

    return RefreshIndicator(
      onRefresh: _fetchRankings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildClassPodium(rankings),
          const SizedBox(height: 20),

          if (listItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text(
                'Hari Piket Lainnya',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listItems.length,
              itemBuilder: (context, index) {
                final rank = listItems[index];

                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          rank.rank.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      rank.dayNameId,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${rank.piketCount} piket terverifikasi'),
                    trailing: Text(
                      '${rank.averageScore.toStringAsFixed(1)} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        fontSize: 16,
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

  Widget _buildGlobalRankingTab(CleanRankViewModel viewModel, String? currentUserClass) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _globalTabController,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryGreen,
            tabs: const [
              Tab(text: 'Harian'),
              Tab(text: 'Mingguan'),
              Tab(text: 'Bulanan'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _globalTabController,
            children: [
              _buildRankingList(viewModel, viewModel.dailyRankings, currentUserClass),
              _buildRankingList(viewModel, viewModel.weeklyRankings, currentUserClass),
              _buildRankingList(viewModel, viewModel.monthlyRankings, currentUserClass),
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
      create: (context) => CleanRankViewModel(),
      child: Consumer<CleanRankViewModel>(
        builder: (context, viewModel, child) {
          _viewModel = viewModel;

          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _mainTabController,
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryGreen,
                  tabs: const [
                    Tab(text: 'Peringkat Kelas'),
                    Tab(text: 'Peringkat Global'),
                  ],
                ),
              ),
            ),
            body: viewModel.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(viewModel.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchRankings,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _mainTabController,
                    children: [
                      _buildClassRankingList(viewModel, viewModel.classRankings),
                      _buildGlobalRankingTab(viewModel, currentUserClass),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

