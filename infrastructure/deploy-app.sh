# Deno Application Deployment Script
# Run this on the target VM after Ubuntu is installed

# Variables
REPO_URL="https://github.com/your-username/gallerymd.git"  # Replace with actual repo URL if available
APP_DIR="/home/pewter/gallerymd"
DOCS_DIR="$APP_DIR/docs"

echo "🚀 Setting up GalleryMD application..."

# Install Deno if not already installed
if ! command -v deno &> /dev/null; then
    echo "📦 Installing Deno..."
    curl -fsSL https://deno.land/install.sh | sh
    echo 'export DENO_INSTALL="$HOME/.deno"' >> ~/.bashrc
    echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> ~/.bashrc
    export DENO_INSTALL="$HOME/.deno"
    export PATH="$DENO_INSTALL/bin:$PATH"
else
    echo "✅ Deno already installed"
fi

# Create app directory structure
mkdir -p $APP_DIR
mkdir -p $DOCS_DIR

# Copy GalleryMD code to the server
# Option 1: If using Git
# echo "📂 Cloning GalleryMD repository..."
# git clone $REPO_URL $APP_DIR

# Option 2: If manually copying files
echo "📂 Creating application files..."

# Create server.ts
cat > $APP_DIR/server.ts << 'EOF'
import { Application, Router } from "https://deno.land/x/oak@v12.6.1/mod.ts";
import { walk } from "https://deno.land/std@0.200.0/fs/mod.ts";
import { extname, join, basename, dirname } from "https://deno.land/std@0.200.0/path/mod.ts";

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
    port: parseInt(Deno.env.get("PORT") || "3000"),
    mdRoot: Deno.env.get("MD_ROOT") || "./docs",
    scanInterval: parseInt(Deno.env.get("SCAN_INTERVAL") || "300000"), // 5 minutes
    rateLimitWindowMs: parseInt(Deno.env.get("RATE_LIMIT_WINDOW") || "60000"), // 1 minute
    maxRequestsPerWindow: parseInt(Deno.env.get("MAX_REQUESTS") || "100"),
    cacheMaxAge: parseInt(Deno.env.get("CACHE_MAX_AGE") || "3600"), // 1 hour
    allowedOrigins: Deno.env.get("ALLOWED_ORIGINS") || "*"
  };
}

const config = loadConfig();

interface CaseStudy {
  id: string;
  title: string;
  path: string;
  imagePath?: string;
  imageUrl?: string;
  content?: string;
}

class GalleryService {
  private caseStudies: CaseStudy[] = [];
  private isScanning = false;
  private lastScanTime = 0;
  private readonly mdRoot: string;

  constructor() {
    this.mdRoot = config.mdRoot;
    console.log(`📁 MD_ROOT set to: ${this.mdRoot}`);
  }

