-- Mevcut Tabloları Kontrol Et ve Sadece Eksik Olanları Ekle
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- Mevcut tabloları kontrol et ve sadece eksik olanları oluştur
DO $$ 
BEGIN
    -- user_favorites tablosu
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_favorites') THEN
        CREATE TABLE user_favorites (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
          item_type TEXT NOT NULL CHECK (item_type IN ('crop', 'marketplace_item', 'guide', 'ai_conversation')),
          item_id UUID NOT NULL,
          item_name TEXT NOT NULL,
          item_description TEXT,
          item_image_url TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          UNIQUE(user_id, item_type, item_id)
        );
        RAISE NOTICE 'user_favorites tablosu oluşturuldu';
    ELSE
        RAISE NOTICE 'user_favorites tablosu zaten mevcut';
    END IF;

    -- user_preferences tablosu
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
        CREATE TABLE user_preferences (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
          preference_key TEXT NOT NULL,
          preference_value TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          UNIQUE(user_id, preference_key)
        );
        RAISE NOTICE 'user_preferences tablosu oluşturuldu';
    ELSE
        RAISE NOTICE 'user_preferences tablosu zaten mevcut';
    END IF;

    -- user_activity_log tablosu
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_activity_log') THEN
        CREATE TABLE user_activity_log (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
          activity_type TEXT NOT NULL CHECK (activity_type IN ('crop_added', 'crop_updated', 'crop_deleted', 'favorite_added', 'favorite_removed', 'marketplace_item_added', 'ai_conversation_started', 'profile_updated')),
          activity_description TEXT NOT NULL,
          related_item_id UUID,
          related_item_type TEXT,
          metadata JSONB,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        RAISE NOTICE 'user_activity_log tablosu oluşturuldu';
    ELSE
        RAISE NOTICE 'user_activity_log tablosu zaten mevcut';
    END IF;

    -- user_notification_preferences tablosu
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_notification_preferences') THEN
        CREATE TABLE user_notification_preferences (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
          notification_type TEXT NOT NULL CHECK (notification_type IN ('harvest_reminder', 'weather_alert', 'marketplace_update', 'ai_suggestion', 'general')),
          is_enabled BOOLEAN DEFAULT true,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          UNIQUE(user_id, notification_type)
        );
        RAISE NOTICE 'user_notification_preferences tablosu oluşturuldu';
    ELSE
        RAISE NOTICE 'user_notification_preferences tablosu zaten mevcut';
    END IF;
END $$;

-- RLS'i etkinleştir (sadece yeni tablolar için)
DO $$
BEGIN
    -- user_favorites için RLS
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_favorites') THEN
        ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'user_favorites için RLS etkinleştirildi';
    END IF;

    -- user_preferences için RLS
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
        ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'user_preferences için RLS etkinleştirildi';
    END IF;

    -- user_activity_log için RLS
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_activity_log') THEN
        ALTER TABLE user_activity_log ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'user_activity_log için RLS etkinleştirildi';
    END IF;

    -- user_notification_preferences için RLS
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_notification_preferences') THEN
        ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'user_notification_preferences için RLS etkinleştirildi';
    END IF;
END $$;

-- RLS Politikalarını oluştur (sadece yoksa)
DO $$
BEGIN
    -- user_favorites politikaları
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_favorites') THEN
        -- View policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_favorites' AND policyname = 'Users can view their own favorites') THEN
            CREATE POLICY "Users can view their own favorites" ON user_favorites
              FOR SELECT USING (auth.uid() = user_id);
            RAISE NOTICE 'user_favorites view policy oluşturuldu';
        END IF;

        -- Insert policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_favorites' AND policyname = 'Users can add their own favorites') THEN
            CREATE POLICY "Users can add their own favorites" ON user_favorites
              FOR INSERT WITH CHECK (auth.uid() = user_id);
            RAISE NOTICE 'user_favorites insert policy oluşturuldu';
        END IF;

        -- Delete policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_favorites' AND policyname = 'Users can delete their own favorites') THEN
            CREATE POLICY "Users can delete their own favorites" ON user_favorites
              FOR DELETE USING (auth.uid() = user_id);
            RAISE NOTICE 'user_favorites delete policy oluşturuldu';
        END IF;
    END IF;

    -- user_preferences politikaları
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
        -- View policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_preferences' AND policyname = 'Users can view their own preferences') THEN
            CREATE POLICY "Users can view their own preferences" ON user_preferences
              FOR SELECT USING (auth.uid() = user_id);
            RAISE NOTICE 'user_preferences view policy oluşturuldu';
        END IF;

        -- Insert policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_preferences' AND policyname = 'Users can insert their own preferences') THEN
            CREATE POLICY "Users can insert their own preferences" ON user_preferences
              FOR INSERT WITH CHECK (auth.uid() = user_id);
            RAISE NOTICE 'user_preferences insert policy oluşturuldu';
        END IF;

        -- Update policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_preferences' AND policyname = 'Users can update their own preferences') THEN
            CREATE POLICY "Users can update their own preferences" ON user_preferences
              FOR UPDATE USING (auth.uid() = user_id);
            RAISE NOTICE 'user_preferences update policy oluşturuldu';
        END IF;

        -- Delete policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_preferences' AND policyname = 'Users can delete their own preferences') THEN
            CREATE POLICY "Users can delete their own preferences" ON user_preferences
              FOR DELETE USING (auth.uid() = user_id);
            RAISE NOTICE 'user_preferences delete policy oluşturuldu';
        END IF;
    END IF;

    -- user_activity_log politikaları
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_activity_log') THEN
        -- View policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_activity_log' AND policyname = 'Users can view their own activity log') THEN
            CREATE POLICY "Users can view their own activity log" ON user_activity_log
              FOR SELECT USING (auth.uid() = user_id);
            RAISE NOTICE 'user_activity_log view policy oluşturuldu';
        END IF;

        -- Insert policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_activity_log' AND policyname = 'Users can insert their own activity log') THEN
            CREATE POLICY "Users can insert their own activity log" ON user_activity_log
              FOR INSERT WITH CHECK (auth.uid() = user_id);
            RAISE NOTICE 'user_activity_log insert policy oluşturuldu';
        END IF;
    END IF;

    -- user_notification_preferences politikaları
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_notification_preferences') THEN
        -- View policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_notification_preferences' AND policyname = 'Users can view their own notification preferences') THEN
            CREATE POLICY "Users can view their own notification preferences" ON user_notification_preferences
              FOR SELECT USING (auth.uid() = user_id);
            RAISE NOTICE 'user_notification_preferences view policy oluşturuldu';
        END IF;

        -- Insert policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_notification_preferences' AND policyname = 'Users can insert their own notification preferences') THEN
            CREATE POLICY "Users can insert their own notification preferences" ON user_notification_preferences
              FOR INSERT WITH CHECK (auth.uid() = user_id);
            RAISE NOTICE 'user_notification_preferences insert policy oluşturuldu';
        END IF;

        -- Update policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_notification_preferences' AND policyname = 'Users can update their own notification preferences') THEN
            CREATE POLICY "Users can update their own notification preferences" ON user_notification_preferences
              FOR UPDATE USING (auth.uid() = user_id);
            RAISE NOTICE 'user_notification_preferences update policy oluşturuldu';
        END IF;

        -- Delete policy
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'user_notification_preferences' AND policyname = 'Users can delete their own notification preferences') THEN
            CREATE POLICY "Users can delete their own notification preferences" ON user_notification_preferences
              FOR DELETE USING (auth.uid() = user_id);
            RAISE NOTICE 'user_notification_preferences delete policy oluşturuldu';
        END IF;
    END IF;
