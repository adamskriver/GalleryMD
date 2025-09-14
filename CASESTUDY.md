# GalleryMD Case Study

**GalleryMD** is a lightweight, Docker-ready web application that transforms a simple folder of Markdown “case study” files into a polished, responsive gallery with minimal dependencies—built from the ground up in Deno.
    
## 1. Why Deno & Oak?
- **Modern Look, Minimal Effort**: Deno’s standard library and Oak framework make it straightforward to ship a clean, light-themed UI without the boilerplate Next.js required.
- **No Blank-Screen Delays**: In our earlier Next.js prototype, the page would go blank while rebuilding or rescanning files on the server. With Deno, we serve cached data instantly and run file scans in the background, so users never see an empty screen.

## 2. Backend Architecture
- **In-Memory Cache**: On startup, the service scans the configured documents folder for `CASESTUDY.md` files (and matching images) and caches the results in memory for millisecond-fast API responses.
- **Background Scanning**: A timer-based scanner silently refreshes the cache every few minutes; users can also trigger a manual refresh via a button or API call.
- **Strong TypeScript**: Defined interfaces for case studies, secure path traversal protection, and crypto-backed IDs ensure robust, maintainable code.
- **Production-Ready**: Built-in rate limiting, CORS, and security headers (CSP, X-Frame-Options) make it safe for public deployment.

## 3. Frontend & UX
- **Responsive Card Layout**: Pure HTML/CSS/JavaScript (no heavy SPA frameworks) displays thumbnails and titles in a modern, accessible card grid.
- **Always-Visible Loading**: Clear loading indicators let users know content is loading—no guessing if the app is working.
- **Lightweight & Fast**: Minimal JavaScript bundle and CSS-only animations keep the UI snappy on desktop and mobile.

## 4. Docker Deployment
- **Tiny Alpine Image**: Under 50 MB, runs as a non-root user for security.
- **Volume Mount**: Easy to mount your local “Documents” folder so edits appear in real time.
- **One-Command Run**: `docker run -d --restart unless-stopped -p 3003:3003 -v "C:\Users\you\Documents:/app/docs" gallerymd`

## 5. Vibe + Traditional Code
- **Traditional Engineering**: Explicit middleware chains, error handling, typed interfaces, and secure file operations.
- **Playful Vibe**: Console logs with emojis (🔍, 🚀, ✅), automatic background refresh, and an interface that “just feels fast.”

---
*Built with ❤️ using Deno • Deployed via Docker*