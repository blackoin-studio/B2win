import 'package:b2win/core/network/api_client.dart';
import 'package:b2win/data/providers/ai_provider.dart';
import 'package:b2win/data/repositories/ai_repository.dart';
import 'package:b2win/features/core/controllers/navbar_controller.dart';
import 'package:b2win/features/core/controllers/prediction_controller.dart';
import 'package:b2win/features/core/screens/blog/blog_screen.dart';
import 'package:b2win/features/core/screens/home/home_card.dart';
import 'package:b2win/features/core/screens/home/navbar.dart';
import 'package:b2win/features/core/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAiTipsterChat(BuildContext context) {
    final AiRepository aiRepo = Get.isRegistered<AiRepository>()
        ? Get.find<AiRepository>()
        : AiRepository(provider: AiProvider(apiClient: ApiClient()));

    final TextEditingController inputController = TextEditingController();
    final RxList<Map<String, String>> messages = <Map<String, String>>[
      {
        'sender': 'ai',
        'text':
            'Hi! I\'m your B2win AI Tipster. Ask me for today\'s safest picks, accumulator ideas, or insight on any match!',
      },
    ].obs;
    final RxBool isSending = false.obs;

    Future<void> sendMessage(String text) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty || isSending.value) return;
      inputController.clear();
      messages.add({'sender': 'user', 'text': trimmed});
      isSending.value = true;

      final games = Get.isRegistered<GameController>()
          ? Get.find<GameController>().games.toList()
          : const <dynamic>[];

      final reply = await aiRepo.askAiTipster(
        message: trimmed,
        availableGames: games.cast(),
      );
      messages.add({'sender': 'ai', 'text': reply});
      isSending.value = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.amberAccent,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ask B2win AI Tipster',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final prompt in const [
                        'Safest picks today?',
                        'Build a 3-match slip',
                        'Top confidence match?',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            backgroundColor: const Color(0xFF292938),
                            label: Text(
                              prompt,
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () => sendMessage(prompt),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Obx(
                    () => ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isUser = msg['sender'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.78,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.orange
                                  : const Color(0xFF292938),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inputController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: sendMessage,
                          decoration: InputDecoration(
                            hintText: 'Ask about today\'s matches or tips...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF292938),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: isSending.value
                            ? null
                            : () => sendMessage(inputController.text),
                        icon: isSending.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.amberAccent,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.amberAccent,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final NavbarController controller = Get.find<NavbarController>();
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome back!"),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () => _openAiTipsterChat(context),
              icon: const Icon(
                Icons.auto_awesome,
                color: Colors.amberAccent,
                size: 18,
              ),
              label: const Text(
                "Ask AI",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(
        () => controller.currentIndex.value == 0
            ? const MatchCard()
            : controller.currentIndex.value == 1
                ? const BlogScreen()
                : const ProfileScreen(),
      ),
      bottomNavigationBar: Navbar(
        isDark: isDark,
      ),
    );
  }
}
