class GalleryApp {
  constructor() {
    this.caseStudies = [];
    this.isLoading = false;
    this.currentModal = null;
    
    this.elements = {
      loadingScreen: document.getElementById('loadingScreen'),
      errorScreen: document.getElementById('errorScreen'),
      galleryContainer: document.getElementById('galleryContainer'),
      galleryGrid: document.getElementById('galleryGrid'),
      gallerySubtitle: document.getElementById('gallerySubtitle'),
      emptyState: document.getElementById('emptyState'),
      refreshBtn: document.getElementById('refreshBtn'),
      refreshEmptyBtn: document.getElementById('refreshEmptyBtn'),
      retryBtn: document.getElementById('retryBtn'),
      statusIndicator: document.getElementById('statusIndicator'),
      modal: document.getElementById('modal'),
      modalOverlay: document.getElementById('modalOverlay'),
      modalTitle: document.getElementById('modalTitle'),
      modalContent: document.getElementById('modalContent'),
      modalLoading: document.getElementById('modalLoading'),
      modalError: document.getElementById('modalError'),
      modalClose: document.getElementById('modalClose'),
      errorMessage: document.getElementById('errorMessage')
    };
    
    this.init();
  }
  
  async init() {
    console.log('🚀 Initializing GalleryApp...');
    this.bindEvents();
    await this.loadCaseStudies();
    this.startStatusPolling();
  }
  
