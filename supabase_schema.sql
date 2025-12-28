-- Supabase Veritabanı Şeması
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın

-- Kullanıcı profilleri tablosu
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Kullanıcı API anahtarları tablosu (şifrelenmiş)
CREATE TABLE IF NOT EXISTS user_api_keys (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  service TEXT NOT NULL, -- 'openai', 'groq', vb.
  encrypted_key TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, service)
);

-- Mahsul verileri tablosu
CREATE TABLE IF NOT EXISTS crops (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  variety TEXT,
  planting_date DATE NOT NULL,
  expected_harvest_date DATE,
  city TEXT NOT NULL,
  notes TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI konuşma geçmişi tablosu
CREATE TABLE IF NOT EXISTS ai_conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  session_id TEXT NOT NULL,
  user_message TEXT NOT NULL,
  ai_response TEXT NOT NULL,
  message_type TEXT DEFAULT 'text', -- 'text' veya 'image'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security) politikaları
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE crops ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;

-- Profiller için RLS politikaları
CREATE POLICY "Kullanıcılar kendi profillerini görebilir" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Kullanıcılar kendi profillerini güncelleyebilir" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Kullanıcılar kendi profillerini oluşturabilir" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- API anahtarları için RLS politikaları
CREATE POLICY "Kullanıcılar kendi API anahtarlarını görebilir" ON user_api_keys
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi API anahtarlarını ekleyebilir" ON user_api_keys
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi API anahtarlarını güncelleyebilir" ON user_api_keys
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi API anahtarlarını silebilir" ON user_api_keys
  FOR DELETE USING (auth.uid() = user_id);

-- Mahsuller için RLS politikaları
CREATE POLICY "Kullanıcılar kendi mahsullerini görebilir" ON crops
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi mahsullerini ekleyebilir" ON crops
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi mahsullerini güncelleyebilir" ON crops
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi mahsullerini silebilir" ON crops
  FOR DELETE USING (auth.uid() = user_id);

-- AI konuşmaları için RLS politikaları
CREATE POLICY "Kullanıcılar kendi konuşmalarını görebilir" ON ai_conversations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi konuşmalarını ekleyebilir" ON ai_conversations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Trigger fonksiyonları
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Updated_at trigger'ları
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_api_keys_updated_at BEFORE UPDATE ON user_api_keys
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_crops_updated_at BEFORE UPDATE ON crops
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Kullanıcı kaydı sonrası profil oluşturma fonksiyonu
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Yeni kullanıcı kaydı sonrası profil oluştur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- İndeksler (performans için)
CREATE INDEX IF NOT EXISTS idx_crops_user_id ON crops(user_id);
CREATE INDEX IF NOT EXISTS idx_crops_planting_date ON crops(planting_date);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_id ON ai_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_session_id ON ai_conversations(session_id);
CREATE INDEX IF NOT EXISTS idx_user_api_keys_user_id ON user_api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_user_api_keys_service ON user_api_keys(service);

