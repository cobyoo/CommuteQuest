# 🎮 CommuteQuest — 출퇴근 RPG

> 매일 출퇴근이 던전 공략. 이동시간 = 경험치, 지하철 노선 = 던전맵.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](./LICENSE)

## 컨셉

출퇴근이 지루한 모든 직장인을 위한 RPG 앱.
**출근하면 경험치**, **정시 도착하면 보스 클리어**, **지각하면 HP 깎임**.
같은 노선 유저끼리 길드를 만들고, 통근 고통을 재미로 바꾸자.

## 핵심 기능

### ⚔️ 던전 & 전투
| 노선 | 던전 등급 | 경험치 배율 |
|------|----------|------------|
| 2호선 | 🔴 지옥 | x2.0 |
| 9호선 급행 | 🟠 하드 | x1.8 |
| 신분당선 | 🟡 노말 | x1.2 |
| 버스 | 🟢 필드 | x1.0 |
| 도보/자전거 | 🔵 보너스 | x1.5 (체력 보너스) |

### 🧙 캐릭터 성장
- **직업 전직:** 인턴 → 사원 → 대리 → 과장 → 임원 → 회장 → 은퇴 전설
- **스탯:** 체력(HP), 인내력(MP), 운(LUCK), 스피드(SPD)
- **스킬:** "환승 대시", "빈자리 감지", "졸음 방어" 등

### 🏆 업적 시스템
- `100일 연속 정시출근` — 전설 칭호 "시간의 지배자"
- `환승 3번 생존자` — 레어 장비 "환승의 운동화"
- `월요일 10회 연속 출근` — 업적 "월요병 면역"
- `폭우 출근 성공` — 칭호 "폭풍전사"

### 👥 길드
- 같은 노선/역 사용자끼리 자동 매칭
- 길드 레이드: 전원 정시출근 시 보스 처치
- 주간 길드 랭킹

### 🎒 장비 시스템
실제 출퇴근 아이템을 게임 장비로:
- 🎧 이어폰 → 방어력 +10 (소음 차단)
- ☕ 텀블러 → HP 회복 +5
- 📱 보조배터리 → MP 회복 +3
- 🧥 패딩 → 겨울 던전 저항력 +20

## 기술 스택

```
┌─────────────────────────────────────────┐
│              Client (Flutter)            │
│   iOS + Android + (Web PWA)             │
├─────────────────────────────────────────┤
│              API (FastAPI)               │
│   인증 · 게임로직 · 랭킹 · 푸시알림      │
├─────────────────────────────────────────┤
│           Database & Infra              │
│   PostgreSQL · Redis · GCP Cloud Run    │
└─────────────────────────────────────────┘
```

| 레이어 | 기술 | 이유 |
|--------|------|------|
| 모바일 | Flutter | iOS/Android 동시 개발 |
| 백엔드 | FastAPI (Python) | 빠른 개발, 비동기 처리 |
| DB | PostgreSQL | 관계형 데이터(유저, 길드, 업적) |
| 캐시 | Redis | 실시간 랭킹, 세션 |
| 인프라 | GCP Cloud Run | 서버리스, 오토스케일링 |
| 위치 | Background GPS | 출발/도착 자동 감지 |
| 푸시 | Firebase Cloud Messaging | 보스전 알림, 길드 레이드 |

## 프로젝트 구조

```
CommuteQuest/
├── app/                    # Flutter 모바일 앱
│   ├── lib/
│   │   ├── models/         # 캐릭터, 던전, 장비 모델
│   │   ├── screens/        # UI 화면
│   │   ├── services/       # API 통신, GPS, 알림
│   │   ├── providers/      # 상태 관리
│   │   └── widgets/        # 공통 위젯
│   └── assets/             # 스프라이트, 사운드
├── backend/                # FastAPI 서버
│   ├── api/                # 엔드포인트
│   ├── core/               # 게임 로직 엔진
│   ├── models/             # DB 모델 (SQLAlchemy)
│   └── services/           # 비즈니스 로직
├── infra/                  # IaC (Terraform)
└── docs/                   # 기획 문서
```

## 수익 모델

| 모델 | 가격 | 내용 |
|------|------|------|
| 기본 (무료) | ₩0 | 캐릭터 1개, 기본 던전, 광고 포함 |
| 프리미엄 구독 | ₩3,900/월 | 광고 제거, 커스텀 스킨, 추가 직업군 |
| 인앱 결제 | ₩1,000~ | 부활권, 경험치 부스터, 레어 장비 상자 |

## 로드맵

- [ ] **v0.1** — MVP: 출퇴근 감지 + 경험치 시스템 + 캐릭터 기본
- [ ] **v0.2** — 던전 시스템 + 노선별 난이도
- [ ] **v0.3** — 업적 + 장비 시스템
- [ ] **v0.4** — 길드 + 소셜 기능
- [ ] **v0.5** — 랭킹 + 리더보드
- [ ] **v1.0** — 앱스토어 출시 🚀

## 시작하기

```bash
# 백엔드
cd backend
pip install -r requirements.txt
uvicorn main:app --reload

# 앱 (Flutter)
cd app
flutter pub get
flutter run
```

## 기여

이 프로젝트에 관심 있으시면 이슈나 PR 환영합니다!

## 라이선스

Copyright (c) 2026 cobyoo. All Rights Reserved.

이 소프트웨어는 독점 라이선스입니다. 무단 복제, 수정, 배포를 금합니다.
라이선스 문의: GitHub Issues 또는 직접 연락

---

**매일 반복되는 출퇴근, 레벨업으로 바꿔보세요.** 🚇⚔️
