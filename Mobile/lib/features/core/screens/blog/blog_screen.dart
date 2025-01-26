import 'package:b2win/constants/api_config.dart';
import 'package:b2win/features/core/controllers/blog_controller.dart';
import 'package:b2win/features/core/screens/blog/blog_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(context) {
    final BlogController blogController = Get.put(BlogController());
    final format = DateFormat('dd-mm-');
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
            SizedBox(height: 20),
            Text(
              "Hey, Vally",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Trending Blog",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Blog List Section
            Expanded(
              child: Obx(() {
                if (blogController.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: blogController.blogs.length,
                  itemBuilder: (context, index) {
                    var blog = blogController.blogs[index];
                    return BlogCard(
                      title: blog['title'],
                      description: blog['description'],
                      date: format
                          .parse(blog['date'])
                          .toString()
                          .substring(0, 10),
                      //likes: blog['likes'],
                      photo: '$imageUrl/${blog['photo']}',
                      onTap: () {
                        Get.to(() => BlogDetailsScreen(blog: blog));
                      },
                    );
                  },
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
  // final int likes;
  final VoidCallback onTap;

  const BlogCard({
    super.key,
    required this.title,
    required this.date,
    // required this.likes,
    required this.description,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Color(0xFF292938),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                photo,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
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
