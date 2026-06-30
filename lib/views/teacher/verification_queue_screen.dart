import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../viewmodels/teacher/verification_queue_viewmodel.dart';
import 'verify_details_screen.dart';

class VerificationQueueScreen extends StatelessWidget {
  const VerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;

    return ChangeNotifierProvider<VerificationQueueViewModel>(
      create: (context) {
        final vm = VerificationQueueViewModel();
        if (token != null) {
          vm.fetchQueue(token);
        }
        return vm;
      },
      child: Scaffold(
        body: Consumer<VerificationQueueViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.pendingSubmissions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (token != null) {
                  await viewModel.fetchQueue(token);
                }
              },
              child: viewModel.error != null
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
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
                                    if (token != null) viewModel.fetchQueue(token);
                                  },
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Queue Header Count Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.pending_actions_rounded, color: AppTheme.primaryGreen),
                                  SizedBox(width: 8),
                                  Text(
                                    'Antrean Validasi',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${viewModel.pendingSubmissions.length} Kelas',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: viewModel.pendingSubmissions.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                    const Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.playlist_add_check_circle_rounded, size: 64, color: AppTheme.success),
                                          SizedBox(height: 16),
                                          Text(
                                            'Semua bersih!',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Tidak ada pengiriman piket yang menunggu validasi.',
                                            style: TextStyle(color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: viewModel.pendingSubmissions.length,
                                  itemBuilder: (context, index) {
                                    final sub = viewModel.pendingSubmissions[index];

                                    return Card(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                        onTap: () async {
                                          final verified = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VerifyDetailsScreen(submission: sub),
                                            ),
                                          );
                                          if (verified == true) {
                                            if (token != null) {
                                              viewModel.fetchQueue(token);
                                            }
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              // Image thumbnail
                                              if (sub.photoUrls.isNotEmpty) ...[
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                                  child: Image.network(
                                                    sub.photoUrls[0].startsWith('http') 
                                                        ? sub.photoUrls[0] 
                                                        : '${AppConfig.baseUrl}/storage/${sub.photoUrls[0]}',
                                                    headers: token != null ? {'Authorization': 'Bearer $token'} : null,
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 70,
                                                        height: 70,
                                                        color: Colors.grey.shade200,
                                                        child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                              ],

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Kelas ${sub.className ?? "-"}',
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.orange.shade50,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'AI: ${sub.aiScore ?? "-"}',
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      sub.date,
                                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Dikirim oleh: ${sub.submittedBy ?? "Siswa"}',
                                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                                    ),
                                                    if (sub.findings.isNotEmpty) ...[
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Temuan: ${sub.findings.join(", ")}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
                                                      ),
                                                    ],
                                                  ],
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
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
