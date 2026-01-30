# n8n 유튜브 쇼츠 자동화 워크플로우 - 2시간 강의

## 강의 개요

**목적**: 기존 유튜브 영상 URL을 입력받아 새로운 쇼츠 영상을 자동으로 생성하는 워크플로우 구축

**소요 시간**: 2시간 (실습 포함)

**대상**: n8n 초보자

**필수 사전 준비**: Docker Desktop 설치 완료

---

## 목차

1. [Local n8n 설치 (20분)](#1-local-n8n-설치)
2. [구글 시트 다루기 (15분)](#2-구글-시트-다루기)
3. [YouTube URL에서 스크립트 가져오기 (15분)](#3-youtube-url에서-스크립트-가져오기)
4. [AI Agent를 통한 새로운 대본 생성 (25분)](#4-ai-agent를-통한-새로운-대본-생성)
5. [API Service (Kie AI) 다루기 (30분)](#5-api-service-kie-ai-다루기)
6. [FFMPEG를 활용한 영상/오디오 결합 (15분)](#6-ffmpeg를-활용한-영상오디오-결합)

---

## 1. Local n8n 설치

### 1.1 AI를 통한 자동 설치

Docker Desktop이 설치되어 있다면, Claude에게 다음과 같이 요청하세요:

```
n8n을 로컬에 설치해주세요. 
설치 가이드: /Users/jaehyunjang/n8n-self/N8N_INSTALL.md
```

### 1.2 수동 설치 단계

#### STEP 1: 설치 폴더 생성

**Mac / Linux**
```bash
mkdir -p ~/n8n-self
cd ~/n8n-self
```

**Windows (PowerShell)**
```powershell
mkdir C:\n8n-self
cd C:\n8n-self
```

#### STEP 2: Dockerfile 생성

```dockerfile
FROM node:20-alpine

RUN apk add --no-cache ffmpeg python3 py3-pip tini su-exec bc bash curl && \
    pip3 install --break-system-packages yt-dlp && \
    npm install -g n8n

RUN mkdir -p /home/node/.n8n /tmp/videos && \
    chown -R node:node /home/node /tmp/videos && \
    chmod 777 /tmp/videos

USER node
WORKDIR /home/node
EXPOSE 5678

ENTRYPOINT ["tini", "--"]
CMD ["sh", "-c", "umask 000 && n8n"]
```

> **중요**: `docker.n8n.io/n8nio/n8n` 공식 이미지는 사용하지 않습니다.
> 이 이미지는 Hardened Alpine으로 ffmpeg 설치가 불가능합니다.

#### STEP 3: docker-compose.yml 생성

```yaml
services:
  n8n:
    container_name: n8n-self
    build: .
    ports:
      - '5678:5678'
    environment:
      GENERIC_TIMEZONE: 'Asia/Seoul'
      TZ: 'Asia/Seoul'
      NODES_EXCLUDE: '[]'
      N8N_RESTRICT_FILE_ACCESS_TO: '/tmp/videos'
    volumes:
      - n8n-self-data:/home/node/.n8n
      - ./data/videos:/tmp/videos
    restart: unless-stopped

volumes:
  n8n-self-data:
```

| 환경변수 | 설명 |
|----------|------|
| `NODES_EXCLUDE: '[]'` | Execute Command 노드 활성화 |
| `N8N_RESTRICT_FILE_ACCESS_TO` | 파일 접근 경로 화이트리스트 |

#### STEP 4: 빌드 및 실행

```bash
# 빌드 (최초 1회, 약 2-3분)
docker compose build --no-cache

# 실행
docker compose up -d

# 확인
docker compose exec n8n ffmpeg -version
docker compose exec n8n yt-dlp --version
```

#### STEP 5: 접속 확인

- URL: `http://localhost:5678`
- 최초 접속 시 Owner 계정 생성

### 1.3 외부 접속 설정 (Webhook용)

```bash
# ngrok 설치 및 실행
ngrok http 5678
```

docker-compose.yml에 URL 추가:
```yaml
environment:
  WEBHOOK_URL: '<YOUR_NGROK_URL>'
  N8N_EDITOR_BASE_URL: '<YOUR_NGROK_URL>'
```

---

## 2. 구글 시트 다루기

### 2.1 워크플로우에서 Google Sheets의 역할

```
┌─────────────────────────────────────────────────────────────┐
│                    Google Sheets 구조                        │
├────────────┬─────────────┬──────────┬─────────────────────────┤
│ ID         │ YouTube_URL │ Status   │ Original_Script        │
├────────────┼─────────────┼──────────┼─────────────────────────┤
│ yt_001     │ https://... │ pending  │                        │
│ yt_002     │ https://... │ completed│ 안녕하세요 오늘은...    │
└────────────┴─────────────┴──────────┴─────────────────────────┘
```

**필요한 컬럼 목록:**

| 컬럼명 | 설명 |
|--------|------|
| `ID` | 고유 식별자 |
| `YouTube_URL` | 원본 유튜브 URL |
| `Status` | pending / processing / completed / failed |
| `Original_Script` | 원본 스크립트 |
| `New_Script` | AI가 생성한 새 대본 |
| `Image_Prompts` | 이미지 생성용 프롬프트 (JSON) |
| `Generated_Images` | 생성된 이미지 URL 목록 |
| `Video_Clips` | 생성된 비디오 URL 목록 |
| `Audio_URL` | TTS 오디오 URL |
| `Final_Video_URL` | 최종 영상 URL |
| `Error_Message` | 에러 메시지 |
| `Cost` | 비용 |
| `Created_At` / `Completed_At` | 타임스탬프 |

### 2.2 Google Sheets 노드 설정

#### 읽기 (Get Data)

```json
{
  "operation": "read",
  "documentId": "1wBEHr...",
  "sheetName": "시트1",
  "filtersUI": {
    "values": [{
      "lookupColumn": "Status",
      "lookupValue": "pending"
    }]
  },
  "options": {
    "returnFirstMatch": true
  }
}
```

**핵심 설정:**
- `returnFirstMatch: true` - 첫 번째 pending 항목만 가져옴
- 필터를 통해 처리할 항목만 선택

#### 업데이트 (Update Data)

```json
{
  "operation": "update",
  "columns": {
    "mappingMode": "defineBelow",
    "value": {
      "row_number": "={{ $json.row_number }}",
      "Status": "processing"
    },
    "matchingColumns": ["row_number"]
  }
}
```

**핵심 개념:**
- `matchingColumns` - 어떤 행을 업데이트할지 결정
- `row_number` - n8n이 자동으로 추가하는 행 번호

### 2.3 OAuth 인증 설정

1. Google Cloud Console에서 OAuth 2.0 클라이언트 ID 생성
2. n8n Credentials에서 Google Sheets OAuth2 추가
3. 권한 승인 (스프레드시트 읽기/쓰기)

---

## 3. YouTube URL에서 스크립트 가져오기

### 3.1 HTTP Request 노드 이해

외부 API를 호출할 때 사용하는 핵심 노드입니다.

```
┌─────────────────────────────────────────┐
│            HTTP Request 노드            │
├─────────────────────────────────────────┤
│  Method: GET / POST / PUT / DELETE      │
│  URL: API 엔드포인트                     │
│  Authentication: API Key, OAuth 등      │
│  Headers: Content-Type, Authorization   │
│  Body: JSON, Form Data 등               │
└─────────────────────────────────────────┘
```

### 3.2 YouTube Transcript API 호출

**RapidAPI - youtube-transcriptor 사용**

```
URL: https://youtube-transcriptor.p.rapidapi.com/transcript
Method: GET
Query Parameters:
  - video_id: {{ YouTube URL에서 추출한 ID }}
  - lang: ko (한국어 우선)
```

**HTTP Request 노드 설정:**

```json
{
  "method": "GET",
  "url": "https://youtube-transcriptor.p.rapidapi.com/transcript",
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth",
  "sendQuery": true,
  "queryParameters": {
    "parameters": [
      { "name": "video_id", "value": "={{ $json.YouTube_URL.match(/v=([^&]+)/)?.[1] || $json.YouTube_URL.split('/').pop() }}" },
      { "name": "lang", "value": "ko" }
    ]
  }
}
```

### 3.3 Transcript 파싱 (Code 노드)

```javascript
const input = $input.first().json;
let transcriptText = '';
let hasTranscript = false;

try {
  const data = Array.isArray(input) ? input[0] : input;
  
  if (data && data.transcriptionAsText) {
    transcriptText = data.transcriptionAsText
      .replace(/\n/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
    hasTranscript = transcriptText.length > 0;
  }
} catch (e) {
  hasTranscript = false;
}

return [{
  json: {
    transcript_text: transcriptText,
    has_transcript: hasTranscript
  }
}];
```

### 3.4 조건 분기 (IF 노드)

```
Has Transcript?
    │
    ├── true  → 다음 단계로 진행
    │
    └── false → 에러 처리
                Status = "failed"
                Error_Message = "No transcript available"
```

---

## 4. AI Agent를 통한 새로운 대본 생성

### 4.1 LangChain AI Agent 개요

n8n의 `@n8n/n8n-nodes-langchain.agent` 노드를 사용하여 AI 기반 대본 생성

```
┌─────────────────────────────────────────┐
│              AI Agent 구조              │
├─────────────────────────────────────────┤
│  [Input]                                │
│     ↓                                   │
│  [System Prompt] - 역할 및 규칙 정의    │
│     ↓                                   │
│  [User Prompt] - 실제 작업 지시         │
│     ↓                                   │
│  [Output Parser] - 구조화된 출력        │
│     ↓                                   │
│  [Parsed Output]                        │
└─────────────────────────────────────────┘
```

### 4.2 System Prompt 설계

```
당신은 한국 최정상급 숏폼 크리에이터입니다.

[출력 규칙]
- 순수 JSON만 출력 (마크다운 코드블록 금지)
- 큰따옴표 안에서 큰따옴표 사용 금지 → 작은따옴표 사용
- 줄바꿈은 \n으로

[필수 출력 구조]
new_script: 전체 나레이션 (한국어)
cuts: 6개 객체 배열
  - cut_number: 1~6
  - image_prompt: 영어 이미지 프롬프트 (50단어+)
  - subtitle_text: 한글 자막 (10자 이내)
  - duration: 5

[글자 수 규칙]
- new_script: **정확히 330-350자** (28초 분량)
```

### 4.3 User Prompt 템플릿

```
다음 유튜브 영상의 원본 트랜스크립트를 분석한 뒤, 
한국어 숏폼 나레이션과 이미지 프롬프트를 생성하세요.

원본 트랜스크립트:
{{ $json.Original_Script }}

작업 지시:

1단계 - 핵심 분석:
- 원본 영상의 핵심 메시지 1가지만 추출
- 시청자를 처음 2초 안에 사로잡을 훅 설계

2단계 - 한국어 나레이션 작성 (new_script):
- **정확히 330-350자** (28초 분량)
- 구어체, 짧은 문장, 임팩트 있는 표현

3단계 - 6개 컷 이미지 프롬프트:
각 컷마다:
(1) 주요 피사체와 행동 묘사
(2) 환경/배경
(3) 조명/분위기 (cinematic, neon glow 등)
(4) 카메라 앵글 (close-up, wide shot 등)
(5) 한글 자막: bold white Korean subtitle
(6) vertical 9:16, ultra detailed, photorealistic, 8K
```

### 4.4 Structured Output Parser

JSON Schema를 정의하여 AI 출력을 강제합니다:

```json
{
  "type": "object",
  "properties": {
    "new_script": {
      "type": "string",
      "description": "전체 나레이션 대본 (한국어, 350자)"
    },
    "cuts": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "cut_number": {"type": "number"},
          "image_prompt": {"type": "string"},
          "subtitle_text": {"type": "string"},
          "duration": {"type": "number"}
        },
        "required": ["cut_number", "image_prompt", "subtitle_text", "duration"]
      }
    }
  },
  "required": ["new_script", "cuts"]
}
```

### 4.5 LLM 모델 연결

Google Gemini 2.0 Flash 사용:

```
Model: models/gemini-2.0-flash
Temperature: 0.7
Max Tokens: 4000
```

---

## 5. API Service (Kie AI) 다루기

### 5.1 Kie AI 개요

Kie AI는 여러 AI 서비스를 통합 API로 제공하는 플랫폼입니다.

```
┌──────────────────────────────────────────────┐
│                   Kie AI                     │
├──────────────────────────────────────────────┤
│  Base URL: https://api.kie.ai/api/v1         │
│                                              │
│  [서비스 목록]                               │
│  ├── ElevenLabs TTS (음성 합성)              │
│  ├── Nano Banana Pro (이미지 생성)           │
│  └── Kling AI (비디오 생성)                  │
│                                              │
│  [인증]                                      │
│  Header: X-API-Key: your-api-key             │
└──────────────────────────────────────────────┘
```

### 5.2 공통 API 패턴

**1단계: 작업 생성 (Create Task)**
```
POST /jobs/createTask
Body: { model: "...", input: {...} }
Response: { data: { taskId: "abc123" } }
```

**2단계: 상태 확인 (Poll Status)**
```
GET /jobs/recordInfo?taskId=abc123
Response: { data: { state: "success/processing/failed", resultJson: "..." } }
```

### 5.3 ElevenLabs TTS (Text-to-Speech)

**음성 목록에서 랜덤 선택:**
```javascript
const voices = [
  'BIvP0GN1cAtSRTxNHnWS', 'aMSt68OGf4xUZAnLpTU8', 
  'RILOU7YmBhvwJGDGjNmP', ...
];
const randomVoice = voices[Math.floor(Math.random() * voices.length)];
```

**API 요청:**
```json
{
  "model": "elevenlabs/text-to-dialogue-v3",
  "input": {
    "stability": 0.5,
    "language_code": "ko",
    "dialogue": [{
      "text": "나레이션 텍스트",
      "voice": "선택된 보이스 ID"
    }]
  }
}
```

**폴링 및 결과 처리:**
```javascript
// 상태 확인 (15초 간격)
const result = JSON.parse(response.data.resultJson);
const audioUrl = result.resultUrls[0];

// 오디오 다운로드 및 처리
// 29초로 정규화 (FFMPEG)
ffmpeg -i audio.mp3 -af "atempo=..." -t 29 normalized.mp3
```

### 5.4 Nano Banana Pro (이미지 생성)

**API 요청:**
```json
{
  "model": "nano-banana-pro",
  "input": {
    "prompt": "이미지 프롬프트 (영어)",
    "aspect_ratio": "9:16",
    "resolution": "1K"
  }
}
```

**Loop 처리 (6개 이미지):**
```
┌─────────────────────────────────────────┐
│         Split In Batches 노드           │
├─────────────────────────────────────────┤
│  cuts[0] → Create Task → Poll → Store   │
│  cuts[1] → Create Task → Poll → Store   │
│  cuts[2] → Create Task → Poll → Store   │
│  cuts[3] → Create Task → Poll → Store   │
│  cuts[4] → Create Task → Poll → Store   │
│  cuts[5] → Create Task → Poll → Store   │
├─────────────────────────────────────────┤
│         Collect All Images              │
└─────────────────────────────────────────┘
```

**폴링 설정:**
- 대기 시간: 15초
- 최대 재시도: 20회 (약 5분)

### 5.5 Kling AI (비디오 생성)

**API 요청:**
```json
{
  "model": "kling-2.6/image-to-video",
  "input": {
    "prompt": "subtle natural movement, smooth camera motion, cinematic. IMPORTANT: Keep all text and subtitles from the first frame completely unchanged and fixed.",
    "image_urls": ["이미지 URL"],
    "sound": false,
    "duration": "5"
  }
}
```

> **중요**: 자막(텍스트)이 포함된 이미지는 `prompt`에 텍스트 고정 지시 필수

**폴링 설정:**
- 대기 시간: 90초 (비디오 생성은 오래 걸림)
- 최대 재시도: 15회 (약 22분)

### 5.6 비용 계산

| 서비스 | 단가 | 수량 | 소계 |
|--------|------|------|------|
| TTS (ElevenLabs) | $0.016 | 1회 | $0.016 |
| Image (Nano Banana) | $0.09 | 6개 | $0.54 |
| Video (Kling AI) | $0.275 | 6개 | $1.65 |
| AI Script | ~$0.05 | 1회 | $0.05 |
| **합계** | | | **$2.26** |

---

## 6. FFMPEG를 활용한 영상/오디오 결합

### 6.1 FFMPEG 개요

FFMPEG은 영상/오디오 처리를 위한 강력한 명령줄 도구입니다.

```
┌─────────────────────────────────────────┐
│              FFMPEG 기능                │
├─────────────────────────────────────────┤
│  - 영상 인코딩/디코딩                   │
│  - 오디오 처리 (속도 조절, 변환)        │
│  - 영상 합치기 (concat)                 │
│  - 영상 + 오디오 병합                   │
│  - 자막 삽입                            │
└─────────────────────────────────────────┘
```

### 6.2 오디오 정규화 (29초)

TTS 결과물을 정확히 29초로 맞추기:

```bash
# 원본 길이 확인
DURATION=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 input.mp3)

# 속도 계산 (bc 사용)
SPEED=$(echo "scale=4; $DURATION / 29" | bc)

# 속도 조절 적용
ffmpeg -y -i input.mp3 -af "atempo=$SPEED" -t 29 output.mp3
```

### 6.3 비디오 클립 합치기 (concat)

**concat.txt 파일 생성:**
```
file 'clip_1.mp4'
file 'clip_2.mp4'
file 'clip_3.mp4'
file 'clip_4.mp4'
file 'clip_5.mp4'
file 'clip_6.mp4'
```

**합치기 명령:**
```bash
ffmpeg -y -f concat -safe 0 -i concat.txt -c copy video_only.mp4
```

### 6.4 비디오 + 오디오 병합

```bash
ffmpeg -y -i video_only.mp4 -i audio.mp3 \
  -c:v copy -c:a aac -shortest final.mp4
```

| 옵션 | 설명 |
|------|------|
| `-c:v copy` | 비디오 재인코딩 없이 복사 (빠름) |
| `-c:a aac` | 오디오를 AAC로 인코딩 |
| `-shortest` | 짧은 스트림에 맞춰 자르기 |

### 6.5 Execute Command 노드

```javascript
// Code 노드에서 스크립트 생성
const dir = `/tmp/videos/yt_recreate_${id}`;
let script = `#!/bin/bash
set -e
DIR="${dir}"

# 비디오 다운로드
${videoUrls.map((url, i) => `curl -sL "${url}" -o $DIR/clip_${i+1}.mp4`).join('\n')}

# concat 파일 생성
> $DIR/concat.txt
${videoUrls.map((_, i) => `echo "file 'clip_${i+1}.mp4'" >> $DIR/concat.txt`).join('\n')}

# 합치기
cd $DIR
ffmpeg -y -f concat -safe 0 -i concat.txt -c copy video_only.mp4

# 오디오 병합
ffmpeg -y -i video_only.mp4 -i audio.mp3 -c:v copy -c:a aac -shortest final.mp4
`;

return [{ json: { assembly_script: script } }];
```

### 6.6 결과 확인 및 업로드

```javascript
// 최종 비디오 경로 추출
const finalPath = stdout.trim().split('\n').pop();

// YouTube 업로드
// Read Final Video → YouTube Upload 노드
```

---

## 워크플로우 전체 흐름도

```
┌─────────────────────────────────────────────────────────────────────┐
│                        YouTube Recreation v2                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [1. Google Sheets]                                                  │
│       │                                                              │
│       ↓                                                              │
│  Get Pending → Update Status (processing)                           │
│       │                                                              │
│       ↓                                                              │
│  [2. YouTube Transcript]                                             │
│       │                                                              │
│       ↓                                                              │
│  HTTP Request → Parse → Check Transcript                            │
│       │         │                                                    │
│       │         └── (No transcript) → Error                          │
│       ↓                                                              │
│  [3. AI Agent]                                                       │
│       │                                                              │
│       ↓                                                              │
│  Generate Script & Image Prompts → Update Sheets                    │
│       │                                                              │
│       ├─────────────────────────┐                                   │
│       ↓                         ↓                                   │
│  [4a. TTS]                [4b. Images]                              │
│       │                         │                                   │
│       ↓                         ↓                                   │
│  ElevenLabs             Nano Banana Pro                             │
│  (음성 생성)              (이미지 6개)                               │
│       │                         │                                   │
│       │                         ↓                                   │
│       │                   [4c. Videos]                              │
│       │                         │                                   │
│       │                         ↓                                   │
│       │                    Kling AI                                 │
│       │                   (비디오 6개)                               │
│       │                         │                                   │
│       └─────────┬───────────────┘                                   │
│                 ↓                                                    │
│  [5. FFMPEG Assembly]                                                │
│       │                                                              │
│       ↓                                                              │
│  Download Clips → Concat → Merge Audio → Final Video                │
│       │                                                              │
│       ↓                                                              │
│  [6. YouTube Upload]                                                 │
│       │                                                              │
│       ↓                                                              │
│  Upload → Update Status (completed)                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 트러블슈팅

### 일반적인 문제

| 문제 | 원인 | 해결 |
|------|------|------|
| Transcript 없음 | 자막 비활성화 영상 | 다른 영상 시도 |
| 이미지 생성 실패 | 프롬프트 부적절 | 프롬프트 수정 |
| 비디오 생성 실패 | Kling AI 서버 문제 | 재시도 |
| FFMPEG 에러 | 파일 권한 문제 | chmod 확인 |
| 업로드 실패 | OAuth 토큰 만료 | 재인증 |

### n8n 디버깅 팁

1. **실행 로그 확인**: 각 노드의 입력/출력 확인
2. **Code 노드에서 console.log**: 실행 결과에 표시됨
3. **Error Workflow 연결**: 에러 발생 시 알림 받기

---

## 실습 과제

### 과제 1: 기본 워크플로우 복제

1. 제공된 워크플로우 Import
2. Google Sheets 연결 (자신의 계정)
3. Kie AI 자격증명 설정
4. 테스트 실행

### 과제 2: 커스터마이징

1. AI 프롬프트 수정 (다른 스타일)
2. 이미지 프롬프트에 특정 스타일 추가
3. 비디오 길이 조정 (5초 → 7초)

### 과제 3: 에러 처리 강화(생략)

1. Error Workflow 연결
2. Slack/Discord 알림 추가
3. 재시도 로직 강화

---

## 참고 자료

- [n8n 공식 문서](https://docs.n8n.io)
- [Kie AI API 문서](https://api.kie.ai/docs)
- [ElevenLabs API](https://elevenlabs.io/docs)
- [FFMPEG 공식 문서](https://ffmpeg.org/documentation.html)
- [YouTube Data API](https://developers.google.com/youtube/v3)

---

## 강의 QR 코드 / 링크

- 워크플로우 공유 링크: [추가 예정]
- 강의 슬라이드: [추가 예정]
- GitHub 저장소: [추가 예정]
