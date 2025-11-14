// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import React from 'react';
import { createRoot } from 'react-dom/client';
import HelloMessage from './components/App';

// Track React root instance to prevent memory leaks
let reactRoot = null;

function cleanupReact() {
  if (reactRoot) {
    reactRoot.unmount();
    reactRoot = null;
  }
}

function initializeReact() {
  const container = document.getElementById('root');
  
  if (!container) {
    console.error('Root element not found');
    return;
  }
  
  // Clean up any existing root before creating a new one
  cleanupReact();
  
  reactRoot = createRoot(container);
  reactRoot.render(<HelloMessage name="World" />);
}

// Clean up React root before Turbo caches the page
document.addEventListener('turbo:before-cache', cleanupReact);

// Initialize React on Turbo page loads
document.addEventListener('turbo:load', initializeReact);

// Handle initial page load (for non-Turbo navigation or first load)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeReact);
} else {
  // DOMContentLoaded has already fired, execute immediately
  initializeReact();
}
