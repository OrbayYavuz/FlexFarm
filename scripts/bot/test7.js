const cheerio = require('cheerio');
async function test() {
    try {
        const res = await fetch("https://guncelfiyatlari.com/antalya-hal-fiyatlari/", {
            headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" }
        });
        const html = await res.text();
        const $ = cheerio.load(html);
        let rows = 0;
        $('table tr').each((_, el) => {
            rows++;
            if (rows < 20) console.log($(el).text().replace(/\s+/g, ' ').trim());
        });
        console.log("Total rows: " + rows);
    } catch (e) {
        console.log("Error:", e.message);
    }
}
test();
