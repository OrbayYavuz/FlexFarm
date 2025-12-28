-- Drop previous attempts
DROP POLICY IF EXISTS "Users can delete their own marketplace items" ON marketplace_items;
DROP POLICY IF EXISTS "Users can delete their own marketplace items OR admin" ON marketplace_items;

-- Robust Policy
CREATE POLICY "Users can delete their own marketplace items OR admin"
ON marketplace_items FOR DELETE
USING (
  auth.uid() = user_id 
  OR 
  (SELECT email FROM auth.users WHERE id = auth.uid()) = 'orbay1907@gmail.com'
);
