const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const cheerio = require('cheerio');

puppeteer.use(StealthPlugin());

const CROP_SEARCH_MAP = {
    'crop_tomato': ['DOMATES', 'DOMATES (Biftek)', 'DOMATES (Salkım)'],
    'crop_cucumber': ['SALATALIK', 'SALATALIK (Slor)'],
    'crop_onion': ['SOĞAN (Kuru)', 'SOĞAN (Taze)', 'SOĞAN']
};

async function testScrape() {
    console.log("Starting LOCAL TEST scraper...");
    const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox']
    });

    const page = await browser.newPage();
    try {
        await page.goto("https://www.antalya.bel.tr/has/hal-fiyatlari", {
            waitUntil: 'networkidle2',
            timeout: 60000
        });

        console.log("Waiting 5s...");
        await new Promise(r => setTimeout(r, 5000));

        const html = await page.content();
        const $ = cheerio.load(html);

        const rows = $('table tr').get();
        console.log(`Found ${rows.length} rows in table.`);

        if (rows.length < 5) {
            console.log("HTML Sneak Peek:", html.substring(0, 500));
            console.log("Table peek:", $('table').html());
        }

        for (const [cropId, searchNames] of Object.entries(CROP_SEARCH_MAP)) {
            let minPrice = 0;
            let maxPrice = 0;
            let found = false;

            $('table tr').each((_, element) => {
                const textText = $(element).text().toUpperCase();
                const isMatch = searchNames.some(name => textText.includes(name.toUpperCase()));

                if (!found && isMatch) {
                    const cols = $(element).find('td');
                    console.log(`Match found for ${searchNames[0]}: Col count: ${cols.length}`);
                    console.log($(element).text().trim().replace(/\s+/g, ' '));
                    if (cols.length >= 4) {
                        const minStr = $(cols[2]).text().replace(/[^0-9,]/g, '').replace(',', '.');
                        const maxStr = $(cols[3]).text().replace(/[^0-9,]/g, '').replace(',', '.');
                        minPrice = parseFloat(minStr) || 0;
                        maxPrice = parseFloat(maxStr) || 0;
                        if (minPrice > 0) Object.assign(found, true);
                    }
                }
            });
            console.log(`${cropId} -> Min: ${minPrice}, Max: ${maxPrice}`);
        }
    } catch (e) {
        console.error(e);
    } finally {
        await browser.close();
    }
}
testScrape();
