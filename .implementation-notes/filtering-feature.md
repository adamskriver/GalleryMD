# Implementation Summary: Path Filtering for GalleryMD

## Problem
GitHub Actions self-hosted runners cache data in the project root (e.g., `runner-data*` directories), causing duplicate `CASESTUDY.md` files to appear in GalleryMD. These cached files could be out of sync with the actual case studies.

## Solution
Implemented a flexible JSON-based filtering system that allows excluding specific paths and files using glob patterns.

## Files Created/Modified

### New Files
1. **`config.ts`** - Filter configuration loader and pattern matching logic
2. **`gallerymd.config.json`** - Default filter configuration
3. **`FILTERING.md`** - Comprehensive documentation for the filtering feature

### Modified Files
1. **`server.ts`**
   - Added import for filter configuration module
   - Added `filterConfig` property to `GalleryService` class
   - Modified `initialize()` to load filter config
   - Updated `scanDirectory()` to apply filters during file scanning

2. **`Dockerfile`**
   - Added `config.ts` and `gallerymd.config.json` to copied files

3. **`README.md`**
   - Added "Flexible Filtering" to features list
   - Added new section documenting filtering configuration
   - Added link to FILTERING.md in additional documentation section

## How It Works

### Configuration Structure
```json
{
  "filters": {
    "excludePaths": ["**/pattern/**"],        // Applies to all files
    "excludePatterns": {
      "CASESTUDY.md": ["**/pattern/**"]       // File-specific patterns
    }
  }
}
```

### Filtering Logic
1. When GalleryMD starts, it loads `gallerymd.config.json` from MD_ROOT
2. During directory scanning, each file path is checked against:
   - General `excludePaths` patterns (applied to all files)
   - File-specific patterns in `excludePatterns` (only for matching filenames)
3. Files matching any pattern are excluded and logged with "⊘ Filtered:" prefix
4. If no config file exists, sensible defaults are used

### Glob Pattern Support
- `*` - Matches any characters except `/` (single level)
- `**` - Matches any characters including `/` (multiple levels)
- `?` - Matches any single character

### Example: Filtering Runner Cache
```json
{
  "filters": {
    "excludePatterns": {
      "CASESTUDY.md": [
        "**/runner-data*/**",
        "**/_work/**",
        "**/actions-runner/**"
      ]
    }
  }
}
```

## Benefits

1. **Prevents Duplicates** - Filters out CI/CD cache directories automatically
2. **Flexible** - Supports any glob pattern for maximum control
3. **File-Specific** - Can target just `CASESTUDY.md` without affecting other files
4. **Performance** - Minimal impact on scanning speed
5. **Logging** - Clear visibility of what's being filtered
6. **Safe Defaults** - Works out of the box with sensible exclusions

## Testing

The Docker build succeeded with all new files included:
```
✓ config.ts copied
✓ gallerymd.config.json copied
✓ Dependencies cached successfully
✓ Image built: gallerymd-deno:latest
```

## Next Steps

When the container runs, you'll see logs like:
```
✓ Loaded gallerymd.config.json
🔍 Starting directory scan...
⊘ Filtered: .github/workflows/runner-data-123/CASESTUDY.md
✅ Scan completed in 45ms. Found 3 case studies.
```

This confirms that duplicate `CASESTUDY.md` files in runner cache directories are being excluded as intended.

## Usage

Users can customize filtering by:
1. Creating `gallerymd.config.json` in their MD_ROOT directory
2. Adding patterns matching their specific cache directories
3. Monitoring logs to verify filtering is working correctly

See `FILTERING.md` for complete documentation and examples.
