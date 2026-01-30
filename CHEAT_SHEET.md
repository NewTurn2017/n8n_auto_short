# n8n YouTube Shorts Automation - Cheat Sheet

## Quick Commands

### Docker

```bash
# 시작
docker compose up -d

# 중지
docker compose down

# 로그 확인
docker compose logs -f

# 재빌드 (업데이트)
docker compose build --no-cache && docker compose up -d
```

### ngrok (외부 접속)

```bash
ngrok http 5678
```

---

## n8n Expression 문법

```javascript
// 현재 노드 데이터
{{ $json.fieldName }}

// 특정 노드 데이터
{{ $('NodeName').item.json.field }}

// 모든 항목
{{ $('NodeName').all() }}

// 조건문
{{ $json.status === 'active' ? 'yes' : 'no' }}

// 현재 시간
{{ $now.toISO() }}
```

---

## Kie AI API

### Base URL
```
https://api.kie.ai/api/v1
```

### 작업 생성
```
POST /jobs/createTask
Body: { "model": "...", "input": {...} }
```

### 상태 확인
```
GET /jobs/recordInfo?taskId=xxx
Response: { "data": { "state": "success/processing/failed" } }
```

### 모델별 비용

| 모델 | 용도 | 단가 |
|------|------|------|
| elevenlabs/text-to-dialogue-v3 | TTS | $0.016 |
| nano-banana-pro | 이미지 | $0.09 |
| kling-2.6/image-to-video | 비디오 | $0.275 |

---

## FFMPEG 명령어

```bash
# 오디오 길이 확인
ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 input.mp3

# 오디오 속도 조절
ffmpeg -y -i input.mp3 -af "atempo=1.1" -t 29 output.mp3

# 비디오 합치기
ffmpeg -y -f concat -safe 0 -i concat.txt -c copy output.mp4

# 비디오 + 오디오 병합
ffmpeg -y -i video.mp4 -i audio.mp3 \
  -c:v copy -c:a aac -shortest final.mp4
```

---

## 워크플로우 섹션별 노드

### 1. Google Sheets
- Get Google Sheets
- Update Status
- Update Original Script
- Update AI Data
- Final Update

### 2. YouTube Transcript
- HTTP Request (youtube-transcriptor)
- Parse Transcript (Code)
- Check Transcript (IF)

### 3. AI Agent
- AI Script Agent (LangChain)
- Structured Output Parser
- Parse AI Output (Code)

### 4a. TTS (ElevenLabs)
- Prepare TTS Request
- Create TTS Task
- Poll TTS Status
- Normalize Audio (Execute Command)

### 4b. Image (Nano Banana Pro)
- Split Cuts to Items
- Image Loop (Split In Batches)
- Create Image Task
- Poll Image Status
- Collect All Images

### 4c. Video (Kling AI)
- Split Images for Video
- Video Loop (Split In Batches)
- Create Video Task
- Poll Video Status
- Collect All Videos

### 5. FFMPEG Assembly
- Merge Branches
- Prepare Assembly
- Download and Assemble
- Set Assembly Result

### 6. YouTube Upload
- Read Final Video
- AI Metadata Agent
- Prepare Upload Metadata
- YouTube Upload
- Calculate Cost

---

## 자주 발생하는 에러

| 에러 | 원인 | 해결 |
|------|------|------|
| No transcript | 자막 없는 영상 | 다른 영상 시도 |
| Task timeout | API 응답 지연 | 대기 시간 증가 |
| Permission denied | 파일 권한 | chmod 777 /tmp/videos |
| OAuth expired | 토큰 만료 | 자격증명 재연결 |

---

## 총 비용 계산

```
TTS:    $0.016 × 1  = $0.016
Image:  $0.09  × 6  = $0.54
Video:  $0.275 × 6  = $1.65
AI:     $0.05  × 1  = $0.05
------------------------
Total:              ≈ $2.26/영상
```

---

## 유용한 링크

- n8n 문서: https://docs.n8n.io
- Kie AI: https://api.kie.ai
- FFMPEG: https://ffmpeg.org/documentation.html
