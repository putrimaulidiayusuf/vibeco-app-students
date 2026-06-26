import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/submission_model.dart';
import '../../core/config/app_config.dart';
import '../../viewmodels/teacher/verify_details_viewmodel.dart';

class VerifyDetailsScreen extends StatefulWidget {
  final PiketSubmission submission;
  const VerifyDetailsScreen({super.key, required this.submission});

  @override
  State<VerifyDetailsScreen> createState() => _VerifyDetailsScreenState();
}

class _VerifyDetailsScreenState extends State<VerifyDetailsScreen> {
  final _notesController = TextEditingController();
  final _scoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default the adjust score to the AI score
    _scoreController.text = (widget.submission.aiScore ?? 80).toString();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify(VerifyDetailsViewModel viewModel) async {
    final notes = _notesController.text.trim();
    int? score;

    // Validation
    if (viewModel.selectedAction == 'adjusted') {
      final parsedScore = int.tryParse(_scoreController.text);
      if (parsedScore == null || parsedScore < 0 || parsedScore > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skor penyesuaian harus berupa angka antara 0 - 100.'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
      score = parsedScore;

      if (notes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan penyesuaian wajib diisi.'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
    }

    if (viewModel.selectedAction == 'rejected' && notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan penolakan wajib diisi.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Validasi'),
        content: Text(
          'Apakah Anda yakin ingin memproses validasi ini sebagai '
          '${viewModel.selectedAction == "approved" ? "DISETUJUI" : viewModel.selectedAction == "adjusted" ? "DISESUAIKAN" : "DITOLAK"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Proses'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final success = await viewModel.verifySubmission(
      token: token,
      submissionId: widget.submission.id,
      status: viewModel.selectedAction,
      score: viewModel.selectedAction == 'adjusted' ? score : null,
      notes: notes.isNotEmpty ? notes : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasil validasi berhasil dikirim!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true); // Return true to refresh queue
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.submission;
    // Safe findings join with null-check
    final findingsStr = sub.findings.isNotEmpty ? sub.findings.join(', ') : 'Tidak ada temuan';

    return ChangeNotifierProvider<VerifyDetailsViewModel>(
      create: (context) => VerifyDetailsViewModel(),
      child: Consumer<VerifyDetailsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Validasi Kelas ${sub.className ?? "-"}'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sub.date,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'Oleh: ${sub.submittedBy ?? "Siswa"}',
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Photo Gallery Viewer
                  if (sub.photoUrls.isNotEmpty) ...[
                    const Text(
                      'Foto Kebersihan Kelas:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sub.photoUrls.length,
                        itemBuilder: (context, index) {
                          final path = sub.photoUrls[index];
                          final imageUrl = path.startsWith('http') 
                              ? path 
                              : '${AppConfig.baseUrl}/storage/$path';

                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                              child: GestureDetector(
                                onTap: () {
                                  // Open fullscreen image preview
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: InteractiveViewer(
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              padding: const EdgeInsets.all(24),
                                              child: const Icon(Icons.broken_image_rounded, size: 64),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Image.network(
                                  imageUrl,
                                  width: 280,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 280,
                                      height: 200,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // AI Assessment Card
                  Card(
                    color: AppTheme.surfaceGreen,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (sub.aiScore ?? 0).toString(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Penilaian AI (AI Score)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Temuan: $findingsStr',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Validation Actions
                  const Text(
                    'Tindakan Guru PLH (Responsible AI):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: viewModel.selectedAction == 'approved' 
                                ? AppTheme.success.withValues(alpha: 0.1) 
                                : Colors.transparent,
                            side: BorderSide(
                              color: viewModel.selectedAction == 'approved' ? AppTheme.success : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          onPressed: () {
                            viewModel.setSelectedAction('approved');
                          },
                          child: Text(
                            'Setujui AI',
                            style: TextStyle(
                              color: viewModel.selectedAction == 'approved' ? AppTheme.success : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: viewModel.selectedAction == 'adjusted' 
                                ? Colors.orange.shade50 
                                : Colors.transparent,
                            side: BorderSide(
                              color: viewModel.selectedAction == 'adjusted' ? Colors.orange : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          onPressed: () {
                            viewModel.setSelectedAction('adjusted');
                          },
                          child: Text(
                            'Sesuaikan',
                            style: TextStyle(
                              color: viewModel.selectedAction == 'adjusted' ? Colors.orange : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: viewModel.selectedAction == 'rejected' 
                                ? AppTheme.error.withValues(alpha: 0.1) 
                                : Colors.transparent,
                            side: BorderSide(
                              color: viewModel.selectedAction == 'rejected' ? AppTheme.error : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          onPressed: () {
                            viewModel.setSelectedAction('rejected');
                          },
                          child: Text(
                            'Tolak',
                            style: TextStyle(
                              color: viewModel.selectedAction == 'rejected' ? AppTheme.error : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Form inputs depending on selected action
                  if (viewModel.selectedAction == 'adjusted') ...[
                    TextFormField(
                      controller: _scoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Skor Penyesuaian Baru (0-100)',
                        prefixIcon: Icon(Icons.stars_rounded, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: viewModel.selectedAction == 'approved' 
                          ? 'Catatan Validasi (Opsional)' 
                          : 'Catatan/Alasan Perubahan (Wajib)',
                      prefixIcon: const Icon(Icons.rate_review_rounded, color: AppTheme.primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  viewModel.isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () => _handleVerify(viewModel),
                          child: const Text('KIRIM VALIDASI'),
                        ),

                  if (viewModel.error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              viewModel.error!,
                              style: const TextStyle(color: AppTheme.error, fontSize: 13),
                            ),
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
  }
}
