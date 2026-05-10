// 커뮤니티 알림창 화면 (알림창 아이콘은 메인화면에 있음!)
// 좋아요, 댓글, 대댓글 알림이 리스트 형태로 보여지는 화면
import 'package:flutter/material.dart';
import '../app_language.dart'; 

class CommunityNotificationScreen extends StatelessWidget {
  const CommunityNotificationScreen({super.key});

  static const Color mainBlue  = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFE2EAFF);
  static const Color midBlue   = Color(0xFF6281E3);

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'type': 'like',
        'title': '닉네임 555님이 좋아를 눌렀습니다.',
        'content': '\'닉네임000\' 서울 24시간 하는 병원 있을까요?',
        'time': '방금 전',
      },
      {
        'type': 'like',
        'title': '닉네임 555님이 좋아를 눌렀습니다.',
        'content': '\'닉네임000\' 서울 24시간 하는 병원 있을까요?',
        'time': '1분',
      },
      {
        'type': 'comment',
        'title': '닉네임 555님이 댓글을 달았습니다.',
        'content': '\'@닉네임000\' 서울 24시간 하는 병원 있을까요?',
        'time': '5분',
      },
      {
        'type': 'like',
        'title': '닉네임 555님이 좋아를 눌렀습니다.',
        'content': '\'닉네임000\' 서울 24시간 하는 병원 있을까요?',
        'time': '10분',
      },
      {
        'type': 'comment',
        'title': '닉네임 555님이 댓글을 달았습니다.',
        'content': '\'@닉네임000\' 서울 24시간 하는 병원 있을까요?',
        'time': '15분',
      },
      {
        'type': 'comment',
        'title': '닉네임 555님이 대댓글을 달았습니다.',
        'content': '\'@닉네임000\' 서울 24시간 하는 병원 있을까요?',
        'time': '1시간',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            // 앱바
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: mainBlue, size: 22),
                    ),
                  ),
                ),
                Text(
                  AppLanguage.t('community_notification_title'), // '알림창'
                  style: const TextStyle(
                    color: mainBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
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

  static const Color mainBlue  = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFE2EAFF);

  @override
  Widget build(BuildContext context) {
    final bool isLike = type == 'like';

    // 닉네임 부분(따옴표 포함)과 나머지 분리
    final parts = content.split('\' ');
    final String boldPart  = parts.isNotEmpty ? '${parts[0]}\'' : content;
    final String plainPart = parts.length > 1 ? ' ${parts[1]}' : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLike ? Icons.favorite : Icons.chat_bubble_rounded,
              color: mainBlue,
              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타이틀
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mainBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                // 내용 (닉네임 bold + 나머지)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: boldPart,
                        style: const TextStyle(
                          color: mainBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: plainPart,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // 시간
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
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