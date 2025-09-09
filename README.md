# GalleryMD - Deno Edition

A fast, modern web-based gallery system for browsing and viewing Markdown case studies, built with Deno and designed to run in Docker containers.

## 🚀 Features

- **Lightning Fast**: Instant loading from cache with background refresh
- **Always-Visible Loading**: Clear loading indicators so users know when content is loading
- **Light Theme**: Clean, modern light-themed UI with smooth animations
- **Smart Image Detection**: Automatically finds and displays CASESTUDY.png/jpg/bmp thumbnails
- **Responsive Design**: Works perfectly on desktop, tablet, and mobile devices
- **Docker Ready**: Runs in secure Alpine-based container
- **Background Scanning**: Continuously monitors for new case studies
- **Manual Refresh**: One-click refresh with visual feedback

## 🏗️ Architecture

- **Backend**: Deno with Oak framework
- **Frontend**: Pure HTML5/CSS3/JavaScript (no heavy frameworks)
- **Security**: Path traversal protection, rate limiting, non-root user
- **Performance**: Async file operations, efficient caching, lazy loading images

## 📁 Expected Directory Structure

```
Documents/
├── ProjectA/
│   ├── CASESTUDY.md
│   └── CASESTUDY.png
├── ProjectB/
│   ├── CASESTUDY.md
│   └── CASESTUDY.jpg
└── ProjectC/
    └── CASESTUDY.md
```

## 🐳 Docker Usage

### Build the Image
```bash
docker build -t gallerymd-deno .
```

### Run the Container
```bash
# Windows
docker run -p 3000:3000 -v "C:/Your/Documents/Folder:/docs" -e MD_ROOT=/docs gallerymd-deno

# Linux/Mac
docker run -p 3000:3000 -v "/path/to/documents:/docs" -e MD_ROOT=/docs gallerymd-deno
```

### Environment Variables
- `MD_ROOT`: Directory to scan for case studies (default: `/docs`)
- `PORT`: Server port (default: `3000`)

## 🔧 Development

### Local Development (without Docker)
```bash
# Install Deno (if not already installed)
# See: https://deno.land/manual/getting_started/installation

# Clone/download the project
cd gallerymd

# Run the server
deno run --allow-net --allow-read --allow-env server.ts
```

### Environment Setup
```bash
# Set the documents root (adjust path as needed)
export MD_ROOT="/path/to/your/documents"
# or on Windows:
set MD_ROOT=C:\path\to\your\documents
```

## 🌐 API Endpoints

- `GET /api/casestudies` - List all case studies
- `GET /api/casestudy/:id` - Get individual case study content
- `POST /api/refresh` - Manually trigger cache refresh
- `GET /api/status` - Server status and scan progress
- `GET /api/image?path=...` - Serve case study images

## 🎨 UI Features

### Loading States
- Prominent loading spinner with descriptive text
- Never leaves users wondering if the app is working
- Smooth transitions between loading and content states

### Light Theme
- Clean, professional appearance
- Excellent readability
- Modern card-based layout
- Subtle shadows and hover effects

### Image Thumbnails
- Automatic detection of cover images
- Fallback to document icon when no image found
- Lazy loading for better performance
- Hover effects for better UX

## 🔒 Security Features

- Path traversal protection prevents access outside document root
- Rate limiting (100 requests per minute per IP)
- Runs as non-root user in Docker
- Secure image serving with MIME type detection
- Input validation and error handling

## 🚀 Performance Optimizations

- Instant loading from cached data
- Background directory scanning
- Efficient file system operations
- Image lazy loading
- Minimal JavaScript bundle
- CSS-only animations where possible

## 📱 Browser Support

- Chrome/Edge 88+
- Firefox 85+
- Safari 14+
- Mobile browsers with modern JavaScript support

## 🔧 Troubleshooting

### No Case Studies Showing
1. Check that `MD_ROOT` environment variable is set correctly
2. Ensure the mounted directory contains `CASESTUDY.md` files
3. Check container logs: `docker logs <container-name>`

### Images Not Loading
1. Ensure image files are named exactly `CASESTUDY.png/jpg/jpeg/bmp`
2. Check file permissions in mounted directory
3. Verify images are in the same directory as the `.md` files

### Performance Issues
1. Check available memory and CPU
2. Reduce scan frequency if needed
3. Consider excluding large subdirectories

## 🆚 Improvements Over Previous Version

- **Faster Loading**: Deno's performance benefits and optimized caching
- **Better UX**: Always-visible loading states and smoother animations  
- **Cleaner Design**: Light theme with modern aesthetics
- **More Reliable**: Better error handling and retry mechanisms
- **Lighter Weight**: No heavy Node.js dependencies

## 👥 Authors

- Adam (Project Owner)
- GitHub Copilot (AI Development Assistant)

---

*Built with ❤️ using Deno • Generated on 2025-09-09*
