import 'package:b2win/common_widgets/loaders/blog_card_shimmer.dart';
import 'package:b2win/common_widgets/loaders/empty_state_widget.dart';
import 'package:b2win/constants/api_config.dart';
import 'package:b2win/data/models/blog_model.dart';
import 'package:b2win/features/core/controllers/blog_controller.dart';
import 'package:b2win/features/core/controllers/profile_controller.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (_) {
      return rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final BlogController blogController = Get.find<BlogController>();
    final ProfileController profileController = Get.find<ProfileController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/avatar.png'),
                ),
                Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() {
              final username =
                  profileController.currentUser.value?.username ?? 'Sports Fan';
              return Text(
                "Hey, $username",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
            const SizedBox(height: 10),
            const Text(
              "Trending Blog",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Blog List Section
            Expanded(
              child: Obx(() {
                if (blogController.isLoading.value) {
                  return const BlogCardShimmer();
                }

                if (blogController.blogs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => blogController.fetchBlogData(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 60),
                        EmptyStateWidget(
                          icon: Icons.article_outlined,
                          title: 'No Blogs Available',
                          subtitle:
                              'Stay tuned! New match analysis and sports articles will appear here.',
                          actionButtonText: 'Refresh',
                          onRetry: () => blogController.fetchBlogData(),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => blogController.fetchBlogData(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: blogController.blogs.length,
                    itemBuilder: (context, index) {
                      final BlogModel blog = blogController.blogs[index];
                      return BlogCard(
                        title: blog.title,
                        description: blog.description,
                        date: _formatDate(blog.date),
                        photo: resolveMediaUrl(blog.photo),
                        onTap: () {
                          Get.toNamed(AppRoutes.blogDetails, arguments: blog);
                        },
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class BlogCard extends StatelessWidget {
  final String title, description, date, photo;
  final VoidCallback onTap;

  const BlogCard({
    super.key,
    required this.title,
    required this.date,
    required this.description,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF292938),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  photo,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: const Color(0xFF1E1E2C),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        date,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
