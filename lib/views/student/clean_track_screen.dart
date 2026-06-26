import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../viewmodels/student/clean_track_viewmodel.dart';

class CleanTrackScreen extends StatefulWidget {
  const CleanTrackScreen({super.key});

  @override
  State<CleanTrackScreen> createState() => _CleanTrackScreenState();
}

class _CleanTrackScreenState extends State<CleanTrackScreen> {
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = AppTheme.success;
        text = 'Disetujui';
        break;
      case 'adjusted':
        color = AppTheme.primaryLight;
        text = 'Disesuaikan';
        break;
      case 'rejected':
        color = AppTheme.error;
        text = 'Ditolak';
        break;
      default:
        color = AppTheme.warning;
        text = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;

    return ChangeNotifierProvider<CleanTrackViewModel>(
      create: (context) {
        final vm = CleanTrackViewModel();
        if (token != null) {
          vm.fetchHistory(token);
        }
        return vm;
      },
      child: Consumer<CleanTrackViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.submissions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (token != null) {
                await viewModel.fetchHistory(token);
              }
            },
            child: viewModel.error != null
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                              const SizedBox(height: 12),
                              Text(viewModel.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (token != null) viewModel.fetchHistory(token);
                                },
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : viewModel.submissions.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Belum ada riwayat piket.',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Lakukan piket kelas hari ini dan unggah fotonya!',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: viewModel.submissions.length,
                        itemBuilder: (context, index) {
                          final sub = viewModel.submissions[index];
                          final displayScore = sub.displayScore;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.date,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          if (sub.submittedBy != null)
                                            Text(
                                              'Oleh: ${sub.submittedBy}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                      _buildStatusBadge(sub.status),
                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // Photo preview gallery row
                                  if (sub.photoUrls.isNotEmpty) ...[
                                    SizedBox(
                                      height: 80,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: sub.photoUrls.length,
                                        itemBuilder: (context, pIndex) {
                                    final path = sub.photoUrls[pIndex];
                                    // Handle relative vs absolute URLs
                                    final imageUrl = path.startsWith('http') 
                                        ? path 
                                        : '${AppConfig.baseUrl}/storage/$path';

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                        child: Image.network(
                                          imageUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Score & findings summary
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Score: ${sub.aiScore ?? "-"}',
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Text(
                                            'Skor Akhir: ',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            sub.isPending ? 'Menunggu Validasi' : displayScore.toString(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: sub.isPending
                                                  ? Colors.orange
                                                  : (displayScore >= 75 ? AppTheme.success : AppTheme.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    displayScore.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (sub.findings.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Temuan AI:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: sub.findings.map((finding) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      finding,
                                      style: const TextStyle(fontSize: 11, color: Colors.orange),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],

                            // Verification details / Notes
                            if (!sub.isPending && sub.notes != null && sub.notes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.rate_review_rounded, size: 16, color: AppTheme.primaryGreen),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Catatan Validasi (${sub.verifiedBy ?? "Guru PLH"}):',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryDark),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sub.notes!,
                                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
          );
        },
      ),
    );
  }
}
