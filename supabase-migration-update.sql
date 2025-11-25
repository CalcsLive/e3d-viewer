-- Migration script to update existing e3d_models table
-- This adds folder organization and user ownership to existing schema

-- Step 1: Drop existing policies (they reference columns that will change)
DROP POLICY IF EXISTS "Allow public read access" ON public.e3d_models;
DROP POLICY IF EXISTS "Allow public insert" ON public.e3d_models;
DROP POLICY IF EXISTS "Allow authenticated insert" ON public.e3d_models;
DROP POLICY IF EXISTS "Allow owner delete" ON public.e3d_models;

-- Step 2: Add new columns to existing table
ALTER TABLE public.e3d_models
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS folder_path TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS file_hash TEXT,
    ADD COLUMN IF NOT EXISTS source_modified_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS thumbnail_path TEXT,
    ADD COLUMN IF NOT EXISTS title TEXT,
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS tags TEXT[],
    ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS allow_download BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS last_viewed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS download_count INTEGER DEFAULT 0;

-- Step 3: Update existing rows with default values
-- Set file_hash to a temporary unique value (will be regenerated on next upload)
UPDATE public.e3d_models
SET file_hash = COALESCE(file_hash, md5(random()::text))
WHERE file_hash IS NULL;

-- Make file_hash NOT NULL after setting defaults
ALTER TABLE public.e3d_models
    ALTER COLUMN file_hash SET NOT NULL;

-- Step 4: Update storage_path format for existing records
-- Old format: models/{model_id}.ext
-- New format: users/{user_id}/{folder_path}/{model_id}.ext
-- We'll keep old paths for now since user_id might be NULL for existing records

-- Step 5: Drop old indexes if they exist
DROP INDEX IF EXISTS idx_e3d_models_uploaded_at;

-- Step 6: Create new indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_folder_file_dedup
    ON public.e3d_models(user_id, folder_path, file_hash)
    WHERE user_id IS NOT NULL;  -- Only enforce dedup for authenticated users

CREATE INDEX IF NOT EXISTS idx_user_models
    ON public.e3d_models(user_id, uploaded_at DESC)
    WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_folder
    ON public.e3d_models(user_id, folder_path, uploaded_at DESC)
    WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_public_models
    ON public.e3d_models(is_public, uploaded_at DESC)
    WHERE is_public = true;

CREATE INDEX IF NOT EXISTS idx_tags
    ON public.e3d_models USING GIN(tags)
    WHERE tags IS NOT NULL;

-- Step 7: Ensure RLS is enabled
ALTER TABLE public.e3d_models ENABLE ROW LEVEL SECURITY;

-- Step 8: Create new RLS policies

-- Allow public to read models marked as public (for link sharing)
CREATE POLICY "Allow public read of public models" ON public.e3d_models
    FOR SELECT
    USING (is_public = true);

-- Allow public to read legacy models (without user_id) - temporary during migration
CREATE POLICY "Allow public read of legacy models" ON public.e3d_models
    FOR SELECT
    USING (user_id IS NULL);

-- Users can read their own models
CREATE POLICY "Allow users to read own models" ON public.e3d_models
    FOR SELECT
    USING (auth.uid() = user_id);

-- Authenticated users can insert their own models
CREATE POLICY "Allow authenticated insert" ON public.e3d_models
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own models
CREATE POLICY "Allow users to update own models" ON public.e3d_models
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own models
CREATE POLICY "Allow users to delete own models" ON public.e3d_models
    FOR DELETE
    USING (auth.uid() = user_id);

-- Step 9: Update comments
COMMENT ON TABLE public.e3d_models IS 'Metadata for uploaded 3D engineering models with folder organization';
COMMENT ON COLUMN public.e3d_models.id IS 'Short unique identifier (8 chars) for URL sharing';
COMMENT ON COLUMN public.e3d_models.user_id IS 'Owner of the model (references auth.users) - NULL for legacy anonymous uploads';
COMMENT ON COLUMN public.e3d_models.folder_path IS 'Virtual folder path (e.g., "clients/acme/parts") - supports unlimited nesting';
COMMENT ON COLUMN public.e3d_models.file_hash IS 'SHA-256 hash for deduplication within same folder';
COMMENT ON COLUMN public.e3d_models.original_filename IS 'Original filename from upload';
COMMENT ON COLUMN public.e3d_models.file_size IS 'File size in bytes';
COMMENT ON COLUMN public.e3d_models.file_type IS 'File extension (stl, 3mf, glb, gltf)';
COMMENT ON COLUMN public.e3d_models.source_modified_at IS 'Last modified timestamp from source file system';
COMMENT ON COLUMN public.e3d_models.storage_path IS 'Path in Supabase storage bucket';
COMMENT ON COLUMN public.e3d_models.thumbnail_path IS 'Optional path to thumbnail image';
COMMENT ON COLUMN public.e3d_models.title IS 'User-editable display name';
COMMENT ON COLUMN public.e3d_models.description IS 'User-provided description';
COMMENT ON COLUMN public.e3d_models.tags IS 'Array of tags for search/filtering';
COMMENT ON COLUMN public.e3d_models.is_public IS 'If true, model can be viewed via shared link without authentication';
COMMENT ON COLUMN public.e3d_models.allow_download IS 'If true, viewers can download the model file';

-- Migration complete!
-- Note: Existing models will continue to work, but won't have user_id assigned
-- New uploads will require authentication and include user_id
