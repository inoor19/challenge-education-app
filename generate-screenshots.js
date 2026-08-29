#!/usr/bin/env node

/**
 * Generate PNG screenshots from HTML mockups
 * Run with: node generate-screenshots.js
 *
 * Requires: npm install puppeteer
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

const SCREENSHOTS_DIR = './screenshots';
const HTML_FILE = './screenshots-mockup.html';
const VIEWPORT = { width: 1080, height: 1920 };

// Screenshot configurations
const screenshots = [
    { name: '01_login_screen.png', selector: '.screenshot:nth-child(1)', title: 'Login Screen' },
    { name: '02_home_dashboard.png', selector: '.screenshot:nth-child(2)', title: 'Home Dashboard' },
    { name: '03_challenge_setup.png', selector: '.screenshot:nth-child(3)', title: 'Challenge Setup' },
    { name: '04_live_quiz.png', selector: '.screenshot:nth-child(4)', title: 'Live Quiz' },
    { name: '05_results_screen.png', selector: '.screenshot:nth-child(5)', title: 'Results' },
    { name: '06_leaderboard.png', selector: '.screenshot:nth-child(6)', title: 'Leaderboard' },
    { name: '07_team_screen.png', selector: '.screenshot:nth-child(7)', title: 'Team Screen' },
    { name: '08_settings.png', selector: '.screenshot:nth-child(8)', title: 'Settings' },
];

async function generateScreenshots() {
    console.log('📱 Generating App Screenshots...\n');

    // Create screenshots directory
    if (!fs.existsSync(SCREENSHOTS_DIR)) {
        fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });
        console.log(`✅ Created directory: ${SCREENSHOTS_DIR}\n`);
    }

    // Launch browser
    const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    try {
        const page = await browser.newPage();

        // Set viewport
        await page.setViewport(VIEWPORT);

        // Load HTML file
        const htmlPath = `file://${path.resolve(HTML_FILE)}`;
        console.log(`Loading: ${htmlPath}\n`);
        await page.goto(htmlPath, { waitUntil: 'networkidle0' });

        // Generate each screenshot
        for (const screenshot of screenshots) {
            try {
                const element = await page.$(screenshot.selector);

                if (element) {
                    const outputPath = path.join(SCREENSHOTS_DIR, screenshot.name);

                    // Take screenshot
                    await element.screenshot({
                        path: outputPath,
                        omitBackground: false
                    });

                    const fileSize = fs.statSync(outputPath).size / 1024; // KB
                    console.log(`✅ Generated: ${screenshot.name}`);
                    console.log(`   Title: ${screenshot.title}`);
                    console.log(`   Size: ${fileSize.toFixed(2)} KB`);
                    console.log(`   Path: ${outputPath}\n`);
                } else {
                    console.error(`❌ Could not find element: ${screenshot.selector}`);
                }
            } catch (error) {
                console.error(`❌ Error generating ${screenshot.name}:`, error.message);
            }
        }

        console.log('\n✅ All screenshots generated successfully!\n');
        console.log('📁 Screenshots saved in: ./screenshots/\n');
        console.log('📋 Next steps:');
        console.log('1. Review the PNG files in ./screenshots/ folder');
        console.log('2. Go to Google Play Console');
        console.log('3. Upload all 8 PNG files to Store Listing > Screenshots');
        console.log('4. Fill store listing with content from GOOGLE_PLAY_READY_TO_PASTE.md');
        console.log('5. Submit for review\n');

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await browser.close();
    }
}

// Run
console.log('╔════════════════════════════════════════════╗');
console.log('║  Challenge Education - Screenshot Generator║');
console.log('╚════════════════════════════════════════════╝\n');

generateScreenshots().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
});
