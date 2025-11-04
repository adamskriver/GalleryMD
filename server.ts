import { Application, Router } from "https://deno.land/x/oak@v12.6.1/mod.ts";
import { walk } from "https://deno.land/std@0.200.0/fs/mod.ts";
import { extname, join, basename, dirname, relative, normalize } from "https://deno.land/std@0.200.0/path/mod.ts";
import { loadFilterConfig, shouldExcludePath, type FilterConfig } from "./config.ts";

interface CaseStudy {
  id: string;
  title: string;
  path: string;
  imagePath?: string;
  imageUrl?: string;
  content?: string;
}

// Configuration management
interface AppConfig {
  port: number;
  mdRoot: string;
  scanInterval: number; // in milliseconds
  rateLimitWindowMs: number;
  maxRequestsPerWindow: number;
  cacheMaxAge: number; // in seconds
  allowedOrigins: string; // CORS allowed origins
}

function loadConfig(): AppConfig {
  return {
    port: parseInt(Deno.env.get("PORT") || "3003"),
    mdRoot: Deno.env.get("MD_ROOT") || "./docs",
    scanInterval: parseInt(Deno.env.get("SCAN_INTERVAL") || "300000"), // 5 minutes
    rateLimitWindowMs: parseInt(Deno.env.get("RATE_LIMIT_WINDOW") || "60000"), // 1 minute
    maxRequestsPerWindow: parseInt(Deno.env.get("MAX_REQUESTS") || "100"),
    cacheMaxAge: parseInt(Deno.env.get("CACHE_MAX_AGE") || "3600"), // 1 hour
    allowedOrigins: Deno.env.get("ALLOWED_ORIGINS") || "*",
    // New: origins allowed to embed this site in frames (space-separated list),
    // e.g. "https://portfolio.adobe.com https://example.com"
    // If empty or not provided, framing will remain disallowed by default.
    // Use the environment variable FRAME_ALLOWED_ORIGINS to explicitly allow embedding.
    // For Adobe Portfolio you may set FRAME_ALLOWED_ORIGINS="https://portfolio.adobe.com"
    // Use exact origins only; do not include wildcards.
    // This value is read below by the framing middleware.
    // NOTE: Adding origins here relaxes clickjacking protections; restrict to trusted origins.
    // We'll read this using Deno.env.get('FRAME_ALLOWED_ORIGINS') where needed.
  };
}

const config = loadConfig();

class GalleryService {
  private caseStudies: CaseStudy[] = [];
  private isScanning = false;
  private lastScanTime = 0;
  private readonly mdRoot: string;
  private filterConfig: FilterConfig | null = null;

  constructor() {
    this.mdRoot = config.mdRoot;
    console.log(`📁 MD_ROOT set to: ${this.mdRoot}`);
  }

  async initialize() {
    console.log("🚀 Initializing gallery service...");
    this.filterConfig = await loadFilterConfig(this.mdRoot);
    await this.scanDirectory();
  }

  async scanDirectory(): Promise<void> {
    if (this.isScanning) {
      console.log("⏳ Scan already in progress, skipping...");
      return;
    }

    this.isScanning = true;
    const scanStart = Date.now();
    console.log("🔍 Starting directory scan...");

    try {
      const filePromises: string[] = [];
      
      // First gather all files
      for await (const entry of walk(this.mdRoot, {
        includeDirs: false,
        exts: [".md"],
        match: [/CASESTUDY\.md$/i]
      })) {
        // Apply filtering
        const relativePath = relative(this.mdRoot, entry.path);
        
        if (this.filterConfig && shouldExcludePath(relativePath, this.filterConfig, "CASESTUDY.md")) {
          console.log(`⊘ Filtered: ${relativePath}`);
          continue;
        }
        
        filePromises.push(entry.path);
      }
      
      // Then process them concurrently with Promise.all
      const caseStudyPromises = filePromises.map(filePath => this.processCaseStudy(filePath));
      const caseStudyResults = await Promise.all(caseStudyPromises);
      
      // Filter out null results
      this.caseStudies = caseStudyResults.filter(study => study !== null) as CaseStudy[];
      this.lastScanTime = Date.now();
      
      console.log(`✅ Scan completed in ${Date.now() - scanStart}ms. Found ${this.caseStudies.length} case studies.`);
    } catch (error) {
      console.error("❌ Error during directory scan:", error);
    } finally {
      this.isScanning = false;
    }
  }

