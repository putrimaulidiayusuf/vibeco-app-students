import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../core/models/submission_model.dart';
import '../../core/config/app_config.dart';
import 'verify_details_screen.dart';

class VerificationQueueScreen extends StatefulWidget {
  const VerificationQueueScreen({super.key});

  @override
  State<VerificationQueueScreen> createState() => _VerificationQueueScreenState();
}

class _VerificationQueueScreenState extends State<VerificationQueueScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<PiketSubmission> _pendingSubmissions = [];

  @override
  void initState() {
    super.initState();
    _fetchQueue();
  }

  Future<void> _fetchQueue() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final token = auth.token;
      if (token == null) return;

      final data = await _apiService.getPendingVerifications(token);
      setState(() {
        _pendingSubmissions = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _pendingSubmissions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchQueue,
        child: _error != null
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
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchQueue,
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
                            '${_pendingSubmissions.length} Kelas',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _pendingSubmissions.isEmpty
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
                            itemCount: _pendingSubmissions.length,
                            itemBuilder: (context, index) {
                              final sub = _pendingSubmissions[index];

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
                                      _fetchQueue();
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
      ),
    );
  }
}
