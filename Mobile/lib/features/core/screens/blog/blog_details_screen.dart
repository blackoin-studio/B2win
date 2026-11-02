import 'package:b2win/common_widgets/ads/dynamic_banner_ad_widget.dart';
import 'package:b2win/constants/api_config.dart';
import 'package:b2win/core/network/api_client.dart';
import 'package:b2win/data/models/blog_model.dart';
import 'package:b2win/data/providers/ai_provider.dart';
import 'package:b2win/data/repositories/ai_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BlogDetailsScreen extends StatefulWidget {
  final BlogModel? blog;

  const BlogDetailsScreen({super.key, this.blog});

  @override
  State<BlogDetailsScreen> createState() => _BlogDetailsScreenState();
}

class _BlogDetailsScreenState extends State<BlogDetailsScreen> {
  bool _showSummary = false;
  Future<AiBlogSummaryResult>? _summaryFuture;

  AiRepository _resolveAiRepo() {
    if (Get.isRegistered<AiRepository>()) {
      return Get.find<AiRepository>();
    }
    return AiRepository(provider: AiProvider(apiClient: ApiClient()));
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    }
  }

  void _toggleAiSummary(BlogModel activeBlog) {
    setState(() {
      _showSummary = !_showSummary;
      if (_showSummary && _summaryFuture == null) {
        _summaryFuture = _resolveAiRepo().getBlogSummary(
          title: activeBlog.title,
          description: activeBlog.description,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final BlogModel activeBlog = widget.blog ?? (Get.arguments as BlogModel);
    final String coverUrl = resolveMediaUrl(activeBlog.photo);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _toggleAiSummary(activeBlog),
            icon: const Icon(
              Icons.auto_awesome,
              color: Colors.amberAccent,
              size: 18,
            ),
            label: Text(
              _showSummary ? 'Hide AI Summary' : 'AI Summary',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  coverUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: const Color(0xFF292938),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              activeBlog.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(activeBlog.date),
                  style: const TextStyle(color: Colors.grey),
                ),
                InkWell(
                  onTap: () => _toggleAiSummary(activeBlog),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Colors.amberAccent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '30s AI Brief',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showSummary && _summaryFuture != null) ...[
              const SizedBox(height: 16),
              FutureBuilder<AiBlogSummaryResult>(
                future: _summaryFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF292938),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.amberAccent,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Generating 30-second AI summary...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }
                  final summary = snapshot.data!;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF292938),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.amberAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI Executive Summary',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...summary.bullets.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              '• $b',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                        if (summary.keyTakeaway.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            summary.keyTakeaway,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            Text(
              activeBlog.description,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            const DynamicBannerAdWidget(placement: 'blog'),
          ],
        ),
      ),
    );
  }
}
