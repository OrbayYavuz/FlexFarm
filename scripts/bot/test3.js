const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const cheerio = require('cheerio');
puppeteer.use(StealthPlugin());
async function test() {
    const b = await puppeteer.launch({ headless: true });
    const p = await b.newPage();
    await p.goto("https://antalyakomisyonculardernegi.com/fiyatlar/");
    await new Promise(r => setTimeout(r, 2000));
    const html = await p.content();
    const $ = cheerio.load(html);
    $('table tr').each((i, el) => {
        console.log($(el).text().replace(/\s+/g, ' '));
    });
    await b.close();
}
test();
