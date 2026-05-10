import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
                    color: Color(0xFF4A4A4A),
                  ),

                  Column(
                    children: const [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E2E2E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'your updates & activity',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8FA67A),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Notification List ─────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 8,
                itemBuilder: (context, index) {
                  return _NotificationCard(
                    title: _sampleNotifications[index % _sampleNotifications.length],
                    time: '${index + 1}h ago',
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

// ─── Notification Card ─────────────────────────────

class _NotificationCard extends StatelessWidget {
  final String title;
  final String time;

  const _NotificationCard({
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFF8FA67A),
            child: Icon(Icons.notifications, color: Colors.white, size: 18),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sample Data ─────────────────────────────

final List<String> _sampleNotifications = [
  "New recipe liked by a user",
  "Your twist got a new comment",
  "Someone followed your profile",
  "Recipe approved by admin",
  "Weekly recipe summary is ready",
];