  private async processCaseStudy(mdPath: string): Promise<CaseStudy | null> {
    try {
      const content = await Deno.readTextFile(mdPath);
      const dir = dirname(mdPath);
      const id = await this.generateId(mdPath);
      
      // Extract title from markdown
      const titleMatch = content.match(/^#\s+(.+)$/m);
      const title = titleMatch ? titleMatch[1].trim() : basename(dir);

  // Look for associated image (store path relative to mdRoot so it can be served from the container)
  const imagePath = await this.findAssociatedImage(dir);
  const relImagePath = imagePath ? relative(this.mdRoot, imagePath).replace(/\\/g, '/') : undefined;
  const imageUrl = relImagePath ? `/api/image?path=${encodeURIComponent(relImagePath)}` : undefined;

      return {
        id,
        title,
        path: mdPath,
        imagePath,
        imageUrl,
        content
      };
    } catch (error) {
      console.error(`❌ Error processing ${mdPath}:`, error);
      return null;
    }
  }

  private async findAssociatedImage(dir: string): Promise<string | undefined> {
    const imageExtensions = ['.png', '.jpg', '.jpeg', '.bmp', '.gif'];
    
    for (const ext of imageExtensions) {
      const imagePath = join(dir, `CASESTUDY${ext}`);
      try {
        const stat = await Deno.stat(imagePath);
        if (stat.isFile) {
          return imagePath;
        }
      } catch {
        // File doesn't exist, continue
      }
    }
    
    return undefined;
  }

  private async generateId(path: string): Promise<string> {
    // Use crypto for more secure and collision-resistant IDs
    const encoder = new TextEncoder();
    const data = encoder.encode(path);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('').substring(0, 16);
  }

  getCaseStudies(): CaseStudy[] {
    return this.caseStudies.map(cs => ({
      id: cs.id,
      title: cs.title,
      path: cs.path,
      imageUrl: cs.imageUrl
    }));
  }

  getCaseStudy(id: string): CaseStudy | undefined {
    return this.caseStudies.find(cs => cs.id === id);
  }

  async refreshCache(): Promise<void> {
    console.log("🔄 Manual refresh requested");
    await this.scanDirectory();
  }

  getStatus() {
    return {
      isScanning: this.isScanning,
      lastScanTime: this.lastScanTime,
      caseStudyCount: this.caseStudies.length
    };
  }
}

// Initialize service
const galleryService = new GalleryService();
await galleryService.initialize();

// Setup router
const router = new Router();

// API endpoints
router.get("/api/casestudies", (ctx) => {
  ctx.response.body = {
    success: true,
    data: galleryService.getCaseStudies(),
    timestamp: Date.now()
  };
});

router.get("/api/casestudy/:id", (ctx) => {
  const id = ctx.params.id;
  const caseStudy = galleryService.getCaseStudy(id);
  
  if (!caseStudy) {
    ctx.response.status = 404;
    ctx.response.body = { success: false, error: "Case study not found" };
    return;
  }
  
  ctx.response.body = {
    success: true,
    data: caseStudy
  };
});

// Protect refresh endpoint with a simple admin token check (replace with real auth as needed)
const ADMIN_TOKEN = Deno.env.get('ADMIN_TOKEN') || '';

router.post("/api/refresh", async (ctx) => {
  // Require an admin token in header 'X-Admin-Token'
  if (!ADMIN_TOKEN) {
    // If no token configured, deny by default to avoid accidental open endpoint
    ctx.response.status = 403;
    ctx.response.body = { success: false, error: "Server misconfiguration: admin token required" };
    return;
  }

  const provided = ctx.request.headers.get('x-admin-token') || '';
  if (provided !== ADMIN_TOKEN) {
    console.warn(`⚠️ Unauthorized refresh attempt from IP: ${ctx.request.ip}`);
    ctx.response.status = 403;
    ctx.response.body = { success: false, error: "Unauthorized" };
    return;
  }

  await galleryService.refreshCache();
  ctx.response.body = {
    success: true,
    message: "Cache refreshed successfully"
  };
});

router.get("/api/status", (ctx) => {
  ctx.response.body = {
    success: true,
    data: galleryService.getStatus()
  };
});

router.get("/api/image", async (ctx) => {
  const relPath = ctx.request.url.searchParams.get("path");

  if (!relPath || typeof relPath !== 'string') {
    ctx.response.status = 400;
    ctx.response.body = { error: "Invalid or missing path parameter" };
    return;
  }

  try {
    // Normalize the relative path and prevent traversal
    const cleanRel = normalize(relPath).replace(/(^\/+|\.\.+)/g, '').replace(/\\/g, '/');

    // Build absolute path under mdRoot
    const absPath = join(galleryService['mdRoot'], cleanRel);

    // Resolve real paths asynchronously
    const resolvedPath = await Deno.realPath(absPath);
    const resolvedRoot = await Deno.realPath(galleryService['mdRoot']);

    // Ensure the resolved path is inside the mdRoot
    if (!resolvedPath.startsWith(resolvedRoot)) {
      ctx.response.status = 403;
      ctx.response.body = { error: "Access denied" };
      return;
    }

    const fileInfo = await Deno.stat(resolvedPath);
    if (!fileInfo.isFile) {
      ctx.response.status = 404;
      return;
    }

    const ext = extname(resolvedPath).toLowerCase();
    const mimeTypes: Record<string, string> = {
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.bmp': 'image/bmp',
      '.gif': 'image/gif'
    };

    ctx.response.headers.set("Content-Type", mimeTypes[ext] || "application/octet-stream");
    ctx.response.headers.set("Cache-Control", `public, max-age=${config.cacheMaxAge}`);
    ctx.response.headers.set("X-Content-Type-Options", "nosniff");

    const file = await Deno.open(resolvedPath, { read: true });
    ctx.response.body = file.readable;
  } catch (error) {
    console.error("Error serving image:", error);
    ctx.response.status = 404;
  }
});

// Serve static files
router.get("/(.*)", async (ctx) => {
  const filePath = ctx.params[0] || "index.html";
  
  try {
    let contentType = "text/html";
    if (filePath.endsWith(".css")) contentType = "text/css";
    else if (filePath.endsWith(".js")) contentType = "application/javascript";
    else if (filePath.endsWith(".png")) contentType = "image/png";
    else if (filePath.endsWith(".jpg") || filePath.endsWith(".jpeg")) contentType = "image/jpeg";

    ctx.response.headers.set("Content-Type", contentType);
    ctx.response.body = await Deno.readFile(`./public/${filePath}`);
  } catch {
    // Fallback to index.html for SPA routing
    try {
      ctx.response.headers.set("Content-Type", "text/html");
      ctx.response.body = await Deno.readFile("./public/index.html");
    } catch {
      ctx.response.status = 404;
      ctx.response.body = "Not Found";
    }
  }
});

// Setup application
const app = new Application();

// Error handling middleware
app.use(async (ctx, next) => {
  try {
    await next();
  } catch (err) {
    console.error("Server error:", err);
    ctx.response.status = 500;
    ctx.response.body = { error: "Internal server error" };
  }
});

// CORS middleware for API endpoints
app.use(async (ctx, next) => {
  if (ctx.request.url.pathname.startsWith('/api')) {
    // Robust CORS: only allow configured origins (space-separated) or '*' for permissive mode.
    const rawAllowed = (config.allowedOrigins || '').trim();
    const allowAll = rawAllowed === '*';
    const allowedList = allowAll ? [] : rawAllowed.split(/\s+/).filter(Boolean);

    const origin = ctx.request.headers.get('origin');

    if (allowAll) {
      ctx.response.headers.set('Access-Control-Allow-Origin', '*');
    } else if (origin && allowedList.includes(origin)) {
      // Echo the exact origin back (recommended when not using '*')
      ctx.response.headers.set('Access-Control-Allow-Origin', origin);
      // Optional: allow credentials only when using specific origins
      ctx.response.headers.set('Access-Control-Allow-Credentials', 'false');
    } else {
      // No allowed origin: do not set CORS headers (will be blocked by browser)
      // Optionally, log suspicious cross-origin attempts
      if (origin) {
        console.warn(`⚠️ Blocked CORS request from disallowed origin: ${origin}`);
      }
    }

    ctx.response.headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    ctx.response.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Admin-Token");
    ctx.response.headers.set("Access-Control-Max-Age", "86400"); // 24 hours

    // Handle preflight OPTIONS request
    if (ctx.request.method === "OPTIONS") {
      ctx.response.status = 204; // No content
      return;
    }
  }
  await next();
});

// Framing / embedding middleware
app.use(async (ctx, next) => {
  // Read allowed frame ancestors from environment
  const frameAllowed = (Deno.env.get('FRAME_ALLOWED_ORIGINS') || '').trim();

  if (frameAllowed) {
    // Set a restrictive Content-Security-Policy that only allows the configured origins
    // to embed this site in a frame. Example value: "https://portfolio.adobe.com"
    // CSP requires the frame-ancestors directive; browsers that support it will honor it.
    ctx.response.headers.set('Content-Security-Policy', `frame-ancestors ${frameAllowed}`);

    // Remove legacy X-Frame-Options header if present to avoid conflicts. We only remove it
    // here by ensuring it's not set later; since this server doesn't set it elsewhere,
    // we proactively clear it for safety.
    ctx.response.headers.delete('X-Frame-Options');
  } else {
    // If no FRAME_ALLOWED_ORIGINS provided, explicitly deny framing via X-Frame-Options
    // for older browsers that don't support CSP.
    ctx.response.headers.set('X-Frame-Options', 'DENY');
  }

  await next();
});

// Rate limiting middleware
const rateLimitMap = new Map();
app.use(async (ctx, next) => {
  const ip = ctx.request.ip;
  const now = Date.now();
  const windowMs = config.rateLimitWindowMs;
  const maxRequests = config.maxRequestsPerWindow;

  if (!rateLimitMap.has(ip)) {
    rateLimitMap.set(ip, { count: 1, resetTime: now + windowMs });
  } else {
    const clientData = rateLimitMap.get(ip);
    if (now > clientData.resetTime) {
      clientData.count = 1;
      clientData.resetTime = now + windowMs;
    } else {
      clientData.count++;
      if (clientData.count > maxRequests) {
        ctx.response.status = 429;
        ctx.response.body = { 
          error: "Rate limit exceeded",
          resetAt: new Date(clientData.resetTime).toISOString()
        };
        return;
      }
    }
  }
  
  await next();
});

app.use(router.routes());
app.use(router.allowedMethods());

// Background scanning based on configured interval
setInterval(() => {
  if (!galleryService['isScanning']) {
    galleryService.scanDirectory();
  }
}, config.scanInterval);

// Add graceful shutdown handler
Deno.addSignalListener("SIGINT", () => {
  console.log("🛑 Shutting down server...");
  Deno.exit(0);
});

// SIGTERM is not supported on Windows
if (Deno.build.os !== "windows") {
  Deno.addSignalListener("SIGTERM", () => {
    console.log("🛑 Shutting down server...");
    Deno.exit(0);
  });
}

// Start the server
console.log(`🌐 Starting server on port ${config.port}...`);
console.log(`📂 Serving files from: ${galleryService['mdRoot']}`);
console.log(`🔄 Background scanning interval: ${config.scanInterval}ms`);

await app.listen({ port: config.port });