  async initialize() {
    console.log("🚀 Initializing gallery service...");
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

      // Look for associated image
      const imagePath = await this.findAssociatedImage(dir);
      const imageUrl = imagePath ? `/api/image?path=${encodeURIComponent(imagePath)}` : undefined;

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

router.post("/api/refresh", async (ctx) => {
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
  const imagePath = ctx.request.url.searchParams.get("path");
  
  if (!imagePath || typeof imagePath !== 'string') {
    ctx.response.status = 400;
    ctx.response.body = { error: "Invalid or missing path parameter" };
    return;
  }

  try {
    // Enhanced security check - normalize and sanitize path first
    // Remove any "../" sequences that might be used for path traversal
    const normalizedPath = join(galleryService['mdRoot'], imagePath.replace(/\.\./g, '')).replace(/\\/g, '/');
    
    // Then do the standard path resolution check
    const resolvedPath = Deno.realPathSync(normalizedPath);
    const resolvedRoot = Deno.realPathSync(galleryService['mdRoot']);
    
    if (!resolvedPath.startsWith(resolvedRoot)) {
      ctx.response.status = 403;
      ctx.response.body = { error: "Access denied" };
      return;
    }

    const fileInfo = await Deno.stat(imagePath);
    if (!fileInfo.isFile) {
      ctx.response.status = 404;
      return;
    }

    const ext = extname(imagePath).toLowerCase();
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
    
    const file = await Deno.open(imagePath, { read: true });
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
    ctx.response.headers.set("Access-Control-Allow-Origin", config.allowedOrigins);
    ctx.response.headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    ctx.response.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    ctx.response.headers.set("Access-Control-Max-Age", "86400"); // 24 hours

    // Handle preflight OPTIONS request
    if (ctx.request.method === "OPTIONS") {
      ctx.response.status = 204; // No content
      return;
    }
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

Deno.addSignalListener("SIGTERM", () => {
  console.log("🛑 Shutting down server...");
  Deno.exit(0);
});

// Start the server
console.log(`🌐 Starting server on port ${config.port}...`);
console.log(`📂 Serving files from: ${galleryService['mdRoot']}`);
console.log(`🔄 Background scanning interval: ${config.scanInterval}ms`);

await app.listen({ port: config.port });
EOF

# Create sample documents folder with a demo case study
mkdir -p $DOCS_DIR/demo

# Create sample CASESTUDY.md
cat > $DOCS_DIR/demo/CASESTUDY.md << 'EOF'
# Sample Case Study

This is a sample case study for the GalleryMD application.

## Overview

This demonstrates the functionality of the GalleryMD markdown rendering system.
EOF

# Create a public folder for static files
mkdir -p $APP_DIR/public

# Create index.html
cat > $APP_DIR/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GalleryMD</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>GalleryMD</h1>
        <p>A gallery of case studies</p>
    </header>
    
    <main>
        <div id="case-studies-container">
            <div class="loading">Loading case studies...</div>
        </div>
        
        <div id="case-study-detail" class="hidden">
            <button id="back-button">Back to Gallery</button>
            <div id="case-study-content"></div>
        </div>
    </main>
    
    <footer>
        <p>GalleryMD &copy; 2025</p>
    </footer>
    
    <script src="app.js"></script>
</body>
</html>
EOF

# Create styles.css
cat > $APP_DIR/public/styles.css << 'EOF'
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
    line-height: 1.6;
    color: #333;
    background-color: #f5f5f5;
}

header {
    background-color: #4a6fa5;
    color: white;
    padding: 2rem;
    text-align: center;
}

main {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
}

.case-study-card {
    background: white;
    border-radius: 5px;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
    margin-bottom: 2rem;
    overflow: hidden;
    transition: transform 0.3s ease;
    cursor: pointer;
}

.case-study-card:hover {
    transform: translateY(-5px);
}

.case-study-card img {
    width: 100%;
    height: 200px;
    object-fit: cover;
}

.case-study-card .content {
    padding: 1.5rem;
}

.case-study-card h2 {
    color: #4a6fa5;
    margin-bottom: 0.5rem;
}

.hidden {
    display: none;
}

#case-study-content {
    background: white;
    padding: 2rem;
    border-radius: 5px;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}

#back-button {
    background: #4a6fa5;
    color: white;
    border: none;
    padding: 0.5rem 1rem;
    margin-bottom: 1rem;
    border-radius: 3px;
    cursor: pointer;
}

footer {
    text-align: center;
    padding: 2rem;
    color: #777;
    font-size: 0.9rem;
}

.loading {
    text-align: center;
    padding: 2rem;
    color: #777;
}

@media (min-width: 768px) {
    #case-studies-container {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: 2rem;
    }
}
EOF

# Create app.js
cat > $APP_DIR/public/app.js << 'EOF'
document.addEventListener('DOMContentLoaded', () => {
    const caseStudiesContainer = document.getElementById('case-studies-container');
    const caseStudyDetail = document.getElementById('case-study-detail');
    const caseStudyContent = document.getElementById('case-study-content');
    const backButton = document.getElementById('back-button');
    
    // Fetch case studies
    fetchCaseStudies();
    
    // Event listeners
    backButton.addEventListener('click', showGallery);
    
    // Functions
    async function fetchCaseStudies() {
        try {
            const response = await fetch('/api/casestudies');
            const data = await response.json();
            
            if (data.success) {
                displayCaseStudies(data.data);
            } else {
                showError('Failed to load case studies');
            }
        } catch (error) {
            showError('Error loading case studies: ' + error.message);
        }
    }
    
    function displayCaseStudies(caseStudies) {
        caseStudiesContainer.innerHTML = '';
        
        if (caseStudies.length === 0) {
            caseStudiesContainer.innerHTML = '<div class="loading">No case studies found</div>';
            return;
        }
        
        caseStudies.forEach(study => {
            const card = document.createElement('div');
            card.className = 'case-study-card';
            card.dataset.id = study.id;
            
            let imageHtml = '';
            if (study.imageUrl) {
                imageHtml = `<img src="${study.imageUrl}" alt="${study.title}">`;
            }
            
            card.innerHTML = `
                ${imageHtml}
                <div class="content">
                    <h2>${study.title}</h2>
                </div>
            `;
            
            card.addEventListener('click', () => fetchCaseStudy(study.id));
            caseStudiesContainer.appendChild(card);
        });
    }
    
    async function fetchCaseStudy(id) {
        try {
            const response = await fetch(`/api/casestudy/${id}`);
            const data = await response.json();
            
            if (data.success) {
                displayCaseStudyDetail(data.data);
            } else {
                showError('Failed to load case study');
            }
        } catch (error) {
            showError('Error loading case study: ' + error.message);
        }
    }
    
    function displayCaseStudyDetail(study) {
        // Simple markdown to HTML conversion
        const html = convertMarkdownToHtml(study.content);
        
        caseStudyContent.innerHTML = html;
        
        caseStudiesContainer.classList.add('hidden');
        caseStudyDetail.classList.remove('hidden');
    }
    
    function showGallery() {
        caseStudyDetail.classList.add('hidden');
        caseStudiesContainer.classList.remove('hidden');
    }
    
    function showError(message) {
        caseStudiesContainer.innerHTML = `<div class="error">${message}</div>`;
    }
    
    // Very basic Markdown to HTML converter
    function convertMarkdownToHtml(markdown) {
        if (!markdown) return '';
        
        // Convert headers
        let html = markdown.replace(/^# (.*$)/gm, '<h1>$1</h1>');
        html = html.replace(/^## (.*$)/gm, '<h2>$1</h2>');
        html = html.replace(/^### (.*$)/gm, '<h3>$1</h3>');
        
        // Convert paragraphs
        html = html.replace(/^\s*(\n)?(.+)/gm, function (m) {
            return /\<(\/)?(h|ul|ol|li|blockquote|pre|img)/.test(m) ? m : '<p>' + m + '</p>';
        });
        
        // Convert bold and italic
        html = html.replace(/\*\*(.*)\*\*/gm, '<strong>$1</strong>');
        html = html.replace(/\*(.*)\*/gm, '<em>$1</em>');
        
        return html;
    }
});
EOF

# Set up environment variables
cat > $APP_DIR/.env << EOF
PORT=3000
MD_ROOT=$DOCS_DIR
SCAN_INTERVAL=300000
CACHE_MAX_AGE=3600
ALLOWED_ORIGINS=*
EOF

# Set correct permissions
chown -R pewter:pewter $APP_DIR

# Create systemd service
sudo tee /etc/systemd/system/gallerymd.service > /dev/null << EOF
[Unit]
Description=GalleryMD Server
After=network.target

[Service]
Type=simple
User=pewter
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
ExecStart=/home/pewter/.deno/bin/deno run --allow-net --allow-read --allow-env --allow-write server.ts
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl enable gallerymd.service
sudo systemctl start gallerymd.service

# Show status
echo "✅ GalleryMD setup complete!"
echo "🔎 Checking service status..."
sudo systemctl status gallerymd.service

echo ""
echo "📋 Next steps:"
echo "1. Access the application at http://$(hostname -I | awk '{print $1}'):3000"
echo "2. Add your case study files to $DOCS_DIR"
echo "3. To manage the service: sudo systemctl [start|stop|restart|status] gallerymd.service"
echo ""
