# Dazlin 💬

A real-time chat app built with Flutter Web + Cloudflare Worker backend.

**Color palette:** Neon lime `#B5F23A` on deep charcoal `#0A0D0A`  
**Font:** Sora (Google Fonts)  
**Backend:** `https://flat-waterfall-d7d4.tekbizz.workers.dev`

---

## Project Structure

```
lib/
  main.dart                    # Entry point + splash gate
  utils/
    constants.dart             # Worker URL, route names
    theme.dart                 # Full DazlinTheme (colors, typography)
  models/
    user_model.dart
    message_model.dart
    chat_model.dart
  services/
    api_service.dart           # All HTTP calls to Cloudflare Worker
    auth_service.dart          # Session persistence (SharedPreferences)
    chat_service.dart          # Polling-based real-time (3s / 4s intervals)
  widgets/
    dazlin_avatar.dart         # Avatar, UnreadBadge, GlowButton, DazlinField
  screens/
    auth_screen.dart           # Sign-in / Sign-up tabs + Google OAuth stub
    chats_screen.dart          # Chat list + sidebar (wide) / bottom nav (narrow)
    chat_screen.dart           # Conversation view with message bubbles
    new_chat_screen.dart       # Search users + create DM / group
    settings_screen.dart       # Profile edit + sign out
web/
  index.html                   # Flutter web host + native splash + Sora font
  manifest.json                # PWA manifest
.github/workflows/deploy.yml   # Auto-deploy to GitHub Pages on push to main
```

---

## Quick Start (Local)

```bash
flutter pub get
flutter run -d chrome
```

---

## Deploy to GitHub Pages

### 1. Create repo & push

```bash
git init
git add .
git commit -m "Initial Dazlin commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/dazlin.git
git push -u origin main
```

### 2. Enable GitHub Pages

Go to your repo → **Settings → Pages → Source → GitHub Actions**

### 3. Push = auto-deploy ✅

Every push to `main` triggers the workflow:
- Builds with `flutter build web --release --base-href "/dazlin/"`
- Deploys to `https://YOUR_USERNAME.github.io/dazlin/`

---

## Cloudflare Worker — Expected API Contract

The Worker at `flat-waterfall-d7d4.tekbizz.workers.dev` should implement:

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/signup` | `{email, username, password, display_name?}` → `{token, user}` |
| POST | `/api/auth/signin` | `{email_or_username, password}` → `{token, user}` |
| POST | `/api/auth/google` | `{id_token, email, display_name, avatar_url?}` → `{token, user}` |
| GET  | `/api/users/me` | Returns current user |
| POST | `/api/users/me/update` | `{display_name?, avatar_url?}` |
| POST | `/api/users/me/presence` | `{is_online: bool}` |
| GET  | `/api/users/search?q=` | Returns `{users: [...]}` |
| GET  | `/api/chats` | Returns `{chats: [...]}` |
| POST | `/api/chats/direct` | `{target_user_id}` → `{chat}` |
| POST | `/api/chats/group` | `{name, member_ids}` → `{chat}` |
| GET  | `/api/chats/:id/messages` | `?limit=50&before=` → `{messages}` |
| POST | `/api/chats/:id/messages` | `{content, type?, reply_to_id?}` → `{message}` |
| POST | `/api/chats/:id/read` | Mark messages read |

All authenticated routes require `Authorization: Bearer <token>` header.

---

## Google Sign-In Setup

1. Create an OAuth 2.0 Client ID at [console.cloud.google.com](https://console.cloud.google.com)
2. Add your GitHub Pages URL as an authorized JavaScript origin
3. Uncomment the `<meta name="google-signin-client_id">` tag in `web/index.html`
4. Uncomment the Google Sign-In code in `lib/screens/auth_screen.dart`

---

## TEKDEV · Dazlin v1.0.0
