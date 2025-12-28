-- DELETE (Silme) Politikalarını Aktifleştirme

-- 1. İlan Silme Politikası
-- Kullanıcılar sadece kendi ilanlarını silebilir
DROP POLICY IF EXISTS "Users can delete their own items" ON marketplace_items;
CREATE POLICY "Users can delete their own items"
ON marketplace_items
FOR DELETE
USING (auth.uid() = user_id);

-- 2. Mesaj Silme Politikası
-- Kullanıcılar kendi gönderdikleri VEYA aldıkları mesajları silebilir (Temizleme için)
-- Dikkat: Bu işlem mesajı veritabanından tamamen siler, diğer taraftan da silinir.
DROP POLICY IF EXISTS "Users can delete their messages" ON marketplace_messages;
CREATE POLICY "Users can delete their messages"
ON marketplace_messages
FOR DELETE
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
