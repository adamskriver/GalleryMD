# GalleryMD Filtering Configuration

## Overview

GalleryMD supports filtering to exclude specific directories and files from being scanned. This is particularly useful for preventing duplicate `CASESTUDY.md` files from appearing when they exist in CI/CD cache directories, build artifacts, or other temporary locations.

## Configuration File

Create a `gallerymd.config.json` file in your project root to configure filtering rules.

### Example Configuration

```json
{
  "filters": {
    "excludePaths": [
      "**/runner-data*/**",
      "**/.github/workflows/runner-data*/**",
      "**/node_modules/**",
      "**/.git/**",
      "**/dist/**",
      "**/build/**"
    ],
    "excludePatterns": {
      "CASESTUDY.md": [
        "**/runner-data*/**",
        "**/_work/**",
        "**/actions-runner/**",
        "**/.github/**/runner-data*/**"
      ]
    }
  }
}
```

## Configuration Options

### `excludePaths`

An array of glob patterns that apply to **all files**. Any path matching these patterns will be excluded from scanning.

**Examples:**
- `"**/node_modules/**"` - Excludes all node_modules directories
- `"**/.git/**"` - Excludes all .git directories
- `"**/build/**"` - Excludes all build directories
- `"**/runner-data*/**"` - Excludes any directory starting with "runner-data"

### `excludePatterns`

An object where keys are specific filenames (like `"CASESTUDY.md"`) and values are arrays of glob patterns. These patterns only apply when scanning for that specific filename.

**Examples:**
```json
"excludePatterns": {
  "CASESTUDY.md": [
    "**/runner-data*/**",
    "**/_work/**"
  ]
}
```

This configuration will filter out `CASESTUDY.md` files found in:
- Any directory starting with `runner-data`
- Any `_work` directory (common in GitHub Actions)

## Glob Pattern Syntax

- `*` - Matches any characters except `/` (single directory level)
- `**` - Matches any characters including `/` (multiple directory levels)
- `?` - Matches any single character
- `[abc]` - Matches any character in the set

### Pattern Examples

| Pattern | Matches |
|---------|---------|
| `**/temp/**` | Any file in a `temp` directory at any level |
| `**/cache-*/**` | Any file in directories starting with `cache-` |
| `**/.github/**` | Any file in `.github` directories |
| `**/build/*.md` | Markdown files directly in `build` directories |

## Default Behavior

If no `gallerymd.config.json` file is present, GalleryMD uses these default exclusions:

```json
{
  "filters": {
    "excludePaths": [
      "**/runner-data*/**",
      "**/node_modules/**",
      "**/.git/**"
    ],
    "excludePatterns": {}
  }
}
```

## Common Use Cases

### GitHub Actions Runner Cache

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

### Build Artifacts

```json
{
  "filters": {
    "excludePaths": [
      "**/dist/**",
      "**/build/**",
      "**/out/**",
      "**/.next/**"
    ]
  }
}
```

### Dependency Directories

```json
{
  "filters": {
    "excludePaths": [
      "**/node_modules/**",
      "**/vendor/**",
      "**/.venv/**",
      "**/target/**"
    ]
  }
}
```

## Logging

When filtering is active, GalleryMD logs excluded files:

```
✓ Loaded gallerymd.config.json
🔍 Starting directory scan...
⊘ Filtered: .github/workflows/runner-data-123/CASESTUDY.md
✅ Scan completed in 45ms. Found 3 case studies.
```

## Troubleshooting

### My filter isn't working

1. Check that the pattern uses forward slashes (`/`), not backslashes
2. Verify the pattern matches the **relative path** from your MD_ROOT
3. Remember that `*` only matches within a single directory level - use `**` for multiple levels
4. Check the console logs for "⊘ Filtered:" messages to see what's being excluded

### I want to see what paths would match

You can test patterns by checking the relative paths in the console output when filtering is enabled.

### Multiple CASESTUDY.md files still showing

If you're still seeing duplicates:
1. Verify the config file is named exactly `gallerymd.config.json`
2. Check that it's in the same directory as your `MD_ROOT`
3. Look at the console output to see if the filter is being applied
4. Add more specific patterns to catch the unwanted paths

## Example: Filtering GitHub Actions Cache

For a GitHub Actions self-hosted runner that caches data in the project root:

```json
{
  "filters": {
    "excludePaths": [
      "**/runner-data*/**",
      "**/.github/workflows/runner-data*/**",
      "**/node_modules/**",
      "**/.git/**"
    ],
    "excludePatterns": {
      "CASESTUDY.md": [
        "**/runner-data*/**",
        "**/_work/**",
        "**/actions-runner/**",
        "**/.github/**/runner-data*/**"
      ]
    }
  }
}
```

This ensures that:
- All files in `runner-data*` directories are excluded
- `CASESTUDY.md` files specifically are filtered from common CI/CD locations
- Standard directories like `node_modules` and `.git` are excluded

## Performance

Filtering is applied during directory scanning and has minimal performance impact. Patterns are evaluated using regex matching, which is fast even for large directory structures.
