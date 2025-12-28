-- Marketplace ve Mesajlaşma Sistemi Database Migration
-- Bu dosyayı Supabase SQL Editor'da çalıştırın
-- Mevcut marketplace_items tablosunu genişletir ve mesajlaşma sistemi ekler

-- 1. marketplace_items tablosunu güncelle (eğer eksik kolonlar varsa)
DO $$
BEGIN
    -- city kolonu ekle (konum için)
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'marketplace_items' AND column_name = 'city') THEN
        ALTER TABLE marketplace_items ADD COLUMN city TEXT;
        RAISE NOTICE 'marketplace_items.city kolonu eklendi';
    END IF;

    -- quantity kolonu ekle (miktar için)
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'marketplace_items' AND column_name = 'quantity') THEN
        ALTER TABLE marketplace_items ADD COLUMN quantity TEXT;
        RAISE NOTICE 'marketplace_items.quantity kolonu eklendi';
    END IF;

    -- unit kolonu ekle (birim: kg, ton, adet vb.)
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'marketplace_items' AND column_name = 'unit') THEN
        ALTER TABLE marketplace_items ADD COLUMN unit TEXT DEFAULT 'adet';
        RAISE NOTICE 'marketplace_items.unit kolonu eklendi';
    END IF;

    -- contact_phone kolonu ekle (iletişim için)
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'marketplace_items' AND column_name = 'contact_phone') THEN
        ALTER TABLE marketplace_items ADD COLUMN contact_phone TEXT;
        RAISE NOTICE 'marketplace_items.contact_phone kolonu eklendi';
    END IF;
END $$;

-- Foreign key constraint'i kontrol et ve ekle (profiles ile ilişki için)
DO $$
BEGIN
    -- Eğer foreign key yoksa ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'marketplace_items_user_id_fkey' 
        AND table_name = 'marketplace_items'
    ) THEN
        -- Önce mevcut foreign key'i kontrol et (auth.users'a)
        -- Eğer varsa, profiles'e de foreign key ekle
        ALTER TABLE marketplace_items 
        ADD CONSTRAINT marketplace_items_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
        RAISE NOTICE 'marketplace_items_user_id_fkey foreign key eklendi';
    ELSE
        RAISE NOTICE 'marketplace_items_user_id_fkey foreign key zaten mevcut';
    END IF;
END $$;

-- 2. Mesajlaşma tablosu oluştur
CREATE TABLE IF NOT EXISTS marketplace_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    listing_id UUID REFERENCES marketplace_items(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Aynı listing için aynı iki kullanıcı arasında tek bir konuşma olmalı
    CONSTRAINT unique_conversation UNIQUE (listing_id, sender_id, receiver_id)
);

-- 3. RLS'i etkinleştir
ALTER TABLE marketplace_messages ENABLE ROW LEVEL SECURITY;

-- 4. Mesajlaşma için RLS politikaları
DO $$
BEGIN
    -- Mesajları görüntüleme: Sadece gönderen veya alan görebilir
    IF NOT EXISTS (SELECT FROM pg_policies 
                   WHERE tablename = 'marketplace_messages' 
                   AND policyname = 'Users can view their own messages') THEN
        CREATE POLICY "Users can view their own messages" ON marketplace_messages
            FOR SELECT USING (
                auth.uid() = sender_id OR auth.uid() = receiver_id
            );
        RAISE NOTICE 'marketplace_messages view policy oluşturuldu';
    END IF;

    -- Mesaj gönderme: Herkes ilan sahibine mesaj gönderebilir
    IF NOT EXISTS (SELECT FROM pg_policies 
                   WHERE tablename = 'marketplace_messages' 
                   AND policyname = 'Users can send messages') THEN
        CREATE POLICY "Users can send messages" ON marketplace_messages
            FOR INSERT WITH CHECK (
                auth.uid() = sender_id AND
                -- İlan sahibi kendisine mesaj gönderemez
                sender_id != receiver_id
            );
        RAISE NOTICE 'marketplace_messages insert policy oluşturuldu';
    END IF;

    -- Mesaj okundu işaretleme: Sadece alıcı işaretleyebilir
    IF NOT EXISTS (SELECT FROM pg_policies 
                   WHERE tablename = 'marketplace_messages' 
                   AND policyname = 'Receivers can mark messages as read') THEN
        CREATE POLICY "Receivers can mark messages as read" ON marketplace_messages
            FOR UPDATE USING (auth.uid() = receiver_id);
        RAISE NOTICE 'marketplace_messages update policy oluşturuldu';
    END IF;

    -- Mesaj silme: Sadece gönderen silebilir (veya alıcı kendi mesajlarını)
    IF NOT EXISTS (SELECT FROM pg_policies 
                   WHERE tablename = 'marketplace_messages' 
                   AND policyname = 'Users can delete their own messages') THEN
        CREATE POLICY "Users can delete their own messages" ON marketplace_messages
            FOR DELETE USING (auth.uid() = sender_id);
        RAISE NOTICE 'marketplace_messages delete policy oluşturuldu';
    END IF;
