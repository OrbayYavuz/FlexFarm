-- Tabloyu Olustur
CREATE TABLE daily_crop_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_id TEXT NOT NULL UNIQUE,          -- Ornek: 'crop_tomato'
    price_per_kg_min DECIMAL(10,2) NOT NULL, -- Min Hal Fiyatı 
    price_per_kg_max DECIMAL(10,2) NOT NULL, -- Max Hal Fiyatı
    market_name TEXT DEFAULT 'Türkiye Geneli', -- Hangi Hal/Borsa
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Guvenlik (RLS - Sadece Okuma Iznı Verilecek)
ALTER TABLE daily_crop_prices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes fiyatlari okuyabilir"
ON daily_crop_prices FOR SELECT
USING (true);

-- Baslangic Test Verileri (SQL Editor'de calistirdiklarimizin gorunmesi icin)
INSERT INTO daily_crop_prices (crop_id, price_per_kg_min, price_per_kg_max) VALUES
('crop_wheat', 8.50, 10.00),
('crop_corn', 6.00, 7.50),
('crop_sunflower', 15.00, 18.00),
('crop_tomato', 12.00, 25.00),
('crop_potato', 8.00, 14.00),
('crop_onion', 7.00, 12.00),
('crop_cotton', 22.00, 26.00),
('crop_sugar_beet', 1.50, 2.00)
ON CONFLICT (crop_id) DO UPDATE 
SET price_per_kg_min = EXCLUDED.price_per_kg_min,
    price_per_kg_max = EXCLUDED.price_per_kg_max,
    last_updated = NOW();
