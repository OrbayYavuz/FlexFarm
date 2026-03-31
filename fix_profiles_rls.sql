-- Profiles tablosu için RLS politikalarını düzelt
-- Bu script Supabase Dashboard'da SQL Editor'da çalıştırılmalı

-- Önce mevcut politikaları kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- Profiles tablosu için INSERT politikası ekle (eğer yoksa)
DO $$
BEGIN
    -- INSERT politikası yoksa ekle
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Enable insert for authenticated users only'
    ) THEN
        CREATE POLICY "Enable insert for authenticated users only" ON "public"."profiles"
        FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
    
    -- SELECT politikası yoksa ekle
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Enable read access for all users'
    ) THEN
        CREATE POLICY "Enable read access for all users" ON "public"."profiles"
        FOR SELECT USING (true);
    END IF;
    
    -- UPDATE politikası yoksa ekle
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Enable update for users based on email'
    ) THEN
        CREATE POLICY "Enable update for users based on email" ON "public"."profiles"
        FOR UPDATE USING (auth.uid() = id);
    END IF;
    
    -- DELETE politikası yoksa ekle
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Enable delete for users based on email'
    ) THEN
        CREATE POLICY "Enable delete for users based on email" ON "public"."profiles"
        FOR DELETE USING (auth.uid() = id);
    END IF;
END $$;

-- RLS'nin aktif olduğundan emin ol
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

-- Politikaları tekrar kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';