END $$;

-- 5. marketplace_items için güvenlik politikalarını kontrol et ve güncelle
DO $$
BEGIN
    -- Sadece ilan sahibi düzenleyebilir kontrolü
    IF NOT EXISTS (SELECT FROM pg_policies 
                   WHERE tablename = 'marketplace_items' 
                   AND policyname = 'Users can update their own items') THEN
        CREATE POLICY "Users can update their own items" ON marketplace_items
            FOR UPDATE USING (auth.uid() = user_id);
        RAISE NOTICE 'marketplace_items update policy oluşturuldu';
    END IF;

    -- Sadece ilan sahibi silebilir kontrolü
    IF NOT EXISTS (SELECT FROM pg_policies 
                   WHERE tablename = 'marketplace_items' 
                   AND policyname = 'Users can delete their own items') THEN
        CREATE POLICY "Users can delete their own items" ON marketplace_items
            FOR DELETE USING (auth.uid() = user_id);
        RAISE NOTICE 'marketplace_items delete policy oluşturuldu';
    END IF;
END $$;

-- 6. Performans için indeksler oluştur
CREATE INDEX IF NOT EXISTS idx_marketplace_items_is_available 
    ON marketplace_items(is_available) WHERE is_available = true;

CREATE INDEX IF NOT EXISTS idx_marketplace_items_category 
    ON marketplace_items(category);

CREATE INDEX IF NOT EXISTS idx_marketplace_items_city 
    ON marketplace_items(city) WHERE city IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_marketplace_items_created_at 
    ON marketplace_items(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_marketplace_messages_listing_id 
    ON marketplace_messages(listing_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_messages_sender_id 
    ON marketplace_messages(sender_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_messages_receiver_id 
    ON marketplace_messages(receiver_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_messages_created_at 
    ON marketplace_messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_marketplace_messages_is_read 
    ON marketplace_messages(is_read) WHERE is_read = false;

-- 7. Mesaj sayısı için view oluştur (performans için)
CREATE OR REPLACE VIEW marketplace_listing_stats AS
SELECT 
    listing_id,
    COUNT(*) as message_count,
    COUNT(*) FILTER (WHERE is_read = false) as unread_count
FROM marketplace_messages
GROUP BY listing_id;

-- 8. Trigger: Mesaj gönderildiğinde updated_at güncelle (eğer yoksa)
CREATE OR REPLACE FUNCTION update_marketplace_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_marketplace_items_updated_at ON marketplace_items;
CREATE TRIGGER update_marketplace_items_updated_at
    BEFORE UPDATE ON marketplace_items
    FOR EACH ROW
    EXECUTE FUNCTION update_marketplace_items_updated_at();

-- Migration tamamlandı mesajı
DO $$
BEGIN
    RAISE NOTICE 'Marketplace migration tamamlandı!';
END $$;

