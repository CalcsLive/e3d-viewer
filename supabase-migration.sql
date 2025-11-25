-- Create e3d_models metadata table in Supabase
-- Run this in your Supabase SQL Editor to enable metadata tracking with folder organization

-- Create e3d_models table with folder support and deduplication
CREATE TABLE IF NOT EXISTS public.e3d_models (
    -- Identity
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Folder organization (unified - no separate projects table)
    folder_path TEXT NOT NULL DEFAULT '',  -- e.g., '' (root), 'clients/acme', 'archive/2024'

    -- File identity (for deduplication within folder)
    file_hash TEXT NOT NULL,               -- SHA-256 hash of file content
    original_filename TEXT NOT NULL,       -- Original filename from upload
    file_size BIGINT NOT NULL,             -- File size in bytes
    file_type TEXT NOT NULL,               -- File extension (stl, 3mf, glb, gltf)

    -- Source file metadata
    source_modified_at TIMESTAMPTZ,        -- File.lastModified from browser

    -- Storage
    storage_path TEXT NOT NULL,            -- users/{user_id}/{folder_path}/{model_id}.ext
    thumbnail_path TEXT,                   -- Optional thumbnail

    -- User metadata
    title TEXT,                            -- Display name (defaults to original_filename)
    description TEXT,
    tags TEXT[],                           -- For searching/filtering

    -- Permissions
    is_public BOOLEAN DEFAULT false,       -- Enable link sharing
    allow_download BOOLEAN DEFAULT true,   -- Allow viewers to download

    -- Timestamps
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_viewed_at TIMESTAMPTZ,

    -- Analytics
    view_count INTEGER DEFAULT 0,
    download_count INTEGER DEFAULT 0
);

-- Deduplication constraint: Same user + same folder + same file hash = duplicate
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_folder_file_dedup
    ON public.e3d_models(user_id, folder_path, file_hash);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_user_models ON public.e3d_models(user_id, uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_folder ON public.e3d_models(user_id, folder_path, uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_public_models ON public.e3d_models(is_public, uploaded_at DESC) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_tags ON public.e3d_models USING GIN(tags);

-- Enable Row Level Security (RLS)
ALTER TABLE public.e3d_models ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- 1. Public can read models marked as public (for link sharing)
CREATE POLICY "Allow public read of public models" ON public.e3d_models
    FOR SELECT
    USING (is_public = true);

-- 2. Users can read their own models
CREATE POLICY "Allow users to read own models" ON public.e3d_models
    FOR SELECT
    USING (auth.uid() = user_id);

-- 3. Authenticated users can insert their own models
CREATE POLICY "Allow authenticated insert" ON public.e3d_models
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- 4. Users can update their own models
CREATE POLICY "Allow users to update own models" ON public.e3d_models
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 5. Users can delete their own models
CREATE POLICY "Allow users to delete own models" ON public.e3d_models
    FOR DELETE
    USING (auth.uid() = user_id);

-- Table and column comments
COMMENT ON TABLE public.e3d_models IS 'Metadata for uploaded 3D engineering models with folder organization';
COMMENT ON COLUMN public.e3d_models.id IS 'Short unique identifier (8 chars) for URL sharing';
COMMENT ON COLUMN public.e3d_models.user_id IS 'Owner of the model (references auth.users)';
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
