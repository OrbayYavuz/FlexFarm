const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const { createClient } = require('@supabase/supabase-js');
const cheerio = require('cheerio');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

puppeteer.use(StealthPlugin());

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables.");
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Antalya Belediyesi Hal Fiyatları Map'i
const CROP_SEARCH_MAP = {
    'crop_tomato': ['DOMATES', 'DOMATES (Biftek)', 'DOMATES (Salkım)'],
    'crop_cucumber': ['SALATALIK', 'SALATALIK (Slor)'],
    'crop_pepper': ['BİBER (Sivri)', 'BİBER (Çarliston)', 'BİBER (Sivri Kıl)'],
    'crop_red_pepper': ['BİBER (Kapya)', 'BİBER (Kırmızı)'],
    'crop_eggplant': ['PATLICAN', 'PATLICAN (Sivri)'],
    'crop_lettuce': ['MARUL (Düz)', 'MARUL (Kıvırcık)', 'MARUL'],
    'crop_spinach': ['ISPANAK'],
    'crop_potato': ['PATATES'],
    'crop_onion': ['SOĞAN (Kuru)', 'SOĞAN (Taze)'],
    'crop_lemon': ['LİMON'],
    'crop_apple': ['ELMA'],
    'crop_watermelon': ['KARPUZ'],
    'crop_melon': ['KAVUN'],
    'crop_carrot': ['HAVUÇ'],
    'crop_cabbage': ['LAHANA (Beyaz)', 'LAHANA'],
    'crop_zucchini': ['KABAK (Bal)', 'KABAK'],
    'crop_beans': ['FASULYE (Sırık)', 'FASULYE'],
    'crop_parsley': ['MAYDANOZ'],
};

async function scrape() {
    console.log("Starting DIRECT OFFICIAL scraper...");

    const browser = await puppeteer.launch({
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-web-security',
            '--disable-features=IsolateOrigins,site-per-process'
        ]
    });

    const page = await browser.newPage();

    // Rastgele fakat inandirici bir User Agent
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    try {
        console.log("Navigating to Official Antalya Municipality Hal Fiyatlari API...");

        // Antalya Büyükşehir Belediyesi Hal Kayıt Sisteminin (veya bilinen diğer apilerin) 
        // bot koruması olmayan en güncel ve risksiz verisi: Tarım Orman Bakanlığı Hal Sistemi / Belediyesi
        // NOT: Belediyenin tablosu dinamiktir, Javascript render eder. Timeout'u yüksek tutuyoruz.
        await page.goto("https://www.antalya.bel.tr/has/hal-fiyatlari", {
            waitUntil: 'networkidle2',
            timeout: 60000
        });

        console.log("Page loaded. Waiting for table to render...");

        // Tablo yüklenmesini 5 saniye bekle
        await new Promise(r => setTimeout(r, 5000));

        const html = await page.content();
        const $ = cheerio.load(html);

        const updates = [];
        console.log("Parsing tables...");

        for (const [cropId, searchNames] of Object.entries(CROP_SEARCH_MAP)) {
            let minPrice = 0;
            let maxPrice = 0;
            let found = false;

            $('table tr').each((_, element) => {
                const textText = $(element).text().toUpperCase();

                // Eğer ürün bu satırda varsa (herhangi bir alt varyantına uyuyorsa)
                const isMatch = searchNames.some(name => textText.includes(name.toUpperCase()));

                if (!found && isMatch) {
                    const cols = $(element).find('td');
                    // Antalya.bel.tr formatı genellikle 1. sütun Ürün Adı, 2. Unitesi, 3. En Düşük, 4. En Yüksek
                    // Biz olası fiyat sütunlarına bakıyoruz
                    if (cols.length >= 4) {
                        const minStr = $(cols[2]).text().replace(/[^0-9,]/g, '').replace(',', '.');
                        const maxStr = $(cols[3]).text().replace(/[^0-9,]/g, '').replace(',', '.');

                        minPrice = parseFloat(minStr) || 0;
                        maxPrice = parseFloat(maxStr) || 0;

                        if (minPrice > 0) {
                            found = true;
                        }
                    }
                }
            });

            if (found && minPrice > 0) {
                updates.push({
                    crop_id: cropId,
                    price_per_kg_min: minPrice,
                    price_per_kg_max: maxPrice > minPrice ? maxPrice : minPrice,
                    market_name: 'Antalya BB Resmi Verisi',
                    last_updated: new Date().toISOString()
                });
                console.log(`Scraped ${searchNames[0]}: Min ₺${minPrice}, Max ₺${maxPrice}`);
            }
        }

        console.log(`Successfully parsed ${updates.length} dynamic items from the site.`);

        // TMO
        const tmoDefaults = [
            { crop_id: 'crop_wheat', price_per_kg_min: 9.25, price_per_kg_max: 10.50, market_name: 'TMO Alım Fiyatı' },
            { crop_id: 'crop_barley', price_per_kg_min: 7.25, price_per_kg_max: 8.00, market_name: 'TMO Alım Fiyatı' },
            { crop_id: 'crop_sunflower', price_per_kg_min: 16.50, price_per_kg_max: 20.00, market_name: 'Trakya Birlik' },
            { crop_id: 'crop_corn', price_per_kg_min: 6.50, price_per_kg_max: 7.00, market_name: 'TMO Alım Fiyatı' },
            { crop_id: 'crop_tea', price_per_kg_min: 17.00, price_per_kg_max: 19.00, market_name: 'Çaykur Yaş Çay' },
            { crop_id: 'crop_cotton', price_per_kg_min: 22.00, price_per_kg_max: 25.00, market_name: 'Çukobirlik' },
            { crop_id: 'crop_sugar_beet', price_per_kg_min: 1.85, price_per_kg_max: 2.15, market_name: 'Türkşeker' },
        ];
        updates.push(...tmoDefaults);

        // Fallbacks for fruits without proper scraped value
        const fallbackFruits = [
            { crop_id: 'crop_olive', price_per_kg_min: 90.00, price_per_kg_max: 140.00, market_name: 'Ege Ortalama' },
            { crop_id: 'crop_cherry', price_per_kg_min: 40.00, price_per_kg_max: 80.00, market_name: 'Türkiye Ort.' },
            { crop_id: 'crop_apricot', price_per_kg_min: 25.00, price_per_kg_max: 40.00, market_name: 'Malatya Ort.' },
            { crop_id: 'crop_hazelnut', price_per_kg_min: 115.00, price_per_kg_max: 135.00, market_name: 'Ordu Ort.' },
            { crop_id: 'crop_pistachio', price_per_kg_min: 280.00, price_per_kg_max: 380.00, market_name: 'Gaziantep Ort.' }
        ].filter(f => !updates.some(u => u.crop_id === f.crop_id));

        updates.push(...fallbackFruits.map(item => ({ ...item, last_updated: new Date().toISOString() })));

        if (updates.length > 0) {
            console.log(`Pushing ${updates.length} updates to Supabase...`);
            const { error } = await supabase
                .from('daily_crop_prices')
                .upsert(updates, { onConflict: 'crop_id' });

            if (error) {
                console.error("Database Update Error:", error);
            } else {
                console.log("Successfully updated Supabase!");
            }
        }

    } catch (e) {
        console.error("Scraper encountered an error:", e);
    } finally {
        await browser.close();
        console.log("Browser closed. Exiting process.");
        setTimeout(() => process.exit(0), 1000);
    }
}

scrape();
