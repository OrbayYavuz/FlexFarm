-- Database Duplicate Key Sorununu Çöz
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Mevcut duplicate kayıtları temizle
DELETE FROM user_preferences 
WHERE id IN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
      PARTITION BY user_id, preference_key 
      ORDER BY created_at DESC
    ) as rn
    FROM user_preferences
  ) t 
  WHERE rn > 1
);

-- 2. Unique constraint'i yeniden oluştur (eğer yoksa)
DO $$
BEGIN
    -- Constraint'i sil (eğer varsa)
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'user_preferences_user_id_preference_key_key'
    ) THEN
        ALTER TABLE user_preferences 
        DROP CONSTRAINT user_preferences_user_id_preference_key_key;
    END IF;
    
    -- Yeni constraint ekle
    ALTER TABLE user_preferences 
    ADD CONSTRAINT user_preferences_user_id_preference_key_key 
    UNIQUE (user_id, preference_key);
    
    RAISE NOTICE 'Unique constraint yeniden oluşturuldu';
END $$;

-- 3. Mevcut kullanıcılar için varsayılan tercihleri kontrol et ve düzelt
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM auth.users LOOP
        -- City tercihini kontrol et ve düzelt
        IF EXISTS (
            SELECT 1 FROM user_preferences 
            WHERE user_id = user_record.id AND preference_key = 'city'
        ) THEN
            -- Mevcut city tercihini güncelle
            UPDATE user_preferences 
            SET preference_value = '', updated_at = NOW()
            WHERE user_id = user_record.id AND preference_key = 'city';
        ELSE
            -- Yeni city tercihi ekle
            INSERT INTO user_preferences (user_id, preference_key, preference_value, created_at, updated_at)
            VALUES (user_record.id, 'city', '', NOW(), NOW());
        END IF;
        
        -- Diğer varsayılan tercihleri kontrol et
        INSERT INTO user_preferences (user_id, preference_key, preference_value, created_at, updated_at)
        VALUES 
            (user_record.id, 'theme', 'light', NOW(), NOW()),
            (user_record.id, 'language', 'tr', NOW(), NOW()),
            (user_record.id, 'units', 'metric', NOW(), NOW()),
            (user_record.id, 'notifications_enabled', 'true', NOW(), NOW())
        ON CONFLICT (user_id, preference_key) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'Kullanıcı tercihleri düzeltildi';
END $$;

-- 4. Tablo istatistiklerini güncelle
ANALYZE user_preferences;



