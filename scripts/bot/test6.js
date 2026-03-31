const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const cheerio = require('cheerio');
puppeteer.use(StealthPlugin());
async function test() {
    const b = await puppeteer.launch({ headless: true });
    const p = await b.newPage();
    await p.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    try {
        console.log("Navigating to antalya.bel.tr...");
        await p.goto("https://www.antalya.bel.tr/has/hal-fiyatlari", { waitUntil: 'load', timeout: 30000 });
        console.log("Waiting for table to appear...");
        await p.waitForSelector('table', { timeout: 15000 });
        const html = await p.content();
        console.log("Table loaded!");
        console.log(html.substring(0, 300));
        console.log("Checking for DOMATES...");
        const $ = cheerio.load(html);
        const rows = $('table tr').length;
        console.log("Rows: " + rows);
        let foundDomates = false;
        $('table tr').each((_, el) => {
            if ($(el).text().toUpperCase().includes('DOMATES')) foundDomates = true;
        });
        console.log("Found DOMATES: " + foundDomates);
    } catch (e) {
        console.log("Error:", e.message);
    } finally {
        await b.close();
    }
}
test();
