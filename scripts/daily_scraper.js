const puppeteer = require('puppeteer');
const cheerio = require('cheerio');
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error("HATA: SUPABASE_URL veya SUPABASE_SERVICE_ROLE_KEY github secrets icerisinde bulunamadi!");
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

const CROP_SEARCH_MAP = {
    'crop_tomato': 'DOMATES',
    'crop_cucumber': 'SALATALIK',
    'crop_pepper': 'BİBER',
    'crop_red_pepper': 'KAPYA',
    'crop_eggplant': 'PATLICAN',
    'crop_lettuce': 'MARUL',
    'crop_spinach': 'ISPANAK',
    'crop_potato': 'PATATES',
    'crop_onion': 'SOĞAN',
    'crop_lemon': 'LİMON',
    'crop_apple': 'ELMA',
    'crop_watermelon': 'KARPUZ',
    'crop_melon': 'KAVUN',
    'crop_carrot': 'HAVUÇ',
    'crop_cabbage': 'LAHANA',
    'crop_zucchini': 'KABAK',
    'crop_beans': 'FASULYE',
    'crop_parsley': 'MAYDANOZ',
};

async function scrapeLivePrices() {
    console.log("=== GitHub Actions Flex Farm Borsa Botu Başlatılıyor ===");
    const updates = [];
    let browser;

    try {
        // Puppeteer ile gercek bir Chrome tarayicisi baslatiliyor (Cloudflare/Anti-Bot asmak icin)
        browser = await puppeteer.launch({
            headless: "new",
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });

        const page = await browser.newPage();

        // Gercek bir kullanici gibi davranmasi icin User-Agent degistiriliyor
        await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

        console.log("halfiyatlari.net sayfasına gidiliyor...");
        await page.goto('https://www.halfiyatlari.net/antalya-hal-fiyatlari/', { waitUntil: 'networkidle2', timeout: 60000 });

        // Cloudflare javascript korumasinin gecmesi icin 3 saniye bekle
        await new Promise(r => setTimeout(r, 3000));

        const html = await page.content();
        const $ = cheerio.load(html);

        for (const [cropId, searchName] of Object.entries(CROP_SEARCH_MAP)) {
            let minPrice = 0, maxPrice = 0, found = false;

            $('table tr').each((_, element) => {
                const rowText = $(element).text().toUpperCase();
                if (!found && rowText.includes(searchName)) {
                    const cols = $(element).find('td');
                    if (cols.length >= 3) {
                        const minStr = $(cols[1]).text().replace(/[^0-9,]/g, '').replace(',', '.');
                        const maxStr = $(cols[2]).text().replace(/[^0-9,]/g, '').replace(',', '.');

                        minPrice = parseFloat(minStr) || 0;
                        maxPrice = parseFloat(maxStr) || 0;
                        if (minPrice > 0) found = true;
                    }
                }
            });

            if (found && minPrice > 0) {
                updates.push({
                    crop_id: cropId,
                    price_per_kg_min: minPrice,
                    price_per_kg_max: maxPrice > minPrice ? maxPrice : minPrice,
                    market_name: 'Antalya Hal (GitHub Bot)',
                    last_updated: new Date().toISOString()
                });
                console.log(`✅ Kazındı: ${searchName.padEnd(12)} | Min: ₺${minPrice} Max: ₺${maxPrice}`);
            }
        }

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

        console.log("\nSupabase sunucusuna gönderiliyor...");
        const { error } = await supabase.from('daily_crop_prices').upsert(updates, { onConflict: 'crop_id' });

        if (error) throw new Error("Supabase insert error: " + error.message);

        console.log(`🎉 Başarılı! Toplam ${updates.length} ürün güncellendi.`);

    } catch (e) {
        console.error("❌ Hata Oluştu:", e.message);
        process.exit(1);
    } finally {
        if (browser) await browser.close();
    }
}

scrapeLivePrices();
