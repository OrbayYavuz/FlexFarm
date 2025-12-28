-- Supabase Dashboard'da SQL Editor'da çalıştır
-- Bu script profiles tablosundaki RLS politikalarını tamamen sıfırlar

-- 1. RLS'yi geçici olarak kapat
ALTER TABLE "public"."profiles" DISABLE ROW LEVEL SECURITY;

-- 2. TÜM politikaları sil (isim fark etmez, hepsini sil)
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'profiles' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON "public"."profiles"', policy_record.policyname);
    END LOOP;
END $$;

-- 3. Yeni politikaları oluştur
CREATE POLICY "profiles_insert_policy" ON "public"."profiles"
FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_select_policy" ON "public"."profiles"
FOR SELECT USING (true);

CREATE POLICY "profiles_update_policy" ON "public"."profiles"
FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_delete_policy" ON "public"."profiles"
FOR DELETE USING (auth.uid() = id);

-- 4. RLS'yi tekrar aktif et
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

-- 5. Sonucu kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;


