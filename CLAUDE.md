# E3D Viewer - Implementation Documentation

> Comprehensive guide to features, architecture, and future roadmap
> Created: November 2025
> Last Updated: November 2025

## Table of Contents
- [Overview](#overview)
- [Implemented Features](#implemented-features)
- [Technical Architecture](#technical-architecture)
- [Database Schema](#database-schema)
- [Authentication Flow](#authentication-flow)
- [File Upload Flow](#file-upload-flow)
- [Known Limitations](#known-limitations)
- [Future Feature Ideas](#future-feature-ideas)
- [Development Notes](#development-notes)

---

## Overview

E3D Viewer is a professional 3D model viewer and management platform designed for engineering workflows and 3D printing preparation. Built with modern web technologies, it provides a seamless experience for uploading, viewing, organizing, and sharing 3D models.

### **Key Highlights**
- 🎨 **Full color support** for 3MF and GLB/GLTF formats
- 🔐 **User authentication** with Supabase Auth
- 📁 **Unlimited folder nesting** for organization
- 🔍 **Smart deduplication** prevents duplicate files
- 🌐 **Public sharing** without requiring login
- 🎮 **CAD-style controls** familiar to engineers
- 📱 **Responsive design** works on all devices

---

## Implemented Features

### ✅ **User Management**

#### Authentication
- Email/password signup and login
- Password recovery via email
- Session persistence across page navigation
- Automatic redirect to login for protected pages
- Logout functionality on all pages

#### User Experience
- User email displayed in all menus
- Signed-in state visible throughout app
- Seamless navigation between Upload, Dashboard, and Viewer

### ✅ **3D Model Upload**

#### Supported Formats
- **STL** - Standard Tessellation Language (monochrome)
- **3MF** - 3D Manufacturing Format (full color, multi-material)
- **GLB** - Binary glTF (full color, materials, textures)
- **GLTF** - glTF JSON (full color, materials, textures)

#### Upload Features
- Drag-and-drop or click to select file
- Folder selection during upload
- Create new folders on-the-fly
- Nested folder paths (e.g., `clients/acme/parts/v2`)
- Real-time upload progress indicator
- Automatic metadata extraction (size, type, modified date)
- SHA-256 hash calculation for deduplication

#### File Deduplication
- **Hybrid approach** for performance:
  1. Quick check: filename + size match
  2. If match found: calculate SHA-256 hash
  3. If hash matches: show duplicate dialog
- Scoped to user + folder (same file allowed in different folders)
- User options: Keep Both, Replace (coming soon), Cancel
- Prevents accidental re-uploads

### ✅ **Interactive 3D Viewer**

#### Camera Controls
- **Orbit Controls**: Drag to rotate, right-drag to pan, scroll to zoom
- **View Presets**: Top, Bottom, Front, Back, Left, Right
- **Camera Modes**: Perspective / Orthographic toggle
- **Home/Fit**: Reset camera or fit model to view
- **Toggle buttons** with active state indicators

#### Model Manipulation
- **Move Gizmo**: Translate model in 3D space
- **Rotate Gizmo**: Rotate model around axes
- **Mutually exclusive** modes (only one active at a time)

#### Scene Helpers
- **Grid (Ground)**: Toggleable reference grid
- **Axes (UCS)**: Toggleable coordinate system display
- **Auto-centering**: Models automatically centered on load
- **Auto-scaling**: Models scaled to fit view

#### Visual Features
- Ambient and directional lighting
- Automatic color preservation (3MF, GLB, GLTF)
- Smooth camera transitions
- Professional gray gradient background

### ✅ **Model Management Dashboard**

#### Grid View
- Responsive card layout (1-4 columns based on screen size)
- Thumbnail placeholders (cube icons)
- Model metadata display:
  - Filename/title
  - File size (auto-formatted)
  - File format (STL, 3MF, GLB, GLTF)
  - Upload date
  - Folder path

#### Search & Filter
- **Real-time search** across:
  - Original filename
  - Title (if set)
  - Description (if set)
  - Tags (if set)
- **Folder filter** dropdown
- **Model count** with filter indication
- Case-insensitive search

#### Model Actions
- **View**: Open in 3D viewer
- **Share**: Copy shareable link to clipboard
- **Delete**: Remove from storage and database (with confirmation)

#### Empty States
- "No models yet" with "Upload First Model" button
- "No models match your search" for filtered results

### ✅ **Folder Organization**

#### Structure
- **Virtual folders** - no physical directory structure
- **Unlimited nesting** - e.g., `clients/acme/parts/revision-3`
- **User-defined paths** - any naming convention
- **Root folder** option (empty string)

#### Features
- Folder selector on upload page
- Create new folder inline during upload
- Folder filter in dashboard
- Folder path displayed on model cards
- Per-user folder isolation

### ✅ **Public Sharing**

#### Link Sharing
- Share button copies `https://yourdomain.com/viewer/{model_id}` to clipboard
- 8-character unique model IDs for short URLs
- Works from dashboard or viewer page

#### Anonymous Viewing
- No login required to view shared models
- Models default to `is_public = true`
- Full 3D viewer functionality for anonymous users
- Prompt to sign in displayed for non-authenticated viewers

#### Privacy
- Database RLS policies ensure users can only modify their own models
- Storage RLS policies allow public read, authenticated write
- Future: Add public/private toggle in UI

---

## Technical Architecture

### **Frontend Stack**
- **Framework**: Nuxt 4 (Vue 3 composition API)
- **3D Engine**: Three.js with three-stdlib
- **Styling**: Tailwind CSS
- **Routing**: Nuxt file-based routing
- **State**: Vue refs and composables

### **Backend Stack**
- **Authentication**: Supabase Auth
- **Database**: Supabase PostgreSQL
- **Storage**: Supabase Storage (S3-compatible)
- **Security**: Row Level Security (RLS)

### **Deployment**
- **Platform**: Cloudflare Pages
- **Preset**: Nitro cloudflare-pages
- **CDN**: Cloudflare global edge network
- **Node Compat**: Enabled for full compatibility

### **Key Design Decisions**

#### 1. ID-Based URLs
- Short 8-character IDs instead of filenames
- Prevents encoding issues with special characters
- Enables clean, shareable URLs
- IDs generated client-side (not UUIDs)

#### 2. Hybrid Deduplication
- Quick check first (no hash computation)
- Hash only when potential duplicate found
- Balances performance and accuracy
- SHA-256 for cryptographic security

#### 3. Unified Folder System
- No separate "projects" table
- Virtual paths stored as strings
- Unlimited nesting without complexity
- User-friendly and flexible

#### 4. Public by Default
- Models default to `is_public = true`
- Simplifies sharing workflow
- Future: Add toggle for private models

#### 5. Storage Organization
```
e3d-models/
└── users/
    └── {user_id}/
        ├── {model_id}.stl
        ├── folder1/
        │   └── {model_id}.3mf
        └── folder2/
            └── subfolder/
                └── {model_id}.glb
```

---

## Database Schema

### **e3d_models Table**

```sql
CREATE TABLE e3d_models (
    -- Identity
    id TEXT PRIMARY KEY,                    -- 8-char unique ID
    user_id UUID REFERENCES auth.users(id), -- Owner (from Supabase Auth)

    -- Organization
    folder_path TEXT NOT NULL DEFAULT '',  -- Virtual folder path

    -- File Identity
    file_hash TEXT NOT NULL,               -- SHA-256 for deduplication
    original_filename TEXT NOT NULL,       -- Original upload name
    file_size BIGINT NOT NULL,             -- Bytes
    file_type TEXT NOT NULL,               -- Extension (stl, 3mf, glb, gltf)
    source_modified_at TIMESTAMPTZ,        -- File.lastModified

    -- Storage
    storage_path TEXT NOT NULL,            -- users/{user_id}/{folder}/{id}.ext
    thumbnail_path TEXT,                   -- Future: Generated thumbnails

    -- User Metadata
    title TEXT,                            -- Display name (defaults to filename)
    description TEXT,                      -- Future: User description
    tags TEXT[],                           -- Future: Searchable tags

    -- Permissions
    is_public BOOLEAN DEFAULT false,       -- Currently defaults to true in code
    allow_download BOOLEAN DEFAULT true,   -- Future: Download control

    -- Timestamps
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_viewed_at TIMESTAMPTZ,            -- Future: Analytics

    -- Analytics
    view_count INTEGER DEFAULT 0,          -- Future: Track popularity
    download_count INTEGER DEFAULT 0       -- Future: Track downloads
);
```

### **Indexes**

```sql
-- Deduplication (user + folder + hash must be unique)
CREATE UNIQUE INDEX idx_user_folder_file_dedup
    ON e3d_models(user_id, folder_path, file_hash);

-- User's models ordered by upload date
CREATE INDEX idx_user_models
    ON e3d_models(user_id, uploaded_at DESC);

-- Folder browsing
CREATE INDEX idx_user_folder
    ON e3d_models(user_id, folder_path, uploaded_at DESC);

-- Public model discovery
CREATE INDEX idx_public_models
    ON e3d_models(is_public, uploaded_at DESC) WHERE is_public = true;

-- Tag search (GIN index for array)
CREATE INDEX idx_tags
    ON e3d_models USING GIN(tags);
```

### **Row Level Security Policies**

```sql
-- Public can read public models (for anonymous sharing)
CREATE POLICY "Allow public read of public models"
    FOR SELECT
    USING (is_public = true);

-- Users can read their own models
CREATE POLICY "Allow users to read own models"
    FOR SELECT
    USING (auth.uid() = user_id);

-- Authenticated users can insert their own models
CREATE POLICY "Allow authenticated insert"
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own models
CREATE POLICY "Allow users to update own models"
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own models
CREATE POLICY "Allow users to delete own models"
    FOR DELETE
    USING (auth.uid() = user_id);
```

---

## Authentication Flow

### **Signup Flow**
1. User visits `/auth/signup`
2. Enters email and password (min 6 characters)
3. Password confirmation validation
4. Supabase creates user account
5. Email confirmation sent (if enabled in Supabase)
6. Redirect to login page
7. User confirms email via link
8. Can now log in

### **Login Flow**
1. User visits `/auth/login`
2. Enters email and password
3. Supabase validates credentials
4. JWT token stored in browser
5. `useSupabaseUser()` returns user object
6. User redirected to upload page
7. Email displayed in header

### **User Object Structure**
```javascript
// From useSupabaseUser()
{
  sub: "b34322b1-f14c-459e-9fca-cde17f939246",  // USER ID (not .id!)
  email: "user@example.com",
  aud: "authenticated",
  role: "authenticated",
  session_id: "...",
  // ... other JWT claims
}
```

**⚠️ Important**: User ID is in `user.value.sub`, not `user.value.id`!

### **Session Persistence**
- JWT stored in browser storage
- Automatic session refresh
- Persists across page reloads
- Shared across tabs

### **Protected Routes**
- Dashboard redirects to `/auth/login` if not authenticated
- Upload requires authentication (checked before file processing)
- Viewer page works for both authenticated and anonymous users

---

## File Upload Flow

### **Step-by-Step Process**

1. **User selects file** via upload area or drag-drop
2. **Authentication check**: Verify `user.value.sub` exists
3. **Duplicate check (Hybrid)**:
   - Query database for same user + folder + filename + size
   - If found: Calculate SHA-256 hash of file
   - Compare hashes
   - If match: Show duplicate dialog
   - User chooses: Keep Both, Replace, or Cancel
4. **Generate model ID**: 8-character random string
5. **Build storage path**: `users/{user_id}/{folder_path}/{model_id}.{ext}`
6. **Calculate file hash**: SHA-256 of file contents
7. **Extract metadata**:
   - Original filename
   - File size (bytes)
   - File type (extension)
   - Source modified timestamp (`File.lastModified`)
8. **Upload to Supabase Storage**:
   - Bucket: `e3d-models`
   - Path: `users/{user_id}/{folder_path}/{model_id}.ext`
   - Cache control: 3600 seconds
   - Upsert: false (no overwrite)
9. **Insert metadata to database**:
   - Table: `e3d_models`
   - All metadata fields populated
   - `is_public` set to `true` (default)
10. **Handle errors**:
    - If storage succeeds but DB fails: Delete from storage
    - Show error message to user
11. **Redirect to viewer**: `/viewer/{model_id}`

### **Error Handling**
- Authentication errors → Redirect to login
- Duplicate files → Show dialog
- Storage errors → Show error message
- Database errors → Cleanup storage, show error
- Invalid file format → Show error

---

## Known Limitations

### **Current Limitations**

1. **No Thumbnail Generation**
   - Placeholder cube icons used
   - Actual thumbnails would require server-side rendering

2. **No Description/Tags UI**
   - Database supports description and tags
   - UI for editing not yet implemented
   - Search works if data exists

3. **No Public/Private Toggle**
   - All uploads default to public
   - Database supports `is_public` field
   - UI toggle not implemented

4. **No Model Versioning**
   - "Replace" option in duplicate dialog not implemented
   - No version history tracking

5. **No Batch Operations**
   - Can't select multiple models
   - Can't bulk delete or move

6. **No Analytics**
   - View count and download count tracked in DB
   - Not displayed or incremented

7. **No Folder Management**
   - Can't rename folders
   - Can't move models between folders
   - Can't delete folders

8. **No Download Button**
   - Can view but not download original file
   - Would be useful for sharing

9. **Limited Search**
   - Only searches metadata fields
   - No fuzzy matching
   - No search history

10. **No Collaboration Features**
    - Can't share with specific users
    - No comments or annotations
    - No team workspaces

### **Browser Compatibility**

- ✅ **Chrome/Edge**: Full functionality
- ✅ **Brave**: Works with standard privacy settings
- ⚠️ **Firefox**: Not tested extensively
- ⚠️ **Safari**: May have WebGL compatibility issues
- ❌ **IE11**: Not supported (requires modern browser)

---

## Future Feature Ideas

### **High Priority** ⭐

1. **Thumbnail Generation**
   - Server-side rendering with Three.js (headless)
   - Generate on upload
   - Store in `e3d-models/users/{user_id}/thumbnails/`
   - Display in dashboard grid

2. **Model Editing UI**
   - Edit title, description, tags
   - Toggle public/private
   - Update modal/form in dashboard

3. **Folder Management**
   - Rename folders
   - Move models between folders (drag-and-drop)
   - Delete empty folders
   - Folder tree view

4. **Download Button**
   - Download original file from viewer
   - Track downloads in analytics

5. **Public/Private Toggle**
   - Checkbox on upload
   - Toggle in dashboard
   - Private models require authentication

### **Medium Priority** 🔶

6. **Model Versioning**
   - "Replace" creates new version
   - Version history (v1, v2, v3)
   - Compare versions side-by-side
   - Revert to previous version

7. **Batch Operations**
   - Select multiple models (checkboxes)
   - Bulk delete
   - Bulk move to folder
   - Bulk tag

8. **Advanced Search**
   - Fuzzy matching
   - Search by date range
   - Search by file size
   - Filter by file type
   - Saved searches

9. **Analytics Dashboard**
   - Total models uploaded
   - Storage used vs quota
   - Most viewed models
   - Upload activity over time
   - Folder distribution

10. **Annotations**
    - Add 3D markers/pins to models
    - Add text notes
    - Attach to specific points
    - Share annotations with link

### **Low Priority / Nice-to-Have** 💡

11. **Model Collections**
    - Create collections across folders
    - Share collections as portfolio
    - Public collections page

12. **Team Workspaces**
    - Invite team members
    - Shared folder access
    - Role-based permissions (viewer, editor, admin)

13. **Comments**
    - Comment threads on models
    - Mention other users
    - Email notifications

14. **Export Options**
    - Export folder as ZIP
    - Export metadata as CSV
    - Batch export

15. **API Access**
    - REST API for programmatic upload
    - API keys
    - Webhooks for events

16. **Mobile App**
    - Native iOS/Android apps
    - AR viewing mode
    - Mobile-optimized controls

17. **Advanced 3D Features**
    - Measurement tools
    - Cross-section slicing
    - Exploded view
    - Animation playback (for animated GLB)

18. **Integration**
    - Slack notifications
    - Discord webhooks
    - CAD software plugins
    - 3D printing service integration

19. **Model Comparison**
    - Side-by-side viewer
    - Diff visualization
    - Overlay mode

20. **QR Codes**
    - Generate QR code for model
    - Display in viewer
    - Print on model labels

---

## Development Notes

### **Important Code Patterns**

#### Getting User ID
```javascript
// CORRECT ✅
const userId = user.value?.id || user.value?.sub

// WRONG ❌
const userId = user.value?.id  // This is undefined!
```

The Supabase `useSupabaseUser()` returns JWT claims, where user ID is in `sub` field.

#### Checking Authentication
```javascript
// In composables
const user = useSupabaseUser()
const userId = user.value?.id || user.value?.sub
if (!userId) {
  throw new Error('User must be authenticated')
}

// In pages
onMounted(() => {
  if (!user.value) {
    router.push('/auth/login')
  }
})
```

#### File Hash Calculation
```javascript
const calculateFileHash = async (file: File): Promise<string> => {
  const buffer = await file.arrayBuffer()
  const hashBuffer = await crypto.subtle.digest('SHA-256', buffer)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}
```

#### Supabase Storage Paths
```javascript
// Format: users/{user_id}/{folder_path}/{model_id}.ext
const folderPrefix = folderPath ? `${folderPath}/` : ''
const filePath = `users/${userId}/${folderPrefix}${fileName}`

// Examples:
// users/abc123/model_xyz.stl
// users/abc123/clients/acme/model_xyz.3mf
// users/abc123/projects/2025/parts/model_xyz.glb
```

### **Common Pitfalls**

1. **User ID is in .sub, not .id** - Most common issue
2. **Bucket name is e3d-models, not 3d-models** - Compatibility fix
3. **is_public must be true for anonymous viewing** - Database default is false
4. **Storage RLS policies** - Must allow public SELECT for anonymous viewing
5. **Database RLS policies** - Must allow public SELECT WHERE is_public = true

### **Testing Checklist**

- [ ] Sign up new user
- [ ] Confirm email (if enabled)
- [ ] Log in
- [ ] Upload model to root folder
- [ ] Upload model to nested folder
- [ ] Try uploading duplicate (should show dialog)
- [ ] View model in viewer
- [ ] Copy share link
- [ ] Log out
- [ ] Open share link (should work anonymously)
- [ ] Go to dashboard
- [ ] Search for model
- [ ] Filter by folder
- [ ] Delete model
- [ ] Test all 3D viewer controls

### **Deployment Checklist**

- [ ] Run `supabase-migration-update.sql` in Supabase SQL Editor
- [ ] Create `e3d-models` storage bucket (public)
- [ ] Add storage RLS policies
- [ ] Enable email auth in Supabase
- [ ] Set up redirect URLs in Supabase Auth
- [ ] Set environment variables in Cloudflare Pages
- [ ] Deploy to Cloudflare Pages
- [ ] Test production build
- [ ] Test anonymous viewing
- [ ] Test authentication flow

---

## Conclusion

E3D Viewer is a production-ready 3D model viewer and management platform with a solid foundation for future enhancements. The architecture is clean, scalable, and follows modern best practices.

### **What Works Great**
✅ User authentication
✅ File upload and storage
✅ Folder organization
✅ Deduplication
✅ Public sharing
✅ 3D viewer with CAD controls
✅ Model management dashboard
✅ Search and filtering

### **Next Recommended Steps**
1. Add thumbnail generation (biggest visual impact)
2. Implement model editing UI (title, description, tags)
3. Add public/private toggle (privacy control)
4. Build folder management tools (rename, move, delete)

The platform is now ready for real-world use! 🚀

---

*This documentation was created during development with Claude Code assistance. Last updated: November 2025*
