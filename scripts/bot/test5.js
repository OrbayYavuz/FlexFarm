const cheerio = require('cheerio');
async function test() {
    const url = encodeURIComponent('https://www.halfiyatlari.net/antalya-hal-fiyatlari/');
    const res = await fetch(`https://api.allorigins.win/get?url=${url}`);
    const data = await res.json();
    const html = data.contents;
    if (!html) console.log("No contents");
    else if (html.includes('DOMATES') || html.includes('domates')) {
        console.log("SUCCESS! found domates.");
        console.log(html.substring(0, 500));
    } else {
        console.log("Failed to find crop names. Probably Cloudflare.");
        console.log(html.substring(0, 500));
    }
}
test();
