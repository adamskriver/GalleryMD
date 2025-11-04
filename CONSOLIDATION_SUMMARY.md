# GalleryMD - Docker Consolidation Summary

## ✅ What Was Changed

### Before (Messy Setup):
- ❌ Separate `docker-compose.runner.yml` for just one service
- ❌ No Docker Compose for the main app (manual `docker run` commands in workflow)
- ❌ Hardcoded paths in GitHub Actions workflow
- ❌ Stale runner tokens causing runner to not appear
- ❌ No network isolation between services
- ❌ Complex deployment script with repetitive logic

### After (Consolidated Setup):
- ✅ **Single `docker-compose.yml`** managing both app and runner
- ✅ **Shared network** (`gallerymd-network`) for service communication
- ✅ **Environment-based config** - all settings in `.env`
- ✅ **Automated token refresh** via `Start-GalleryMD.ps1`
- ✅ **Simplified deployment** - workflow just calls `docker compose`
- ✅ **Proper health checks** for the app
- ✅ **Volume management** for persistent runner data

## 📦 New File Structure

```
GalleryMD/
├── docker-compose.yml          ← NEW: Single compose file for everything
├── Dockerfile                  ← UNCHANGED: App container definition
├── Start-GalleryMD.ps1        ← NEW: Automated setup script
├── DOCKER.md                   ← NEW: Docker documentation
├── .env                        ← UPDATED: Consolidated environment vars
├── .github/workflows/
│   └── docker-build-push.yml  ← UPDATED: Simplified to use compose
└── docker-compose.runner.yml  ← DELETE THIS (obsolete)
```

## 🚀 How to Use

### First Time Setup
```powershell
.\Start-GalleryMD.ps1
```

This automatically:
1. Fetches fresh runner token from GitHub
2. Updates `.env`
3. Stops old containers
4. Builds and starts both services

### Daily Use
```powershell
# Start
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f

# Restart just the app
docker compose restart gallerymd
```

## 🔧 Key Improvements

### 1. Automatic Token Management
**Old way:** Manually get token → paste into `.env` → restart
**New way:** Run `.\Start-GalleryMD.ps1` → done

### 2. Simplified Deployment
**Old way (workflow):**
```yaml
docker build -t gallerymd-deno:latest .
docker stop gallerymd || true
docker rm gallerymd || true
docker run -d --name gallerymd --restart unless-stopped \
  -p 3003:3003 -v 'Z:/path:/docs' -e MD_ROOT=/docs gallerymd-deno:latest
```

**New way (workflow):**
```yaml
docker compose build gallerymd
docker compose up -d gallerymd
```

### 3. Network Isolation
Both services now share a dedicated bridge network, allowing:
- Inter-container communication by service name
- Network-level isolation from other Docker containers
- Future ability to add more services (Redis, database, etc.)

### 4. Configuration Management
**Old way:** Mix of `.env`, hardcoded values, and workflow variables
**New way:** Everything in `.env` with clear documentation

## 🔒 Security Improvements

1. **Read-only volume mounts** - App can't modify your markdown files
2. **Dedicated network** - Isolated from other containers
3. **Health checks** - Automatic restart if app becomes unhealthy
4. **Secret injection** - `ADMIN_TOKEN` comes from GitHub Secrets in CI/CD

## 📊 Current Status

✅ **Both containers running successfully:**
- `gallerymd` - Running on port 3003
- `gallerymd-runner` - Connected to GitHub, listening for jobs

✅ **Runner registered on GitHub:**
- Check: https://github.com/adamskriver/GalleryMD/settings/actions/runners
- Status: Online and ready to accept workflows

## 🧹 Cleanup Steps

1. **Delete old compose file:**
   ```powershell
   Remove-Item docker-compose.runner.yml
   ```

2. **Test the new setup:**
   ```powershell
   # Trigger a workflow manually
   gh workflow run "Deploy GalleryMD"
   
   # Watch it execute on your self-hosted runner
   docker compose logs -f runner
   ```

3. **Commit the changes:**
   ```powershell
   git add docker-compose.yml Start-GalleryMD.ps1 DOCKER.md .github/workflows/docker-build-push.yml
   git commit -m "Consolidate Docker setup into single compose file with automated token management"
   git push
   ```

## 🎯 Next Steps

1. Monitor the first automated deployment when you push to `main`
2. Consider adding more services to `docker-compose.yml` if needed (e.g., Redis, PostgreSQL)
3. Set up monitoring/alerting for container health
4. Document any custom workflow requirements

## 📚 Documentation

- See `DOCKER.md` for detailed Docker usage guide
- See `.github/workflows/docker-build-push.yml` for deployment workflow
- See `README.md` for application documentation

---

**Questions?** Check the logs:
```powershell
docker compose logs -f
```
