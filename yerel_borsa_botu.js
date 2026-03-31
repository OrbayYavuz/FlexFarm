const { createClient } = require('@supabase/supabase-js');
const cheerio = require('cheerio');

// Kendi Supabase bilgilerini buraya gir
const supabaseUrl = process.env.SUPABASE_URL || 'SENIN_SUPABASE_URL_BURAYA';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'SENIN_SUPABASE_ANON_VEYA_SERVICE_KEY_BURAYA';

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

async function runScraper() {
    console.log("=== Flex Farm Yerel Borsa Botu Başlatılıyor ===");
    console.log("Türkiye IP adresi üzerinden fiyatlar çekiliyor...");

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const updates = [];

    try {
        // Senin bilgisayarina Cloudflare veya DNS engeli takilmaz.
        const response = await fetch("https://www.halfiyatlari.net/antalya-hal-fiyatlari/", {
            headers: {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"
            }
        });

        if (!response.ok) throw new Error(`HTTP Error: ${response.status}`);

        const html = await response.text();
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
                    market_name: 'Antalya Hal (Yerel Bot)',
                    last_updated: new Date().toISOString()
                });
                console.log(`✅ Kazındı: ${searchName.padEnd(12)} | Min: ₺${minPrice} Max: ₺${maxPrice}`);
            }
        }

        // TMO Sabit / Yedek Veriler
        const tmoDefaults = [
            { crop_id: 'crop_wheat', price_per_kg_min: 9.25, price_per_kg_max: 10.50, market_name: 'TMO Alım Fiyatı', last_updated: new Date().toISOString() },
            { crop_id: 'crop_barley', price_per_kg_min: 7.25, price_per_kg_max: 8.00, market_name: 'TMO Alım Fiyatı', last_updated: new Date().toISOString() },
            { crop_id: 'crop_sunflower', price_per_kg_min: 16.50, price_per_kg_max: 20.00, market_name: 'Trakya Birlik', last_updated: new Date().toISOString() },
            { crop_id: 'crop_corn', price_per_kg_min: 6.50, price_per_kg_max: 7.00, market_name: 'TMO Alım Fiyatı', last_updated: new Date().toISOString() },
            { crop_id: 'crop_tea', price_per_kg_min: 17.00, price_per_kg_max: 19.00, market_name: 'Çaykur Yaş Çay', last_updated: new Date().toISOString() }
        ];
        updates.push(...tmoDefaults);

        if (supabaseUrl.includes('supabase.co')) {
            console.log("\nSupabase sunucusuna gönderiliyor...");
            const { error } = await supabase.from('daily_crop_prices').upsert(updates, { onConflict: 'crop_id' });
            if (error) throw error;
            console.log(`🎉 Başarılı! Toplam ${updates.length} ürün güncellendi.`);
        } else {
            console.log("\n(TEST MODU) Supabase URL girilmediği için sadece ekrana yazdırıldı.");
        }

    } catch (e) {
        console.error("Hاتا Oluştu:", e.message);
    }
}

runScraper();
