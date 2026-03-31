-- Kullanıcı Aktivite Tabloları - Flex Tarm
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Favoriler tablosu
CREATE TABLE IF NOT EXISTS user_favorites (
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

-- 2. Kullanıcı tercihleri tablosu
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  preference_key TEXT NOT NULL,
  preference_value TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, preference_key)
);

-- 3. Kullanıcı aktivite geçmişi tablosu
CREATE TABLE IF NOT EXISTS user_activity_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('crop_added', 'crop_updated', 'crop_deleted', 'favorite_added', 'favorite_removed', 'marketplace_item_added', 'ai_conversation_started', 'profile_updated')),
  activity_description TEXT NOT NULL,
  related_item_id UUID,
  related_item_type TEXT,
  metadata JSONB, -- Ek bilgiler için JSON
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Kullanıcı bildirim tercihleri tablosu
CREATE TABLE IF NOT EXISTS user_notification_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('harvest_reminder', 'weather_alert', 'marketplace_update', 'ai_suggestion', 'general')),
  is_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, notification_type)
);

-- 5. RLS'i etkinleştir
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;

-- 6. RLS Politikaları

-- Favoriler için politikalar
CREATE POLICY "Users can view their own favorites" ON user_favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can add their own favorites" ON user_favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own favorites" ON user_favorites
  FOR DELETE USING (auth.uid() = user_id);

-- Tercihler için politikalar
CREATE POLICY "Users can view their own preferences" ON user_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences" ON user_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences" ON user_preferences
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own preferences" ON user_preferences
  FOR DELETE USING (auth.uid() = user_id);

-- Aktivite geçmişi için politikalar
CREATE POLICY "Users can view their own activity log" ON user_activity_log
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own activity log" ON user_activity_log
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Bildirim tercihleri için politikalar
CREATE POLICY "Users can view their own notification preferences" ON user_notification_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notification preferences" ON user_notification_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notification preferences" ON user_notification_preferences
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notification preferences" ON user_notification_preferences
  FOR DELETE USING (auth.uid() = user_id);

-- 7. Trigger fonksiyonları
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

-- Trigger'ları ekle
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
  FOR EACH ROW EXECUTE FUNCTION update_user_preferences_updated_at();

CREATE TRIGGER update_user_notification_preferences_updated_at BEFORE UPDATE ON user_notification_preferences
  FOR EACH ROW EXECUTE FUNCTION update_user_notification_preferences_updated_at();

-- 8. İndeksler (performans için)
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_item_type ON user_favorites(item_type);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_key ON user_preferences(preference_key);
CREATE INDEX IF NOT EXISTS idx_user_activity_log_user_id ON user_activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_log_activity_type ON user_activity_log(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_activity_log_created_at ON user_activity_log(created_at);
CREATE INDEX IF NOT EXISTS idx_user_notification_preferences_user_id ON user_notification_preferences(user_id);

-- 9. Varsayılan tercihleri ekleme fonksiyonu
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

-- 10. Kullanıcı kaydı sonrası varsayılan tercihleri oluşturma
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


