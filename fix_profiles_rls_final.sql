-- Supabase Dashboard'da SQL Editor'da çalıştır
-- Bu script profiles tablosundaki RLS politikalarını düzeltir

-- 1. Mevcut politikaları kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 2. Tüm politikaları sil (yeniden oluşturmak için)
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."profiles";
DROP POLICY IF EXISTS "Enable read access for all users" ON "public"."profiles";
DROP POLICY IF EXISTS "Enable update for users based on email" ON "public"."profiles";
DROP POLICY IF EXISTS "Enable delete for users based on email" ON "public"."profiles";

-- 3. Yeni politikaları oluştur
CREATE POLICY "Enable insert for authenticated users only" ON "public"."profiles"
FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable read access for all users" ON "public"."profiles"
FOR SELECT USING (true);

CREATE POLICY "Enable update for users based on email" ON "public"."profiles"
FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Enable delete for users based on email" ON "public"."profiles"
FOR DELETE USING (auth.uid() = id);

-- 4. RLS'yi aktif et
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

-- 5. Sonucu kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';


