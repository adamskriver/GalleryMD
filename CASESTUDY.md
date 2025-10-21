# GalleryMD Case Study

**GalleryMD** is a lightweight, Docker-ready web application that transforms a simple collection of Markdown “CASESTUDY.MD” files in a folder structure into a polished, responsive gallery with minimal dependencies—built from the ground up in Deno.

## 1. Why Deno & Oak?

- **Modern Look, Minimal Effort**: Deno’s standard library and Oak framework make it straightforward to ship a clean, light-themed UI without the boilerplate Next.js required.
- **No Blank-Screen Delays**: In our earlier Next.js prototype, the page would go blank while rebuilding or rescanning files on the server. With Deno, we serve cached data instantly and run file scans in the background, so users never see an empty screen.

> In Next.js that prototype relied on synchronous rebuilds and server-side rendering paths that could block responses while the project rebuilt or rescanned the filesystem, which caused visible blank-screen delays for users. Our Deno implementation instead returns cached results immediately and performs scans asynchronously in the background (or on a timer), so the UI remains populated while the cache updates. This non-blocking design keeps perceived latency low and avoids jarring refreshes.

## 2. Backend Architecture

- **In-Memory Cache**: On startup, the service scans the configured documents folder for `CASESTUDY.md` files (and matching images) and caches the results in memory for millisecond-fast API responses.
- **Background Scanning**: A timer-based scanner silently refreshes the cache every few minutes; users can also trigger a manual refresh via a button or API call.
- **Strong TypeScript**: Defined interfaces for case studies, secure path traversal protection, and crypto-backed IDs ensure robust, maintainable code.
- **Production-Ready**: Built-in rate limiting, CORS, and security headers (CSP, X-Frame-Options) make it safe for public deployment.

## 3. Frontend & UX

- **Responsive Card Layout**: Pure HTML/CSS/JavaScript (no heavy SPA frameworks) displays thumbnails and titles in a modern, accessible card grid.
- **Always-Visible Loading**: Clear loading indicators let users know content is loading—no guessing if the app is working.
- **Lightweight & Fast**: Minimal JavaScript bundle and CSS-only animations keep the UI snappy on desktop and mobile.

> We intentionally avoided large single-page application frameworks (React, Angular, Vue) to keep the client bundle tiny and the runtime simple. That reduces initial load time, eliminates heavy hydration costs, and keeps the project easy to deploy in a minimal Docker image. The compact codebase also makes for shorter, more focused prompts when "vibecoding"—small, targeted edits or feature additions can be described and implemented with less context because there are fewer framework abstractions to account for.

## 4. Docker Deployment

- **Tiny Alpine Image**: Under 50 MB, runs as a non-root user for security.
- **Volume Mount**: Easy to mount your local “Documents” folder so edits appear in real time.
- **One-Command Run**: `docker run -d --restart unless-stopped -p 3003:3003 -v "C:\Users\you\Documents:/app/docs" gallerymd`

## 5. Engineering Approach

- **Traditional Engineering**: Explicit middleware chains, error handling, typed interfaces, and secure file operations.
- **Performance Focus**: Automatic background refresh and an interface optimized for responsiveness and speed.

---

Built with ❤️ using Deno • Deployed via Docker
