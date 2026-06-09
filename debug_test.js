const express = require('express');
const puppeteer = require('puppeteer');

async function run() {
  const app = express();
  const staticPath = './build/browser';
  app.use(express.static(staticPath));
  
  const server = app.listen(3002, async () => {
    console.log(`Server started at http://localhost:3002`);
    
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();
    
    page.on('requestfailed', request => {
      console.error(`❌ Request failed: ${request.url()} - ${request.failure().errorText}`);
    });
    
    page.on('console', msg => {
      const type = msg.type();
      console.log(`[console.${type}] ${msg.text()}`);
    });
    
    page.on('pageerror', err => {
      console.error(`❌ Page Error:`, err);
    });
    
    try {
      console.log('Navigating to http://localhost:3002/test/index.html...');
      await page.goto('http://localhost:3002/test/index.html', { waitUntil: 'load' });
      console.log('Page loaded. Waiting for console outputs...');
      await new Promise(resolve => setTimeout(resolve, 2000));
    } catch (e) {
      console.error('Error during execution:', e);
    } finally {
      await browser.close();
      server.close();
      console.log('Server stopped.');
    }
  });
}

run();
