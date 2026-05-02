import 'package:flutter/material.dart';

class CommunityNotificationScreen extends StatelessWidget {
  const CommunityNotificationScreen({super.key});

  static const Color mainBlue = Color(0xFF2260FF);

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'type': 'like',
        'title': '닉네임 555님이 좋아를 눌렀습니다.',
        'content': '‘닉네임000’ 서울 24시간 하는 병원 있을까요?',
        'time': '방금 전',
      },
      {
        'type': 'like',
        'title': '닉네임 555님이 좋아를 눌렀습니다.',
        'content': '‘닉네임000’ 서울 24시간 하는 병원 있을까요?',
        'time': '1분',
      },
      {
        'type': 'comment',
        'title': '닉네임 555님이 댓글을 달았습니다.',
        'content': '‘@닉네임000’ 서울 24시간 하는 병원 있을까요?',
        'time': '5분',
      },
      {
        'type': 'like',
        'title': '닉네임 555님이 좋아를 눌렀습니다.',
        'content': '‘닉네임000’ 서울 24시간 하는 병원 있을까요?',
        'time': '10분',
      },
      {
        'type': 'comment',
        'title': '닉네임 555님이 댓글을 달았습니다.',
        'content': '‘@닉네임000’ 서울 24시간 하는 병원 있을까요?',
        'time': '15분',
      },
      {
        'type': 'comment',
        'title': '닉네임 555님이 대댓글을 달았습니다.',
        'content': '‘@닉네임000’ 서울 24시간 하는 병원 있을까요?',
        'time': '1시간',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: mainBlue,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const Text(
                  '알림창',
                  style: TextStyle(
                    color: mainBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 34),

            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  final item = notifications[index];

                  return _NotificationCard(
                    type: item['type']!,
                    title: item['title']!,
                    content: item['content']!,
                    time: item['time']!,
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

class _NotificationCard extends StatelessWidget {
  final String type;
  final String title;
  final String content;
  final String time;

  const _NotificationCard({
    required this.type,
    required this.title,
    required this.content,
    required this.time,
  });

  static const Color mainBlue = Color(0xFF2260FF);

  @override
  Widget build(BuildContext context) {
    final bool isLike = type == 'like';

    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isLike ? Icons.favorite : Icons.chat_bubble,
            color: mainBlue,
            size: 28,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mainBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: content.split(' ').first,
                        style: const TextStyle(
                          color: mainBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: content.replaceFirst(content.split(' ').first, ''),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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