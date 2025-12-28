-- KESİN ÇÖZÜM: Bu kodu Supabase SQL Editor'de çalıştırın.
-- Bu kod, mesaj gönderme işlemini "Yönetici Yetkisi" (Security Definer) ile yapan özel bir fonksiyon oluşturur.
-- Böylece RLS (izin) hatalarına takılmadan mesaj gönderebilirsiniz.

-- 1. Önce eski unique kısıtlamayı kaldır (Sohbet geçmişi için şart)
ALTER TABLE marketplace_messages DROP CONSTRAINT IF EXISTS marketplace_messages_listing_id_sender_id_receiver_id_key;

-- 2. Mesaj Gönderme Fonksiyonu (Yönetici Yetkili)
CREATE OR REPLACE FUNCTION send_marketplace_message(
  p_listing_id UUID,
  p_receiver_id UUID,
  p_message TEXT
) RETURNS JSONB AS $$
DECLARE
  v_inserted_id UUID;
  v_created_at TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Mesajı ekle
  INSERT INTO marketplace_messages (listing_id, sender_id, receiver_id, message, is_read)
  VALUES (p_listing_id, auth.uid(), p_receiver_id, p_message, false)
  RETURNING id, created_at INTO v_inserted_id, v_created_at;

  -- Başarılı sonucunu döndür
  RETURN jsonb_build_object('id', v_inserted_id, 'created_at', v_created_at);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Fonksiyonu kullanıma aç
GRANT EXECUTE ON FUNCTION send_marketplace_message TO authenticated;
GRANT EXECUTE ON FUNCTION send_marketplace_message TO service_role;

-- 4. Garanti olsun: Tablo RLS'ini düzelt (Okuma işlemleri için)
ALTER TABLE marketplace_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own messages" ON marketplace_messages;
CREATE POLICY "Users can view their own messages" 
ON marketplace_messages FOR SELECT 
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Insert politikasına artık gerek yok çünkü fonksiyon kullanacağız, ama yine de dursun:
DROP POLICY IF EXISTS "Users can insert their own messages" ON marketplace_messages;
CREATE POLICY "Users can insert their own messages" 
ON marketplace_messages FOR INSERT 
WITH CHECK (auth.uid() = sender_id);
