const { createClient } = require('@supabase/supabase-js');
const cheerio = require('cheerio');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables.");
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// guncelfiyatlari.com arama isimleri
const CROP_SEARCH_MAP = {
    'crop_tomato': ['DOMATES', 'DOMATES (Ceri)', 'DOMATES Ceri', 'DOMATES (Pembe)'],
    'crop_cucumber': ['HIYAR', 'SALATALIK', 'Hıyar', 'Slor'],
    'crop_pepper': ['Biber Sivri', 'Biber Çarli', 'Biber (Dolma)', 'Biber Üçburun'],
    'crop_red_pepper': ['Biber Kapya'],
    'crop_eggplant': ['PATLICAN'],
    'crop_lettuce': ['MARUL', 'Marul Düz', 'Marul Kıvırcık', 'Aysberg'],
    'crop_spinach': ['ISPANAK'],
    'crop_potato': ['PATATES'],
    'crop_onion': ['SOĞAN'],
    'crop_lemon': ['LİMON'],
    'crop_apple': ['ELMA'],
    'crop_watermelon': ['KARPUZ'],
    'crop_melon': ['KAVUN'],
    'crop_carrot': ['HAVUÇ'],
    'crop_cabbage': ['LAHANA'],
    'crop_zucchini': ['KABAK'],
    'crop_beans': ['FASULYE'],
    'crop_parsley': ['MAYDANOZ'],
};

async function scrape() {
    console.log("Starting FAST FETCH scraper (guncelfiyatlari.com)...");

    try {
        const response = await fetch("https://guncelfiyatlari.com/antalya-hal-fiyatlari/", {
            headers: {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            }
        });

        if (!response.ok) {
            throw new Error(`Failed to fetch HTTP: ${response.status}`);
        }

        const html = await response.text();
        const $ = cheerio.load(html);

        const updates = [];
        console.log("Parsing tables...");

        for (const [cropId, searchNames] of Object.entries(CROP_SEARCH_MAP)) {
            let minPrice = 0;
            let maxPrice = 0;
            let found = false;

            $('table tr').each((_, element) => {
                const textText = $(element).text().toUpperCase();

                const isMatch = searchNames.some(name => textText.includes(name.toUpperCase()));

                if (!found && isMatch) {
                    const cols = $(element).find('td');
                    if (cols.length >= 2) {
                        // Sütunlar bazen (Ürün, Birim, En Düşük, En Yüksek) bazen de direkt (Ürün, En Düşük, En Yüksek)
                        // Fiyat içeren sütunları sondan alalım.
                        const lastCol = $(cols[cols.length - 1]).text().replace(/[^0-9,]/g, '').replace(',', '.');
                        const prevCol = $(cols[cols.length - 2]).text().replace(/[^0-9,]/g, '').replace(',', '.');

                        // Fiyatlar
                        let p1 = parseFloat(prevCol);
                        let p2 = parseFloat(lastCol);

                        if (!p1 && !p2 && cols.length >= 4) {
                            p1 = parseFloat($(cols[2]).text().replace(/[^0-9,]/g, '').replace(',', '.'));
                            p2 = parseFloat($(cols[3]).text().replace(/[^0-9,]/g, '').replace(',', '.'));
                        }

                        if (p1 > 0 || p2 > 0) {
                            minPrice = p1 > 0 ? p1 : p2;
                            maxPrice = p2 > 0 ? Math.max(p1, p2) : minPrice;
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
                    market_name: 'Antalya Hal (Scraped)',
                    last_updated: new Date().toISOString()
                });
                console.log(`Scraped ${searchNames[0]}: Min ₺${minPrice}, Max ₺${maxPrice}`);
            }
        }

        console.log(`Successfully parsed ${updates.length} items from the site.`);

        // TMO
        const tmoDefaults = [
            { crop_id: 'crop_wheat', price_per_kg_min: 9.25, price_per_kg_max: 10.50, market_name: 'TMO Alım Fiyatı', last_updated: new Date().toISOString() },
            { crop_id: 'crop_barley', price_per_kg_min: 7.25, price_per_kg_max: 8.00, market_name: 'TMO Alım Fiyatı', last_updated: new Date().toISOString() },
            { crop_id: 'crop_sunflower', price_per_kg_min: 16.50, price_per_kg_max: 20.00, market_name: 'Trakya Birlik', last_updated: new Date().toISOString() },
            { crop_id: 'crop_corn', price_per_kg_min: 6.50, price_per_kg_max: 7.00, market_name: 'TMO Alım Fiyatı', last_updated: new Date().toISOString() },
            { crop_id: 'crop_tea', price_per_kg_min: 17.00, price_per_kg_max: 19.00, market_name: 'Çaykur Yaş Çay', last_updated: new Date().toISOString() },
            { crop_id: 'crop_cotton', price_per_kg_min: 22.00, price_per_kg_max: 25.00, market_name: 'Çukobirlik', last_updated: new Date().toISOString() },
            { crop_id: 'crop_sugar_beet', price_per_kg_min: 1.85, price_per_kg_max: 2.15, market_name: 'Türkşeker', last_updated: new Date().toISOString() },
        ];
        updates.push(...tmoDefaults);

        // Fallbacks for fruits without proper scraped value
        const fallbackFruits = [
            { crop_id: 'crop_olive', price_per_kg_min: 90.00, price_per_kg_max: 140.00, market_name: 'Ege Ortalama', last_updated: new Date().toISOString() },
            { crop_id: 'crop_cherry', price_per_kg_min: 40.00, price_per_kg_max: 80.00, market_name: 'Türkiye Ort.', last_updated: new Date().toISOString() },
            { crop_id: 'crop_apricot', price_per_kg_min: 25.00, price_per_kg_max: 40.00, market_name: 'Malatya Ort.', last_updated: new Date().toISOString() },
            { crop_id: 'crop_hazelnut', price_per_kg_min: 115.00, price_per_kg_max: 135.00, market_name: 'Ordu Ort.', last_updated: new Date().toISOString() },
            { crop_id: 'crop_pistachio', price_per_kg_min: 280.00, price_per_kg_max: 380.00, market_name: 'Gaziantep Ort.', last_updated: new Date().toISOString() }
        ].filter(f => !updates.some(u => u.crop_id === f.crop_id));

        updates.push(...fallbackFruits);

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
    }
}

scrape();
