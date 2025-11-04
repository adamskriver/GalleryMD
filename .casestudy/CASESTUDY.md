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
- **Production-Ready**: Built-in rate limiting, configurable CORS with origin whitelisting, admin token protection for sensitive endpoints, and security headers (CSP frame-ancestors, X-Frame-Options) make it safe for public deployment.
- **Smart Filtering**: Configurable glob patterns exclude CI/CD artifacts, build directories, and other non-content paths from the gallery to prevent duplicate entries.

## 3. Frontend & UX

- **Responsive Card Layout**: Pure HTML/CSS/JavaScript (no heavy SPA frameworks) displays thumbnails and titles in a modern, accessible card grid.
- **Always-Visible Loading**: Clear loading indicators let users know content is loading—no guessing if the app is working.
- **Lightweight & Fast**: Minimal JavaScript bundle and CSS-only animations keep the UI snappy on desktop and mobile.

> We intentionally avoided large single-page application frameworks (React, Angular, Vue) to keep the client bundle tiny and the runtime simple. That reduces initial load time, eliminates heavy hydration costs, and keeps the project easy to deploy in a minimal Docker image. The compact codebase also makes for shorter, more focused prompts when "vibecoding"—small, targeted edits or feature additions can be described and implemented with less context because there are fewer framework abstractions to account for.

## 4. Docker Deployment

- **Tiny Alpine Image**: Under 50 MB, runs as a non-root user for security.
- **Volume Mount**: Easy to mount your local "Documents" folder so edits appear in real time.
- **Consolidated Compose**: Single `docker-compose.yml` orchestrates both the gallery app and optional self-hosted GitHub Actions runner with automated token refresh.
- **One-Command Run**: `docker run -d --restart unless-stopped -p 3003:3003 -v "C:\Users\you\Documents:/app/docs" gallerymd`
- **Environment-Based Config**: CORS origins, admin tokens, frame embedding permissions, and scanning intervals all configured via environment variables for flexible deployment.

## 5. CI/CD & Self-Hosted Runners

- **GitHub Actions Integration**: Automated builds and tests run on every push to main.
- **Docker-Based Runner**: Self-hosted GitHub Actions runner runs in a lightweight container alongside the app—no GitHub-hosted minutes consumed.
- **Automated Token Management**: PowerShell script (`Start-GalleryMD.ps1`) fetches fresh runner registration tokens via GitHub CLI and updates the environment automatically—no manual token pasting required.
- **Single Compose File**: Both app and runner services defined in one `docker-compose.yml` for simplified deployment and lifecycle management.
- **Local Build Validation**: Workflows build the Docker image locally on the self-hosted runner, catching issues before deployment.
- **No Blank Screens During CI**: The runner and app containers operate independently; the gallery stays responsive even while builds run in the background.

> This setup demonstrates how a small project can achieve full CI/CD capabilities with minimal infrastructure—just Docker Desktop and a few PowerShell scripts. The self-hosted runner approach is especially valuable for private repos where GitHub-hosted runner minutes are limited, and it ensures builds happen in the same Windows environment where the app actually runs. The automated token refresh eliminates the previous manual workflow of fetching tokens and updating `.env` files every hour.

## 6. Security & Production Readiness

- **CORS Protection**: Configurable origin whitelisting prevents unauthorized cross-origin API access while allowing trusted domains.
- **Admin Token Authentication**: Sensitive endpoints like `/api/refresh` require an admin token header to prevent abuse and unauthorized cache manipulation.
- **Frame Embedding Control**: Content Security Policy with `frame-ancestors` directive allows controlled embedding (e.g., Adobe Portfolio) while blocking unauthorized iframe usage.
- **Path Traversal Prevention**: Async `realPath` resolution ensures all file access stays within the configured document root.
- **Rate Limiting**: Per-IP request throttling (100 requests/minute by default) protects against DoS and excessive API usage.
- **Non-Root Execution**: Docker container runs as unprivileged user (`deno:deno`) for defense-in-depth security.

## 7. Engineering Approach

- **Traditional Engineering**: Explicit middleware chains, error handling, typed interfaces, and secure file operations.
- **Performance Focus**: Automatic background refresh and an interface optimized for responsiveness and speed.
- **Infrastructure as Code**: Dockerfiles, compose configurations, and cloud-init scripts make deployment repeatable and auditable.
- **Open Source**: Repository made public (November 2025) after thorough security audit to ensure no credentials or sensitive data in git history.

---

Built with ❤️ using Deno • Deployed via Docker • CI/CD with GitHub Actions • Open Source
