-- Drop previous attempts
DROP POLICY IF EXISTS "Users can delete their own marketplace items" ON marketplace_items;
DROP POLICY IF EXISTS "Users can delete their own marketplace items OR admin" ON marketplace_items;

-- Safe Policy using JWT (Standard Supabase way)
CREATE POLICY "Users can delete their own marketplace items OR admin"
ON marketplace_items FOR DELETE
USING (
  auth.uid() = user_id 
  OR 
  (auth.jwt() ->> 'email') = 'orbay1907@gmail.com'
);