END $$;

-- Trigger fonksiyonlarını oluştur
CREATE OR REPLACE FUNCTION update_user_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_user_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger'ları ekle (sadece yoksa)
DO $$
BEGIN
    -- user_preferences trigger
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
        IF NOT EXISTS (SELECT FROM information_schema.triggers WHERE trigger_name = 'update_user_preferences_updated_at') THEN
            CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
              FOR EACH ROW EXECUTE FUNCTION update_user_preferences_updated_at();
            RAISE NOTICE 'user_preferences trigger oluşturuldu';
        END IF;
    END IF;

    -- user_notification_preferences trigger
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_notification_preferences') THEN
        IF NOT EXISTS (SELECT FROM information_schema.triggers WHERE trigger_name = 'update_user_notification_preferences_updated_at') THEN
            CREATE TRIGGER update_user_notification_preferences_updated_at BEFORE UPDATE ON user_notification_preferences
              FOR EACH ROW EXECUTE FUNCTION update_user_notification_preferences_updated_at();
            RAISE NOTICE 'user_notification_preferences trigger oluşturuldu';
        END IF;
    END IF;
END $$;

-- İndeksleri oluştur (sadece yoksa)
DO $$
BEGIN
    -- user_favorites indeksleri
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_favorites') THEN
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_user_favorites_user_id') THEN
            CREATE INDEX idx_user_favorites_user_id ON user_favorites(user_id);
            RAISE NOTICE 'user_favorites user_id indeksi oluşturuldu';
        END IF;
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_user_favorites_item_type') THEN
            CREATE INDEX idx_user_favorites_item_type ON user_favorites(item_type);
            RAISE NOTICE 'user_favorites item_type indeksi oluşturuldu';
        END IF;
    END IF;

    -- user_preferences indeksleri
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_user_preferences_user_id') THEN
            CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);
            RAISE NOTICE 'user_preferences user_id indeksi oluşturuldu';
        END IF;
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_user_preferences_key') THEN
            CREATE INDEX idx_user_preferences_key ON user_preferences(preference_key);
            RAISE NOTICE 'user_preferences key indeksi oluşturuldu';
        END IF;
    END IF;

    -- user_activity_log indeksleri
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_activity_log') THEN
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_user_activity_log_user_id') THEN
            CREATE INDEX idx_user_activity_log_user_id ON user_activity_log(user_id);
            RAISE NOTICE 'user_activity_log user_id indeksi oluşturuldu';
        END IF;
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_user_activity_log_activity_type') THEN
            CREATE INDEX idx_user_activity_log_activity_type ON user_activity_log(activity_type);
            RAISE NOTICE 'user_activity_log activity_type indeksi oluşturuldu';
        END IF;
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_user_activity_log_created_at') THEN
            CREATE INDEX idx_user_activity_log_created_at ON user_activity_log(created_at);
            RAISE NOTICE 'user_activity_log created_at indeksi oluşturuldu';
        END IF;
    END IF;

    -- user_notification_preferences indeksleri
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_notification_preferences') THEN
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE indexname = 'idx_user_notification_preferences_user_id') THEN
            CREATE INDEX idx_user_notification_preferences_user_id ON user_notification_preferences(user_id);
            RAISE NOTICE 'user_notification_preferences user_id indeksi oluşturuldu';
        END IF;
    END IF;
