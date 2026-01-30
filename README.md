# YouTube Shorts 자동 생성 워크플로우

> **유튜브 영상 URL만 넣으면, AI가 자동으로 새로운 쇼츠 영상을 만들어줍니다!**

![n8n](https://img.shields.io/badge/n8n-workflow-orange)
![AI](https://img.shields.io/badge/AI-Powered-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 이런 분들을 위한 강의입니다

- n8n을 처음 접하시는 분
- 코딩 없이 자동화를 배우고 싶으신 분  
- AI를 활용한 콘텐츠 제작에 관심 있으신 분
- 유튜브 쇼츠 채널을 운영하시는 분

---

## 워크플로우가 하는 일

```
유튜브 URL 입력 → AI가 스크립트 분석 → 새로운 대본 생성 → 
이미지 6장 생성 → 영상 6개 생성 → 음성 생성 → 
최종 영상 조합 → 유튜브 업로드
```

### 실제 비용
- **영상 1개당 약 $2.26** (약 3,000원)
- 완전 자동화로 약 20-30분 소요

---

## 시작하기 전 준비물

### 필수 설치
| 항목 | 설명 | 다운로드 링크 |
|------|------|--------------|
| Docker Desktop | n8n을 실행하기 위한 프로그램 | [Mac](https://docs.docker.com/desktop/setup/install/mac-install/) / [Windows](https://docs.docker.com/desktop/setup/install/windows-install/) |

### 필요한 계정 (무료/유료)
| 서비스 | 용도 | 비고 |
|--------|------|------|
| Google 계정 | Google Sheets, YouTube | 무료 |
| RapidAPI | 유튜브 자막 추출 | 무료 티어 있음 |
| Kie AI | 이미지/영상/음성 생성 | 유료 (종량제) |
| Google AI Studio | AI 대본 생성 | 무료 |

---

## 설치 방법 (5분)

### 방법 1: AI 자동 설치 (추천)

Claude나 ChatGPT에게 `N8N_INSTALL.md` 파일을 주고 설치를 요청하세요:

```
이 문서를 보고 n8n을 설치해주세요.
```

### 방법 2: 수동 설치

**1단계: 폴더 만들기**

Mac 사용자:
```bash
mkdir -p ~/n8n-self
cd ~/n8n-self
```

Windows 사용자 (PowerShell):
```powershell
mkdir C:\n8n-self
cd C:\n8n-self
```

**2단계: 파일 복사하기**

이 저장소의 `Dockerfile`과 `docker-compose.yml` 파일을 위에서 만든 폴더에 복사합니다.

**3단계: 실행하기**

```bash
# 빌드 (처음 1회만, 약 2-3분 소요)
docker compose build --no-cache

# 실행
docker compose up -d
```

**4단계: 접속하기**

브라우저에서 열기: **http://localhost:5678**

처음 접속하면 계정을 만들라고 합니다. 이름, 이메일, 비밀번호를 입력하세요.

---

## 워크플로우 가져오기

1. n8n에 접속합니다 (http://localhost:5678)
2. 왼쪽 메뉴에서 **Workflows** 클릭
3. 오른쪽 위 **Import from URL** 또는 **Import from File** 클릭
4. 이 저장소의 워크플로우 파일을 선택

---

## API 키 설정하기

워크플로우를 실행하려면 각 서비스의 API 키가 필요합니다.

### 1. Google Sheets & YouTube

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 새 프로젝트 생성
3. "API 및 서비스" → "사용자 인증 정보" → "OAuth 클라이언트 ID 만들기"
4. n8n에서 "Credentials" → "New Credential" → "Google Sheets OAuth2" 선택
5. 발급받은 Client ID와 Secret 입력

### 2. RapidAPI (YouTube Transcript)

1. [RapidAPI](https://rapidapi.com/) 가입
2. [youtube-transcriptor](https://rapidapi.com/Suspended-Developers/api/youtube-transcriptor) 구독 (무료 티어)
3. API Key 복사
4. n8n에서 "Header Auth" credential 생성
   - Name: `X-RapidAPI-Key`
   - Value: 복사한 API Key

### 3. Kie AI (이미지/영상/음성)

1. [Kie AI](https://kie.ai/) 가입
2. API Key 발급
3. n8n에서 "Header Auth" credential 생성
   - Name: `X-API-Key`
   - Value: 발급받은 API Key

### 4. Google AI Studio (Gemini)

1. [Google AI Studio](https://makersuite.google.com/app/apikey) 접속
2. API Key 생성
3. n8n에서 "Google AI" credential 생성

---

## 사용 방법

### 1단계: Google Sheets 준비

아래 형식의 스프레드시트를 만드세요:

| ID | YouTube_URL | Status |
|----|-------------|--------|
| 1 | https://youtube.com/watch?v=xxx | pending |
| 2 | https://youtube.com/watch?v=yyy | pending |

### 2단계: 워크플로우 실행

1. n8n에서 워크플로우 열기
2. "Test Workflow" 버튼 클릭
3. 완료될 때까지 기다리기 (약 20-30분)

### 3단계: 결과 확인

- Google Sheets에서 Status가 "completed"로 변경됨
- YouTube에 비공개 영상으로 업로드됨

---

## 폴더 구조

```
n8n_auto_short/
├── README.md              ← 지금 보고 있는 파일
├── N8N_INSTALL.md         ← n8n 설치 가이드
├── LECTURE_MATERIALS.md   ← 강의 자료 (상세)
├── CHEAT_SHEET.md         ← 빠른 참조 시트
├── CREDENTIALS_SETUP_GUIDE.md ← API 키 설정 상세 가이드
├── Dockerfile             ← Docker 설정 파일
└── docker-compose.yml     ← Docker 실행 설정
```

---

## 강의 목차 (2시간)

| 순서 | 주제 | 시간 |
|------|------|------|
| 1 | Local n8n 설치 | 20분 |
| 2 | 구글 시트 다루기 | 15분 |
| 3 | YouTube URL에서 스크립트 가져오기 | 15분 |
| 4 | AI Agent를 통한 새로운 대본 생성 | 25분 |
| 5 | API Service (Kie AI) 다루기 | 30분 |
| 6 | FFMPEG를 활용한 영상/오디오 결합 | 15분 |

---

## 자주 묻는 질문 (FAQ)

### Q: Docker Desktop이 뭔가요?
A: 컴퓨터 안에 작은 컴퓨터를 만들어주는 프로그램이에요. n8n을 깔끔하게 실행하기 위해 필요합니다.

### Q: n8n이 안 켜져요
A: Docker Desktop이 실행 중인지 확인하세요. 작업 표시줄에 고래 아이콘이 있어야 해요.

### Q: 영상이 안 만들어져요
A: 
1. API 키가 모두 올바르게 입력되었는지 확인
2. Kie AI 잔액이 있는지 확인
3. 원본 영상에 자막이 있는지 확인

### Q: 비용이 너무 비싸요
A: 이미지 개수를 6개에서 4개로 줄이거나, 비디오 길이를 5초에서 3초로 줄이면 비용을 절감할 수 있어요.

---

## 문제 해결

| 증상 | 원인 | 해결 방법 |
|------|------|----------|
| "port 5678 already in use" | 포트 충돌 | 다른 프로그램 종료 또는 포트 변경 |
| "No transcript available" | 자막 없는 영상 | 자막이 있는 영상으로 변경 |
| API 호출 실패 | 키 오류 또는 잔액 부족 | 키 재확인, 잔액 충전 |
| 영상 합치기 실패 | 파일 권한 문제 | Docker 재시작 |

---

## 유용한 명령어

```bash
# n8n 시작
docker compose up -d

# n8n 중지
docker compose down

# 로그 확인 (문제 발생 시)
docker compose logs -f

# n8n 업데이트
docker compose down
docker compose build --no-cache
docker compose up -d
```

---

## 관련 링크

- [n8n 공식 문서](https://docs.n8n.io)
- [n8n 커뮤니티](https://community.n8n.io)
- [Kie AI](https://kie.ai)
- [Google AI Studio](https://makersuite.google.com)

---

## 라이선스

MIT License - 자유롭게 사용하세요!

---

## 만든 사람

강의 문의: [이메일 또는 연락처 추가]

---

**즐거운 자동화 되세요!** 
