-- RLS (Row Level Security) Politikalarını Düzeltme
-- Bu kodu Supabase SQL Editor kısmına yapıştırıp 'RUN' diyerek çalıştırın.

-- 1. Tablo üzerindeki RLS'i aktifleştir
ALTER TABLE marketplace_messages ENABLE ROW LEVEL SECURITY;

-- 2. Mevcut politikaları temizle (çakışma olmaması için)
DROP POLICY IF EXISTS "Users can insert their own messages" ON marketplace_messages;
DROP POLICY IF EXISTS "Users can view their own messages" ON marketplace_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON marketplace_messages;

-- 3. Yeni INSERT politikası (Kullanıcı SADECE kendi gönderdiği mesajları ekleyebilir)
CREATE POLICY "Users can insert their own messages" 
ON marketplace_messages 
FOR INSERT 
WITH CHECK (auth.uid() = sender_id);

-- 4. Yeni SELECT politikası (Kullanıcı gönderdiği VEYA aldığı mesajları görebilir)
CREATE POLICY "Users can view their own messages" 
ON marketplace_messages 
FOR SELECT 
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- 5. Mesaj geçmişini tutabilmek için Unique Kısıtlamayı kaldır
-- (Eğer bu kısıtlama varsa, aynı kişi aynı ilana sadece 1 mesaj atabiliyordu)
ALTER TABLE marketplace_messages DROP CONSTRAINT IF EXISTS marketplace_messages_listing_id_sender_id_receiver_id_key;

-- 6. İndeksler (Sorgu hızı için)
CREATE INDEX IF NOT EXISTS idx_messages_sender_receiver ON marketplace_messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_listing_id ON marketplace_messages(listing_id);
