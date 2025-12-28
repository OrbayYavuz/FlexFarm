-- Supabase Dashboard'da SQL Editor'da çalıştır
-- Bu script profiles tablosundaki RLS politikalarını tamamen temizler ve doğru politikaları yeniden oluşturur

-- 1. Mevcut tüm politikaları sil
-- Önceki scriptte farklı isimlerle oluşturulmuş olabilecek tüm politikaları hedefliyoruz
DROP POLICY IF EXISTS "Enable delete for users based on email" ON "public"."profiles";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."profiles";
DROP POLICY IF EXISTS "Enable read access for all users" ON "public"."profiles";
DROP POLICY IF EXISTS "Enable update for users based on email" ON "public"."profiles";
DROP POLICY IF EXISTS "Users can create their own profile" ON "public"."profiles"; -- Görüntüdeki ek politika
DROP POLICY IF EXISTS "Users can update their own profile" ON "public"."profiles"; -- Görüntüdeki ek politika

-- 2. Yeni ve doğru politikaları oluştur
-- INSERT politikası: Kullanıcı sadece kendi profilini oluşturabilir
CREATE POLICY "Enable insert for authenticated users only" ON "public"."profiles"
FOR INSERT WITH CHECK (auth.uid() = id);

-- SELECT politikası: Tüm kullanıcılar tüm profilleri okuyabilir
CREATE POLICY "Enable read access for all users" ON "public"."profiles"
FOR SELECT USING (true);

-- UPDATE politikası: Kullanıcı sadece kendi profilini güncelleyebilir
CREATE POLICY "Enable update for users based on email" ON "public"."profiles"
FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- DELETE politikası: Kullanıcı sadece kendi profilini silebilir
CREATE POLICY "Enable delete for users based on email" ON "public"."profiles"
FOR DELETE USING (auth.uid() = id);

-- 3. Politikaların başarıyla oluşturulduğunu kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';


