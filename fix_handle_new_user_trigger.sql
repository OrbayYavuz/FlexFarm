-- Supabase Dashboard'da SQL Editor'da çalıştır
-- Bu script handle_new_user trigger'ını düzeltir

-- 1. Mevcut trigger'ı sil
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Mevcut fonksiyonu sil
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Yeni, güvenli fonksiyonu oluştur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Profil zaten varsa hata vermez
  INSERT INTO public.profiles (id, email, name, created_at, updated_at)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Trigger'ı yeniden oluştur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Test için kontrol
SELECT 'Trigger ve fonksiyon başarıyla oluşturuldu' as result;


