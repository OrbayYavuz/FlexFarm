-- BU KODU ÇALIŞTIRIN: "Duplicate Key" hatasını çözer.
-- Hatanın sebebi veritabanında 'unique_conversation' adında özel bir kısıtlama olmasıymış.
-- Bu kısıtlama, aynı kişiyle birden fazla mesajlaşmayı engelliyor. Bunu kaldırıyoruz.

ALTER TABLE marketplace_messages DROP CONSTRAINT IF EXISTS "unique_conversation";

-- Garanti olsun, standart isimli kısıtlamayı da tekrar deneyelim
ALTER TABLE marketplace_messages DROP CONSTRAINT IF EXISTS marketplace_messages_listing_id_sender_id_receiver_id_key;

-- İşlem tamamlandıktan sonra mesaj göndermeyi tekrar deneyin.
