import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../core/models/submission_model.dart';
import '../../core/config/app_config.dart';

class ClassMonitorScreen extends StatefulWidget {
  const ClassMonitorScreen({super.key});

  @override
  State<ClassMonitorScreen> createState() => _ClassMonitorScreenState();
}

class _ClassMonitorScreenState extends State<ClassMonitorScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  String? _error;

  String? _className;
  int _totalSubmissions = 0;
  int _averageScore = 0;
  List<PiketSubmission> _classSubmissions = [];

  @override
  void initState() {
    super.initState();
    _fetchMonitorData();
  }

  Future<void> _fetchMonitorData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final token = auth.token;
      if (token == null) return;

      final data = await _apiService.getClassMonitor(token);
      
      _className = data['class_name']?.toString() ?? 'Kelas';
      final summary = data['performance_summary'];
      if (summary != null) {
        _totalSubmissions = summary['total_submissions'] is int 
            ? summary['total_submissions'] 
            : int.tryParse(summary['total_submissions'].toString()) ?? 0;
        _averageScore = summary['average_score'] is int 
            ? summary['average_score'] 
            : (summary['average_score'] as num?)?.toInt() ?? 0;
      }

      final rawSubs = data['submissions'] as List<dynamic>?;
      if (rawSubs != null) {
        _classSubmissions = rawSubs
            .map((item) => PiketSubmission.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _classSubmissions = [];
      }

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

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Statistik Kelas $_className',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _averageScore.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rata-rata Skor',
                        style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade200),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _totalSubmissions.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Total Pengiriman',
                        style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _classSubmissions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchMonitorData,
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
                          onPressed: _fetchMonitorData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    'Riwayat Kebersihan Kelas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                ),
                _classSubmissions.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'Belum ada riwayat pengiriman piket.',
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _classSubmissions.length,
                        itemBuilder: (context, index) {
                          final sub = _classSubmissions[index];
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
                                      Text(
                                        sub.date,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      _buildStatusBadge(sub.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Dikirim oleh: ${sub.submittedBy ?? "Siswa"}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 12),

                                  // Photos gallery row
                                  if (sub.photoUrls.isNotEmpty) ...[
                                    SizedBox(
                                      height: 60,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: sub.photoUrls.length,
                                        itemBuilder: (context, pIndex) {
                                          final path = sub.photoUrls[pIndex];
                                          final imageUrl = path.startsWith('http') 
                                              ? path 
                                              : '${AppConfig.baseUrl}/storage/$path';

                                          return Padding(
                                            padding: const EdgeInsets.only(right: 6.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                              child: Image.network(
                                                imageUrl,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 60,
                                                    height: 60,
                                                    color: Colors.grey.shade200,
                                                    child: const Icon(Icons.broken_image_rounded, size: 16, color: Colors.grey),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'AI Score: ${sub.aiScore ?? "-"}',
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                      Row(
                                        children: [
                                          const Text(
                                            'Skor Akhir: ',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            sub.isPending ? 'Menunggu' : displayScore.toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: sub.isPending 
                                                  ? Colors.orange 
                                                  : (displayScore >= 75 ? AppTheme.success : AppTheme.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  if (sub.notes != null && sub.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Catatan: ${sub.notes}',
                                        style: const TextStyle(fontSize: 11, color: Colors.black87, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                          },
                        ),
              ],
            ),
    );
  }
}
