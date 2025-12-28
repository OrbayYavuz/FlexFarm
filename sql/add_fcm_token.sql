-- Add FCM Token column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS fcm_token text;

-- Create policy to allow users to update their own FCM token
CREATE POLICY "Users can update their own fcm_token" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Comment
COMMENT ON COLUMN public.profiles.fcm_token IS 'Firebase Cloud Messaging Token for Push Notifications';
