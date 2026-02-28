const https = require('https');

const urls = [
    'https://api.codetabs.com/v1/proxy?quest=https://www.halfiyatlari.net/antalya-hal-fiyatlari/',
    'https://corsproxy.io/?https://www.halfiyatlari.net/antalya-hal-fiyatlari/'
];

urls.forEach(url => {
    https.get(url, (res) => {
        console.log(`URL: ${url} | Status: ${res.statusCode}`);
        res.on('data', () => { });
    }).on('error', (e) => {
        console.error(`URL: ${url} | Error: ${e.message}`);
    });
});
