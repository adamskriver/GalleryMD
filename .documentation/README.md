# GalleryMD Documentation

This directory contains technical documentation for the GalleryMD project.

## 📚 Documentation Files

- **[FILTERING.md](FILTERING.md)** - Complete guide to the filtering system for excluding directories and files from the gallery
- **[RUNNER_SETUP.md](RUNNER_SETUP.md)** - Instructions for setting up GitHub Actions self-hosted runner with Docker

## 📁 Project Organization

The GalleryMD project uses the following organizational structure:

```
GalleryMD/
├── .casestudy/          # Case study and project documentation
├── .documentation/      # Technical documentation (this folder)
├── .implementation-notes/  # Development notes and implementation details
├── archive/             # Archived infrastructure and old versions
├── public/              # Frontend assets (HTML, CSS, JS)
├── scripts/             # Utility scripts
└── [root files]         # Core application files (server.ts, config.ts, etc.)
```

## 🔒 Hidden Folders

Folders prefixed with `.` are excluded from the gallery scanning by default to keep the project organized and prevent clutter in the case study gallery.

---

*Last updated: October 27, 2025*
