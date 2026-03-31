-- Mahsul Hatırlatıcıları Tablosu
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

CREATE TABLE IF NOT EXISTS crop_reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  crop_id UUID REFERENCES crops(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  reminder_date TIMESTAMP WITH TIME ZONE NOT NULL,
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('spraying', 'watering', 'fertilizing', 'pruning', 'harvesting', 'other')),
  is_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS'i etkinleştir
ALTER TABLE crop_reminders ENABLE ROW LEVEL SECURITY;

-- RLS Politikaları
CREATE POLICY "Kullanıcılar kendi hatırlatıcılarını görebilir" ON crop_reminders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi hatırlatıcılarını ekleyebilir" ON crop_reminders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi hatırlatıcılarını güncelleyebilir" ON crop_reminders
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcılar kendi hatırlatıcılarını silebilir" ON crop_reminders
  FOR DELETE USING (auth.uid() = user_id);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_crop_reminders_user_id ON crop_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_crop_reminders_crop_id ON crop_reminders(crop_id);
CREATE INDEX IF NOT EXISTS idx_crop_reminders_reminder_date ON crop_reminders(reminder_date);