END $$;

-- Varsayılan tercihleri ekleme fonksiyonu
CREATE OR REPLACE FUNCTION create_default_user_preferences(user_uuid UUID)
RETURNS VOID AS $$
BEGIN
  -- Varsayılan tercihleri ekle
  INSERT INTO user_preferences (user_id, preference_key, preference_value) VALUES
    (user_uuid, 'theme', 'light'),
    (user_uuid, 'language', 'tr'),
    (user_uuid, 'units', 'metric'),
    (user_uuid, 'city', ''),
    (user_uuid, 'notifications_enabled', 'true')
  ON CONFLICT (user_id, preference_key) DO NOTHING;
  
  -- Varsayılan bildirim tercihlerini ekle
  INSERT INTO user_notification_preferences (user_id, notification_type, is_enabled) VALUES
    (user_uuid, 'harvest_reminder', true),
    (user_uuid, 'weather_alert', true),
    (user_uuid, 'marketplace_update', false),
    (user_uuid, 'ai_suggestion', true),
    (user_uuid, 'general', true)
  ON CONFLICT (user_id, notification_type) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Kullanıcı kaydı sonrası varsayılan tercihleri oluşturma fonksiyonu
CREATE OR REPLACE FUNCTION public.handle_new_user_with_preferences()
RETURNS TRIGGER AS $$
BEGIN
  -- Profil oluştur
  INSERT INTO public.profiles (id, email, name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email))
  ON CONFLICT (id) DO NOTHING;
  
  -- Varsayılan tercihleri oluştur
  PERFORM create_default_user_preferences(NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eski trigger'ı sil ve yenisini ekle
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_with_preferences();

-- Mevcut kullanıcılar için varsayılan tercihleri oluştur
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM auth.users LOOP
        PERFORM create_default_user_preferences(user_record.id);
    END LOOP;
    RAISE NOTICE 'Mevcut kullanıcılar için varsayılan tercihler oluşturuldu';
END $$;



