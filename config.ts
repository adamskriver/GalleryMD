import { join } from "https://deno.land/std@0.200.0/path/mod.ts";

export interface FilterConfig {
  filters: {
    excludePaths?: string[];
    excludePatterns?: {
      [filename: string]: string[];
    };
  };
}

const DEFAULT_CONFIG: FilterConfig = {
  filters: {
    excludePaths: [
      "**/runner-data*/**",
      "**/node_modules/**",
      "**/.git/**",
    ],
    excludePatterns: {},
  },
};

let cachedConfig: FilterConfig | null = null;

export async function loadFilterConfig(rootDir: string): Promise<FilterConfig> {
  if (cachedConfig) return cachedConfig;

  const configPath = join(rootDir, "gallerymd.config.json");
  
  try {
    const configText = await Deno.readTextFile(configPath);
    cachedConfig = JSON.parse(configText);
    console.log("✓ Loaded gallerymd.config.json");
    return cachedConfig!;
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      console.log("ℹ Using default filter configuration");
      cachedConfig = DEFAULT_CONFIG;
      return DEFAULT_CONFIG;
    }
    throw error;
  }
}

/**
 * Convert glob pattern to regex
 */
function matchesPattern(path: string, pattern: string): boolean {
  // Normalize path separators to forward slashes
  const normalizedPath = path.replace(/\\/g, "/");
  
  // Convert glob pattern to regex
  const regexPattern = pattern
    .replace(/\./g, "\\.")
    .replace(/\*\*/g, "§§DOUBLESTAR§§")  // Temporarily replace **
    .replace(/\*/g, "[^/]*")              // * matches anything except /
    .replace(/§§DOUBLESTAR§§/g, ".*")     // ** matches anything including /
    .replace(/\?/g, ".");
  
  const regex = new RegExp(`^${regexPattern}$`);
  return regex.test(normalizedPath);
}

/**
 * Check if a path should be excluded based on filter configuration
 */
export function shouldExcludePath(
  relativePath: string,
  config: FilterConfig,
  filename?: string
): boolean {
  const normalizedPath = relativePath.replace(/\\/g, "/");
  
  // Check general excludePaths
  if (config.filters.excludePaths) {
    for (const pattern of config.filters.excludePaths) {
      if (matchesPattern(normalizedPath, pattern)) {
        return true;
      }
    }
  }
  
  // Check filename-specific patterns
  if (filename && config.filters.excludePatterns?.[filename]) {
    for (const pattern of config.filters.excludePatterns[filename]) {
      if (matchesPattern(normalizedPath, pattern)) {
        return true;
      }
    }
  }
  
  return false;
}
