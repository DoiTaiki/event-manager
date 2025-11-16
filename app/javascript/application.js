// Entry point for the build script in your package.json
import '@hotwired/turbo-rails';
import './controllers';
import React, { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './components/App';

let reactRoot = null;
let isInitialized = false;
let turboListenersSetup = false;

/**
 * Cleans up the React root instance to prevent memory leaks
 */
function cleanupReact() {
  if (reactRoot) {
    try {
      reactRoot.unmount();
    } catch (error) {
      console.warn('Error during React root unmount:', error);
    }
    reactRoot = null;
  }
  isInitialized = false;
}

/**
 * Initializes the React application
 * Prevents duplicate initialization and handles errors gracefully
 */
function initializeReact() {
  // Prevent duplicate initialization
  if (isInitialized) {
    return;
  }

  const container = document.getElementById('root');
  if (!container) {
    console.error('Root element with id "root" not found');
    return;
  }

  try {
    reactRoot = createRoot(container);
    reactRoot.render(
      <StrictMode>
        <App />
      </StrictMode>,
    );
    isInitialized = true;
  } catch (error) {
    console.error('Failed to initialize React application:', error);
    cleanupReact();
  }
}

// Setup Turbo event listeners (only once to prevent duplicates)
if (!turboListenersSetup) {
  document.addEventListener('turbo:before-cache', cleanupReact);
  document.addEventListener('turbo:load', initializeReact);
  turboListenersSetup = true;
}

// Handle initial page load for non-Turbo navigation
// Turbo-enabled pages will be initialized via turbo:load event
if (typeof Turbo === 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeReact, { once: true });
  } else {
    initializeReact();
  }
}
