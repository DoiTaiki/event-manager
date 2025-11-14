// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import React, { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './components/App';
// Track React root instance to prevent memory leaks
let reactRoot = null;
let isInitialized = false;

function cleanupReact() {
  if (reactRoot) {
    reactRoot.unmount();
    reactRoot = null;
  }
  isInitialized = false;
}

function initializeReact() {
  // Prevent duplicate initialization
  if (isInitialized) {
    return;
  }

  const container = document.getElementById('root');

  if (!container) {
    console.error('Root element not found');
    return;
  }

  // Clean up any existing root before creating a new one
  cleanupReact();

  reactRoot = createRoot(container);
  reactRoot.render(
    <StrictMode>
      <App />
    </StrictMode>
  );

  isInitialized = true;
}

// Clean up React root before Turbo caches the page
document.addEventListener('turbo:before-cache', cleanupReact);

// Initialize React on Turbo page loads (including initial load)
document.addEventListener('turbo:load', initializeReact);

// Handle initial page load for non-Turbo navigation
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeReact);
} else {
  // DOMContentLoaded has already fired, but wait for turbo:load if Turbo is enabled
  // If Turbo is not enabled, initialize immediately
  if (typeof Turbo === 'undefined') {
    initializeReact();
  }
}