  bindEvents() {
    // Refresh buttons
    this.elements.refreshBtn.addEventListener('click', () => this.handleRefresh());
    this.elements.refreshEmptyBtn.addEventListener('click', () => this.handleRefresh());
    this.elements.retryBtn.addEventListener('click', () => this.loadCaseStudies());
    
    // Modal events
    this.elements.modalClose.addEventListener('click', () => this.closeModal());
    this.elements.modalOverlay.addEventListener('click', () => this.closeModal());
    
    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.currentModal) {
        this.closeModal();
      }
    });
    
    // Handle browser back/forward
    window.addEventListener('popstate', () => {
      if (this.currentModal) {
        this.closeModal();
      }
    });
  }
  
  async loadCaseStudies() {
    if (this.isLoading) {
      console.log('📋 Load already in progress, skipping...');
      return;
    }
    
    this.isLoading = true;
    console.log('📋 Loading case studies...');
    
    this.showLoadingScreen();
    
    try {
      const response = await fetch('/api/casestudies');
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      
      if (!data.success) {
        throw new Error(data.error || 'Failed to load case studies');
      }
      
      this.caseStudies = data.data || [];
      console.log(`✅ Loaded ${this.caseStudies.length} case studies`);
      
      this.renderGallery();
      this.showGalleryScreen();
      
    } catch (error) {
      console.error('❌ Error loading case studies:', error);
      this.showErrorScreen(error.message);
    } finally {
      this.isLoading = false;
    }
  }
  
  async handleRefresh() {
    console.log('🔄 Manual refresh triggered');
    
    // Disable refresh button
    const refreshBtn = this.elements.refreshBtn;
    refreshBtn.disabled = true;
    
    // Show refreshing status in header
    this.updateStatusIndicator({ isRefreshing: true });
    
    try {
      // Just reload case studies - background scanning will pick up changes
      // No need to call /api/refresh since that requires admin auth
      await this.loadCaseStudies();
      
      // Show success status briefly
      this.updateStatusIndicator({ isRefreshing: false, justRefreshed: true });
      setTimeout(() => {
        this.updateStatusIndicator({ isRefreshing: false });
      }, 2000);
      
    } catch (error) {
      console.error('❌ Error during refresh:', error);
      this.updateStatusIndicator({ error: true });
      this.showError('Failed to refresh gallery');
    } finally {
      // Re-enable button
      refreshBtn.disabled = false;
    }
  }
  
  renderGallery() {
    const grid = this.elements.galleryGrid;
    const subtitle = this.elements.gallerySubtitle;
    const emptyState = this.elements.emptyState;
    
    // Update subtitle
    const count = this.caseStudies.length;
    subtitle.textContent = count === 0 ? 'No studies found' : 
                          count === 1 ? '1 study found' : 
                          `${count} studies found`;
    
    // Clear existing content
    grid.innerHTML = '';
    
    if (count === 0) {
      emptyState.classList.remove('hidden');
      return;
    }
    
    emptyState.classList.add('hidden');
    
    // Render case study cards
    this.caseStudies.forEach(caseStudy => {
      const card = this.createCaseStudyCard(caseStudy);
      grid.appendChild(card);
    });
  }
  
  createCaseStudyCard(caseStudy) {
    const card = document.createElement('div');
    card.className = 'case-study-card';
    card.setAttribute('data-id', caseStudy.id);
    card.addEventListener('click', () => this.openModal(caseStudy.id));
    
    // Set background image if available
    if (caseStudy.imageUrl) {
      card.style.backgroundImage = `url(${caseStudy.imageUrl})`;
    }
    
    card.innerHTML = `
      <div class="card-content">
        <h3 class="card-title">${this.escapeHtml(caseStudy.title)}</h3>
        <div class="card-meta">
          Click to read
        </div>
      </div>
    `;
    
    return card;
  }
  
  async openModal(caseStudyId) {
    console.log(`📖 Opening case study: ${caseStudyId}`);
    
    const caseStudy = this.caseStudies.find(cs => cs.id === caseStudyId);
    if (!caseStudy) {
      console.error('❌ Case study not found:', caseStudyId);
      return;
    }
    
    this.currentModal = caseStudyId;
    
    // Set title immediately
    this.elements.modalTitle.textContent = caseStudy.title;
    
    // Show modal with loading state
    this.elements.modal.classList.remove('hidden');
    this.elements.modalLoading.classList.remove('hidden');
    this.elements.modalContent.classList.add('hidden');
    this.elements.modalError.classList.add('hidden');
    
    // Add to browser history
    history.pushState({ modal: caseStudyId }, '', `#${caseStudyId}`);
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden';
    
    try {
      const response = await fetch(`/api/casestudy/${caseStudyId}`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      
      if (!data.success) {
        throw new Error(data.error || 'Failed to load case study');
      }
      
      // Render markdown content
      const content = this.renderMarkdown(data.data.content);
      this.elements.modalContent.innerHTML = content;
      
      // Show content, hide loading
      this.elements.modalLoading.classList.add('hidden');
      this.elements.modalContent.classList.remove('hidden');
      
    } catch (error) {
      console.error('❌ Error loading case study:', error);
      this.elements.modalLoading.classList.add('hidden');
      this.elements.modalError.classList.remove('hidden');
    }
  }
  
  closeModal() {
    if (!this.currentModal) return;
    
    console.log('❌ Closing modal');
    
    this.elements.modal.classList.add('hidden');
    this.currentModal = null;
    
    // Restore body scroll
    document.body.style.overflow = '';
    
    // Update browser history
    if (window.location.hash) {
      history.pushState(null, '', window.location.pathname);
    }
  }
  
  renderMarkdown(content) {
    // Simple markdown renderer (you could use a library like marked.js for more features)
    return content
      .replace(/^### (.*$)/gim, '<h3>$1</h3>')
      .replace(/^## (.*$)/gim, '<h2>$1</h2>')
      .replace(/^# (.*$)/gim, '<h1>$1</h1>')
      .replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>')
      .replace(/\*(.*)\*/gim, '<em>$1</em>')
      .replace(/`([^`]+)`/gim, '<code>$1</code>')
      .replace(/```([^`]+)```/gim, '<pre><code>$1</code></pre>')
      .replace(/^\- (.*$)/gim, '<li>$1</li>')
      .replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>')
      .replace(/^\d+\. (.*$)/gim, '<li>$1</li>')
      .replace(/^> (.*$)/gim, '<blockquote>$1</blockquote>')
      .replace(/\n\n/gim, '</p><p>')
      .replace(/^(?!<[h|u|l|p|b])/gim, '<p>')
      .replace(/(?![>])$/gim, '</p>')
      .replace(/<p><\/p>/gim, '');
  }
  
  showLoadingScreen() {
    this.elements.loadingScreen.classList.remove('hidden');
    this.elements.errorScreen.classList.add('hidden');
    this.elements.galleryContainer.classList.add('hidden');
  }
  
  showErrorScreen(message) {
    this.elements.errorMessage.textContent = message || 'An unknown error occurred';
    this.elements.errorScreen.classList.remove('hidden');
    this.elements.loadingScreen.classList.add('hidden');
    this.elements.galleryContainer.classList.add('hidden');
  }
  
  showGalleryScreen() {
    this.elements.galleryContainer.classList.remove('hidden');
    this.elements.loadingScreen.classList.add('hidden');
    this.elements.errorScreen.classList.add('hidden');
  }
  
  async startStatusPolling() {
    const updateStatus = async () => {
      try {
        const response = await fetch('/api/status');
        if (response.ok) {
          const data = await response.json();
          if (data.success) {
            this.updateStatusIndicator(data.data);
          }
        }
      } catch (error) {
        console.warn('Status polling failed:', error);
        this.updateStatusIndicator({ isScanning: false, error: true });
      }
    };
    
    // Update immediately, then every 5 seconds
    await updateStatus();
    setInterval(updateStatus, 5000);
  }
  
  updateStatusIndicator(status) {
    const indicator = this.elements.statusIndicator;
    const dot = indicator.querySelector('.status-dot');
    const text = indicator.querySelector('.status-text');
    
    // Remove any existing spinner
    const existingSpinner = indicator.querySelector('.status-spinner');
    if (existingSpinner) {
      existingSpinner.remove();
    }
    
    // Show dot by default
    dot.style.display = 'block';
    
    // Reset dot classes
    dot.className = 'status-dot';
    
    if (status.isRefreshing) {
      // Hide dot and show spinner
      dot.style.display = 'none';
      const spinner = document.createElement('span');
      spinner.className = 'status-spinner';
      indicator.insertBefore(spinner, text);
      text.textContent = 'Refreshing...';
    } else if (status.justRefreshed) {
      text.textContent = 'Updated!';
    } else if (status.error) {
      dot.classList.add('error');
      text.textContent = 'Connection Error';
    } else if (status.isScanning) {
      dot.classList.add('scanning');
      text.textContent = 'Scanning...';
    } else {
      text.textContent = 'Ready';
    }
  }
  
  showError(message) {
    // Simple error notification - you could implement a toast system
    console.error('🚨', message);
    alert(message); // Temporary - replace with proper notification
  }
  
  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.galleryApp = new GalleryApp();
  });
} else {
  window.galleryApp = new GalleryApp();
}

// Handle page visibility changes for auto-refresh
document.addEventListener('visibilitychange', () => {
  if (!document.hidden && window.galleryApp && !window.galleryApp.isLoading) {
    // Auto-refresh when user returns to the page
    setTimeout(() => {
      window.galleryApp.loadCaseStudies();
    }, 1000);
  }
});
