# Supabase Setup Guide

Complete guide to set up Supabase backend for E3D Viewer with folder organization and user authentication.

## Prerequisites

- Supabase account (free tier works fine)
- Supabase project created

## Step 1: Create Storage Bucket

1. Go to your Supabase dashboard
2. Navigate to **Storage** → **Buckets**
3. Click **New Bucket**
4. Configure:
   - **Name**: `e3d-models` (⚠️ Important: use this exact name)
   - **Public bucket**: ✅ Check this box (allows public read access for shared links)
   - **File size limit**: Set to your preference (e.g., 50 MB)
   - **Allowed MIME types**: Leave empty (allows all) or specify:
     - `model/stl`
     - `model/3mf`
     - `model/gltf-binary`
     - `model/gltf+json`

5. Click **Create Bucket**

### Why `e3d-models` instead of `3d-models`?

- Starts with a letter (better compatibility with tools/services)
- Consistent naming with `e3d_models` database table
- Follows standard naming conventions

## Step 2: Run Database Migration

1. Navigate to **SQL Editor** in Supabase dashboard
2. Click **New Query**
3. Copy the entire contents of `supabase-migration-update.sql` from this project
4. Paste into the SQL editor
5. Click **Run** (or press Ctrl/Cmd + Enter)

### What the migration creates:

**Table: `e3d_models`**
- Stores metadata for all uploaded 3D models
- Links files to users (authentication required for uploads)
- Supports unlimited folder nesting (e.g., `clients/acme/parts/v2`)
- Tracks file hashes for deduplication
- Includes analytics (view count, download count)
- Privacy controls (public/private models)

**Indexes:**
- Fast user-based queries
- Folder navigation
- Public model discovery
- Tag-based search

**Row Level Security (RLS) Policies:**
- ✅ Public can view models marked as `is_public = true`
- ✅ Users can view their own models
- ✅ Authenticated users can upload models
- ✅ Users can update/delete only their own models

## Step 3: Enable Email Authentication (Optional but Recommended)

For user authentication to work:

1. Navigate to **Authentication** → **Providers**
2. Enable **Email** provider (should be enabled by default)
3. Configure email templates if desired
4. For development, you can use:
   - **Site URL**: `http://localhost:3000`
   - **Redirect URLs**: `http://localhost:3000/**`

For production deployment:
5. Add your production URL to **Redirect URLs**
   - Example: `https://your-app.pages.dev/**`

## Step 4: Get Your API Credentials

1. Navigate to **Project Settings** → **API**
2. Copy these values to your `.env` file:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_KEY=your-anon-public-key-here
```

⚠️ **Important**: Use the `anon` / `public` key, NOT the `service_role` secret key!

## Step 5: Configure Storage Policies (Optional - Advanced)

If you want more control over storage access:

1. Navigate to **Storage** → **Policies** → `e3d-models` bucket
2. The bucket is public by default (good for simple sharing)
3. For finer control, you can add custom policies:

**Example: Only authenticated users can upload**
```sql
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'e3d-models' AND auth.uid()::text = (storage.foldername(name))[1]);
```

**Example: Users can delete their own files**
```sql
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'e3d-models' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## Verification Checklist

Before running your app, verify:

- ✅ Bucket `e3d-models` exists and is public
- ✅ Table `e3d_models` created successfully (check in **Table Editor**)
- ✅ RLS policies are active (green checkmark in **Authentication** → **Policies**)
- ✅ `.env` file contains correct `SUPABASE_URL` and `SUPABASE_KEY`
- ✅ Email authentication is enabled (if using auth features)

## Testing the Setup

1. Start your dev server: `npm run dev`
2. Open http://localhost:3000
3. Try uploading a 3D model file
4. You should be prompted to log in (if auth is required)
5. After upload, check:
   - **Storage** → `e3d-models` → `users/{user_id}/` folder contains the file
   - **Table Editor** → `e3d_models` table has a new row with metadata

## Folder Organization

The app organizes files as:

```
e3d-models/
└── users/
    └── {user_id}/
        ├── {model_id}.stl              # Root folder (folder_path = '')
        ├── clients/
        │   └── acme/
        │       └── {model_id}.3mf      # folder_path = 'clients/acme'
        └── projects/
            └── 2025/
                └── {model_id}.glb      # folder_path = 'projects/2025'
```

Users can create nested folders like:
- `projects/2025/january`
- `clients/acme/parts/revision-3`
- `archive/old-designs`

## Deduplication

The system prevents accidental duplicate uploads within the same folder:

1. **Quick check**: Compares filename + size (fast)
2. **Hash confirmation**: If match found, calculates SHA-256 hash (accurate)
3. **User prompt**: Shows dialog with options:
   - Keep Both (upload anyway)
   - Replace Existing
   - Cancel

**Note**: Same file can exist in different folders (e.g., `projects/A` and `projects/B`)

## Troubleshooting

**Error: relation "e3d_models" does not exist**
- Run the migration script in SQL Editor
- Refresh the page and try again

**Error: new row violates row-level security policy**
- User is not authenticated
- Enable email auth in Supabase dashboard
- Add login UI to your app (or make models public)

**Files not uploading**
- Check bucket name is exactly `e3d-models`
- Verify bucket is set to **public**
- Check browser console for CORS errors
- Ensure `.env` credentials are correct

**Can't see uploaded models in Storage**
- Look in `users/{user_id}/` folder, not root
- Check if user is authenticated (anonymous uploads not supported)
- Verify file upload succeeded (check browser network tab)

## Migration from Old Schema

If you have existing data in old `3d-models` bucket:

1. **Option A**: Start fresh (delete old bucket, create `e3d-models`)
2. **Option B**: Copy files manually:
   - Download files from `3d-models` bucket
   - Re-upload through the app to `e3d-models`
   - Old links will break (models use new ID-based URLs)

The migration script (`supabase-migration-update.sql`) preserves existing database records if you're upgrading from an older version of this app.

## Next Steps

- Set up authentication UI (login/signup pages)
- Create "My Models" dashboard page
- Add model search/filter functionality
- Implement thumbnail generation
- Add model sharing with specific users

For questions or issues, check the main [README.md](README.md) troubleshooting section.
