// 커뮤니티 게시글 상세 화면
// 게시글 제목, 작성자 닉네임, 작성 날짜, 본문 내용, 좋아요 수, 댓글 수 등이 표시됨
// 게시글이 본인 글인지 여부에 따라 메뉴 버튼에서 수정/삭제 또는 신고/원문보기 옵션이 다르게 보임
import 'package:flutter/material.dart';

import '../../dialogs/report_dialog.dart';
import '../../dialogs/delete_confirm_dialog.dart';
import '../../dialogs/comment_delete_dialog.dart';
import 'community_write.dart';

class CommunityDetailScreen extends StatelessWidget {
  final bool isMyPost;

  const CommunityDetailScreen({
    super.key,
    this.isMyPost = false, //true로 하면 내 글, false로 하면 다른 사람 글 화면 보여줌 (메뉴 버튼 다르게 보이도록)
  });

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFEFF2FF);
  static const Color commentBg = Color(0xFFE2E9FF);

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.only(left: 18),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: mainBlue,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const Text(
                  '커뮤니티',
                  style: TextStyle(
                    color: mainBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '서울에 24시간 하는 병원 있나요?',
                                  style: TextStyle(
                                    color: mainBlue,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),

                              // 메뉴 버튼
                              PopupMenuButton<String>(
                                color: Colors.white,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: mainBlue,
                                ),
                                onSelected: (value) {
                                  // 신고하기
                                  if (value == 'report') {
                                    showDialog(
                                      context: context,
                                      barrierColor: mainBlue.withOpacity(0.5),
                                      builder: (_) => const ReportDialog(),
                                    );
                                  }

                                  // 삭제하기
                                  else if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      barrierColor: mainBlue.withOpacity(0.5),
                                      builder: (_) =>
                                          const DeleteConfirmDialog(),
                                    );
                                  }

                                  // 수정하기
                                  else if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CommunityWriteScreen(),
                                      ),
                                    );
                                  } else if (value == 'view') {
                                    // TODO: 원문보기
                                  }
                                },
                                itemBuilder: (context) {
                                  if (isMyPost) {
                                    return const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('수정하기'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('삭제하기'),
                                      ),
                                    ];
                                  } else {
                                    return const [
                                      PopupMenuItem(
                                        value: 'report',
                                        child: Text('신고하기'),
                                      ),
                                      PopupMenuItem(
                                        value: 'view',
                                        child: Text('원문보기'),
                                      ),
                                    ];
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          const Row(
                            children: [
                              Text(
                                '닉네임 000',
                                style: TextStyle(
                                  color: mainBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              Text(
                                '2026. 04. 18',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Container(height: 1, color: mainBlue),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    const Text(
                      '본문',
                      style: TextStyle(
                        color: mainBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 60),

                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text('10'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.bookmark_border, color: mainBlue),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(height: 1, color: mainBlue),
                    ),

                    const SizedBox(height: 20),

                    // 🔥 댓글 영역
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: commentBg,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 댓글 개수 표시
                          Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 14),
                            child: Text(
                              '댓글 2 >',
                              style: TextStyle(
                                color: mainBlue,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          // 댓글 리스트
                          _CommentCard(
                            nickname: '닉네임123',
                            content: '와 그러게요! 너무 궁금해요!\n저희 지역에는 많이 없어요 ㅠㅠ',
                            date: '2026. 04. 18',
                            isMyComment: false,
                          ),
                          SizedBox(height: 14),
                          _CommentCard(
                            nickname: '닉네임 555',
                            content: '서울 병원 있어요!',
                            date: '2026. 04. 18',
                            isMyComment: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ── 댓글 카드 ─────────────────────────────────
class _CommentCard extends StatelessWidget {
  final String nickname;
  final String content;
  final String date;
  final bool isMyComment; // true면 삭제 버튼, false면 답글 쓰기 버튼
  
  //isMyComment: false → 삭제 버튼 없음 → 근데 답글 쓰기 버튼은 항상 보임
  //isMyComment: true → 삭제 버튼 있음 → 답글 쓰기 버튼도 같이 보임

  const _CommentCard({
    required this.nickname,
    required this.content,
    required this.date,
    required this.isMyComment,
  });

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 5,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 닉네임 + 삭제 버튼 (본인 댓글일 때)
          Row(
            children: [
              Text(
                nickname,
                style: const TextStyle(
                  color: mainBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (isMyComment)
                GestureDetector(
                  onTap: () {
                    // 댓글 삭제 다이얼로그
                    showDialog(
                      context: context,
                      barrierColor: mainBlue.withOpacity(0.5),
                      builder: (_) => const CommentDeleteDialog(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '삭제',
                      style: TextStyle(
                        color: mainBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          Text(content),

          const SizedBox(height: 10),

          // 대댓글 목록 (하드코딩 더미)
          const _ReplyCard(
            targetNickname: '닉네임123',
            nickname: '닉네임 555',
            content: '서울 병원 있어요!',
            date: '2026. 04. 18',
            isMyReply: true,
          ),

          const SizedBox(height: 10),

          // 날짜 + 답글 쓰기 버튼
          Row(
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: mainBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '답글 쓰기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 대댓글 카드 ───────────────────────────────
class _ReplyCard extends StatelessWidget {
  final String targetNickname; // @ 멘션 대상
  final String nickname; // 대댓글 작성자
  final String content;
  final String date;
  final bool isMyReply; // true면 삭제 버튼

  const _ReplyCard({
    required this.targetNickname,
    required this.nickname,
    required this.content,
    required this.date,
    required this.isMyReply,
  });

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color softBg = Color(0xFFECF1FF);
  static const Color replyBg = Color(0xFFF3F5FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: replyBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // @ 멘션 + 삭제 버튼
          Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '@ ',
                      style: TextStyle(
                        color: mainBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: targetNickname,
                      style: const TextStyle(
                        color: mainBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isMyReply)
                GestureDetector(
                  onTap: () {
                    // 대댓글 삭제 다이얼로그
                    showDialog(
                      context: context,
                      barrierColor: mainBlue.withOpacity(0.5),
                      builder: (_) => const CommentDeleteDialog(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '삭제',
                      style: TextStyle(
                        color: mainBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // 작성자 + 내용
          Text(
            '$nickname  $content',
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),

          const SizedBox(height: 6),

          // 날짜
          Text(
            date,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
