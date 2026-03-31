const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
puppeteer.use(StealthPlugin());
async function test() {
    const b = await puppeteer.launch({ headless: true });
    const p = await b.newPage();
    const r = await p.goto("https://antalyakomisyonculardernegi.com/fiyatlar/");
    const html = await p.content();
    console.log(html.substring(0, 1000));
    await b.close();
}
test();
