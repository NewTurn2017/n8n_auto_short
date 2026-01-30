# n8n Credentials Setup Guide

## Required Credentials for YouTube Automation Workflows

This guide walks you through setting up all 5 required API credentials in your n8n instance.

---

## 1. Kie.ai API Credential

**Purpose**: Access Nano Banana Pro (image generation), Kling 2.1 (video generation), and ElevenLabs (TTS)

### Setup Steps:

1. **Get API Key**:
   - Visit [Kie.ai](https://kie.ai)
   - Sign up / Log in
   - Navigate to API Settings
   - Generate new API key

2. **Add to n8n**:
   - In n8n, go to **Settings** → **Credentials**
   - Click **Add Credential**
   - Select **Header Auth**
   - Configure:
     - **Name**: `Kie.ai API`
     - **Header Name**: `Authorization`
     - **Header Value**: `Bearer YOUR_API_KEY_HERE`
   - Click **Save**

3. **Test**:
   ```bash
   curl -H "Authorization: Bearer YOUR_API_KEY" \
        https://api.kie.ai/api/v1/models
   ```
   Should return 200 with model list.

---

## 2. Google Sheets OAuth2 Credential

**Purpose**: Read/write Google Sheets for queue management and status tracking

### Setup Steps:

1. **Enable Google Sheets API**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create new project or select existing
   - Navigate to **APIs & Services** → **Library**
   - Search for "Google Sheets API"
   - Click **Enable**

2. **Create OAuth2 Credentials**:
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth client ID**
   - Application type: **Web application**
   - Add authorized redirect URI:
     ```
     https://moving-owl-urgently.ngrok-free.app/rest/oauth2-credential/callback
     ```
   - Click **Create**
   - Copy **Client ID** and **Client Secret**

3. **Add to n8n**:
   - In n8n, go to **Settings** → **Credentials**
   - Click **Add Credential**
   - Select **Google Sheets OAuth2 API**
   - Configure:
     - **Client ID**: [from step 2]
     - **Client Secret**: [from step 2]
   - Click **Connect my account**
   - Authorize access
   - Click **Save**

4. **Test**:
   - Create a test workflow with Google Sheets node
   - Select the credential
   - Try reading a sheet
   - Should succeed without errors

---

## 3. Google Drive OAuth2 Credential

**Purpose**: Upload generated images/videos for URL access

### Setup Steps:

1. **Enable Google Drive API**:
   - In [Google Cloud Console](https://console.cloud.google.com/)
   - Same project as Sheets
   - Navigate to **APIs & Services** → **Library**
   - Search for "Google Drive API"
   - Click **Enable**

2. **Use Same OAuth2 Credentials**:
   - Google Drive can use the same OAuth2 client as Sheets
   - OR create separate credentials following same process

3. **Add to n8n**:
   - In n8n, go to **Settings** → **Credentials**
   - Click **Add Credential**
   - Select **Google Drive OAuth2 API**
   - Configure with same Client ID/Secret
   - Click **Connect my account**
   - Authorize access (including Drive scope)
   - Click **Save**

---

## 4. Gmail OAuth2 Credential

**Purpose**: Send notification emails on workflow completion/failure

### Setup Steps:

1. **Enable Gmail API**:
   - In [Google Cloud Console](https://console.cloud.google.com/)
   - Same project
   - Navigate to **APIs & Services** → **Library**
   - Search for "Gmail API"
   - Click **Enable**

2. **Add to n8n**:
   - In n8n, go to **Settings** → **Credentials**
   - Click **Add Credential**
   - Select **Gmail OAuth2 API**
   - Configure with same Client ID/Secret
   - Click **Connect my account**
   - Authorize access (including Gmail scope)
   - Click **Save**

---

## 5. YouTube OAuth2 Credential

**Purpose**: Upload generated videos to YouTube

### Setup Steps:

1. **Enable YouTube Data API v3**:
   - In [Google Cloud Console](https://console.cloud.google.com/)
   - Same project
   - Navigate to **APIs & Services** → **Library**
   - Search for "YouTube Data API v3"
   - Click **Enable**

2. **Add to n8n**:
   - In n8n, go to **Settings** → **Credentials**
   - Click **Add Credential**
   - Select **YouTube OAuth2 API**
   - Configure with same Client ID/Secret
   - Click **Connect my account**
   - Authorize access (including YouTube upload scope)
   - Click **Save**

3. **Important**: Ensure OAuth consent screen includes:
   - Scope: `https://www.googleapis.com/auth/youtube.upload`
   - Scope: `https://www.googleapis.com/auth/youtube`

---

## 6. Execute Command 노드 활성화 (n8n v2.0+)

**Purpose**: FFmpeg, yt-dlp 등 서버 명령어를 워크플로우에서 실행

### 왜 필요한가?

n8n v2.0부터 "Secure by Default" 정책으로 Execute Command 노드가 **기본 비활성화**됩니다.
노드 검색에서 보이지 않으며, 기존 워크플로우도 `Unrecognized node type` 오류가 발생합니다.

### 활성화 방법

`docker-compose.yml`의 `environment`에 추가:

```yaml
environment:
  - NODES_EXCLUDE=[]
```

이후 컨테이너 재시작:

```bash
docker compose down && docker compose up -d
```

### 확인

n8n UI에서 노드 검색창에 "Execute Command" 입력 → 노드가 표시되면 성공

---

## 7. Verify FFmpeg and yt-dlp Installation

**Purpose**: Video processing and YouTube download capabilities

### For Self-Hosted n8n:

```bash
# SSH into your n8n server
ssh user@your-n8n-server

# Check FFmpeg
ffmpeg -version
# Should show FFmpeg version info

# Check yt-dlp
yt-dlp --version
# Should show yt-dlp version info
```

### If Not Installed:

**Ubuntu/Debian**:
```bash
sudo apt update
sudo apt install -y ffmpeg
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp
```

**macOS**:
```bash
brew install ffmpeg yt-dlp
```

**Docker** (add to Dockerfile):
```dockerfile
RUN apt-get update && apt-get install -y ffmpeg
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && chmod a+rx /usr/local/bin/yt-dlp
```

### Docker (이 프로젝트의 Dockerfile):

이미 `Dockerfile`에 FFmpeg(static build)와 yt-dlp가 포함되어 있습니다.
`docker compose build && docker compose up -d`로 빌드하면 자동 설치됩니다.

---

## Verification Checklist

After setup, verify all credentials:

- [ ] Kie.ai API: Test HTTP request returns 200
- [ ] Google Sheets: Can read/write test sheet
- [ ] Google Drive: Can upload test file
- [ ] Gmail: Can send test email
- [ ] YouTube: Can access channel info
- [ ] FFmpeg: `ffmpeg -version` succeeds
- [ ] yt-dlp: `yt-dlp --version` succeeds

---

## Troubleshooting

### "Invalid credentials" error
- Re-authenticate OAuth2 credentials
- Check token expiration
- Verify API is enabled in Google Cloud Console

### "Permission denied" error
- Check OAuth consent screen scopes
- Ensure user authorized all requested permissions
- Re-authorize if scopes changed

### "Command not found: ffmpeg"
- FFmpeg not installed on server
- Follow installation steps above
- Verify PATH includes installation directory

### "API quota exceeded"
- Check Google Cloud Console quotas
- Request quota increase if needed
- Implement rate limiting in workflows

---

## Security Best Practices

1. **Never commit credentials** to version control
2. **Use environment variables** for sensitive data
3. **Rotate API keys** regularly
4. **Limit OAuth scopes** to minimum required
5. **Monitor API usage** for anomalies
6. **Enable 2FA** on all accounts

---

## Next Steps

Once all credentials are configured:

1. Execute the "Setup: Create YouTube Automation Sheets" workflow (ID: `w0QpowawopYEH6ai`)
2. Document the created Sheet IDs
3. Proceed with building the main automation workflows

---

**Need Help?**

- n8n Credentials Docs: https://docs.n8n.io/credentials/
- Google Cloud Console: https://console.cloud.google.com/
- Kie.ai Support: https://kie.ai/support
