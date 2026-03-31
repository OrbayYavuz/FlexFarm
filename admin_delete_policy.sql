-- Drop the old policy first
DROP POLICY IF EXISTS "Users can delete their own marketplace items" ON marketplace_items;
DROP POLICY IF EXISTS "Users can delete their own marketplace items OR admin" ON marketplace_items;

-- Create the new policy that includes the admin check
CREATE POLICY "Users can delete their own marketplace items OR admin"
ON marketplace_items FOR DELETE
USING (
  auth.uid() = user_id 
  OR 
  (auth.jwt() ->> 'email') = 'orbay1907@gmail.com'
);
