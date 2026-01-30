# ============================================
# YouTube Automation - n8n + FFmpeg + yt-dlp
# ============================================
# Static FFmpeg: 공유 라이브러리 의존성 제로
# yt-dlp: Python pip으로 설치
# ============================================

# --- Stage 1: Download static FFmpeg ---
FROM alpine:3.20 AS downloader

RUN apk add --no-cache curl xz

# John Van Sickle's static FFmpeg build
# 완전 정적 링크 → 공유 라이브러리 불필요 → Alpine/musl에서도 작동
RUN curl -L "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" \
    -o /tmp/ffmpeg.tar.xz && \
    cd /tmp && tar xf ffmpeg.tar.xz && \
    mkdir -p /opt/ffmpeg && \
    cp /tmp/ffmpeg-*-amd64-static/ffmpeg /opt/ffmpeg/ && \
    cp /tmp/ffmpeg-*-amd64-static/ffprobe /opt/ffmpeg/ && \
    chmod +x /opt/ffmpeg/ffmpeg /opt/ffmpeg/ffprobe && \
    rm -rf /tmp/ffmpeg*

# --- Stage 2: Final n8n image ---
FROM n8nio/n8n:latest

USER root

# Static FFmpeg (의존성 없음)
COPY --from=downloader /opt/ffmpeg/ffmpeg /usr/local/bin/ffmpeg
COPY --from=downloader /opt/ffmpeg/ffprobe /usr/local/bin/ffprobe

# Python + yt-dlp 설치
RUN apk add --no-cache python3 py3-pip && \
    pip3 install --break-system-packages yt-dlp

# 임시 파일용 디렉토리
RUN mkdir -p /tmp/videos && chmod 777 /tmp/videos

USER node
