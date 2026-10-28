import 'package:b2win/constants/api_config.dart';
import 'package:b2win/data/models/blog_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BlogDetailsScreen extends StatelessWidget {
  final BlogModel? blog;

  const BlogDetailsScreen({super.key, this.blog});

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final BlogModel activeBlog = blog ?? (Get.arguments as BlogModel);
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
              children: [
                Text(
                  _formatDate(activeBlog.date),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              activeBlog.description,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
