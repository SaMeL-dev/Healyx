// 병원 관련 상수 및 더미 데이터 관리 파일
// 🔧 병원 데이터 관리 (임시 더미 데이터)
// API 연동할 때: 이 파일의 데이터만 교체하면 모든 화면에 반영됨

// [병원 검색 결과] 리스트용 더미 데이터
const List<Map<String, dynamic>> HOSPITAL_LIST = [
  {
    'hospitalName': '서울병원',
    'address': '서울특별시 송파구 올림픽로 43길 88',
    'rating': 4.8,
    'hasBadge': true,
    'hasReview': true,
  },
  {
    'hospitalName': '@@병원',
    'address': '서울특별시 송파구 올림픽로 43길 88',
    'rating': 0.0,
    'hasBadge': false,
    'hasReview': false,
  },
  {
    'hospitalName': '00병원',
    'address': '서울특별시 송파구 올림픽로 43길 88',
    'rating': 4.8,
    'hasBadge': true,
    'hasReview': true,
  },
];

// [리뷰 검색 결과] 리스트용 더미 데이터
const List<Map<String, dynamic>> REVIEW_SEARCH_HOSPITALS = [
  {
    'hospitalName': '서울병원',
    'address': '서울특별시 송파구 올림픽로 43길 88',
    'rating': 3.5,
    'hasBadge': true,
    'hasReview': true,
  },
  {
    'hospitalName': '동서울병원',
    'address': '서울특별시 송파구 올림픽로 43길 88',
    'rating': 3.5,
    'hasBadge': false,
    'hasReview': true,
  },
  {
    'hospitalName': '서울병원',
    'address': '서울특별시 송파구 올림픽로 43길 88',
    'rating': 0.0,
    'hasBadge': true,
    'hasReview': false,
  },
  {
    'hospitalName': '00병원',
    'address': '서울특별시 송파구 올림픽로 43길 88',
    'rating': 3.5,
    'hasBadge': true,
    'hasReview': true,
  },
  {
    'hospitalName': '00병원',
    'address': '서울특별시 송파구 올림픽로 43길 88',
    'rating': 3.5,
    'hasBadge': false,
    'hasReview': true,
  },
];
