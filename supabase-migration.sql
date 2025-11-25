-- Optional: Create e3d_models metadata table in Supabase
-- Run this in your Supabase SQL Editor to enable metadata tracking
-- This is optional - the app will work without it using storage paths only

-- Create e3d_models table
CREATE TABLE IF NOT EXISTS public.e3d_models (
    id TEXT PRIMARY KEY,
    original_filename TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    file_type TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_e3d_models_uploaded_at ON public.e3d_models(uploaded_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.e3d_models ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public read access (for link sharing)
CREATE POLICY "Allow public read access" ON public.e3d_models
    FOR SELECT
    USING (true);

-- Create policy to allow anyone to insert (for uploads)
CREATE POLICY "Allow public insert" ON public.e3d_models
    FOR INSERT
    WITH CHECK (true);

-- Optional: If you want only authenticated users to upload, use this instead:
-- CREATE POLICY "Allow authenticated insert" ON public.e3d_models
--     FOR INSERT
--     TO authenticated
--     WITH CHECK (true);

-- Optional: Add delete policy (users can delete their own uploads)
-- This requires authentication and tracking user_id
-- CREATE POLICY "Allow owner delete" ON public.e3d_models
--     FOR DELETE
--     USING (auth.uid() = user_id);

COMMENT ON TABLE public.e3d_models IS 'Metadata for uploaded 3D engineering models';
COMMENT ON COLUMN public.e3d_models.id IS 'Short unique identifier (8 chars)';
COMMENT ON COLUMN public.e3d_models.original_filename IS 'Original filename from upload';
COMMENT ON COLUMN public.e3d_models.file_size IS 'File size in bytes';
COMMENT ON COLUMN public.e3d_models.file_type IS 'File extension (stl, 3mf, glb, gltf)';
COMMENT ON COLUMN public.e3d_models.storage_path IS 'Path in Supabase storage bucket';
COMMENT ON COLUMN public.e3d_models.uploaded_at IS 'Upload timestamp';
