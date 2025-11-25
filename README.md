# E3D Viewer - 3D Model Viewer for Engineering & 3D Printing

A professional 3D model viewer built with Nuxt 4, Three.js, and Supabase, designed for engineering model review and 3D printing preparation. Deployed on Cloudflare Pages for fast global access.

## Features

- **Multi-format Support with Full Color Fidelity**
  - STL (monochrome)
  - **3MF** - Full color support for multi-material 3D printing models
  - **GLB/GLTF** - Complete color and material data preservation for engineering models
- **Interactive 3D Viewer**
  - Orbit controls (rotate, pan, zoom)
  - Transform controls (move and rotate objects)
  - Grid and axes helpers for spatial reference
  - Automatic model centering and scaling
- **Cloud Storage** via Supabase for easy model sharing
- **Cloudflare Pages** deployment for global edge performance
- Modern gradient UI with Tailwind CSS

## Why Color Support Matters

For engineering and 3D printing workflows, color data is critical:

- **Engineering Review**: Visualize assemblies with part identification by color, stress analysis results, and material specifications
- **3D Printing**: Preview multi-material prints with accurate color representation before sending to printer
- **Quality Control**: Identify defects, verify color coding, and validate model integrity

This viewer preserves the full color and material information embedded in **3MF** and **GLB/GLTF** formats, making it ideal for professional workflows.

## Tech Stack

- **Frontend**: Nuxt 4 + Vue 3
- **3D Graphics**: Three.js + three-stdlib
- **Storage**: Supabase
- **Styling**: Tailwind CSS
- **Deployment**: Cloudflare Pages (Nitro preset)

## Setup

### Prerequisites

- Node.js 18+
- Supabase account and project
- npm or pnpm

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Supabase

Create `.env` file in the root:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key
```

### 3. Set Up Supabase Storage

In your Supabase project:

1. Navigate to **Storage** section
2. Create a new bucket named `3d-models`
3. Set bucket to **public** (or configure RLS policies as needed)
4. The app automatically creates a `models/` folder on first upload

### 4. Development Server

```bash
npm run dev
```

Access at http://localhost:3000 (or alternative port if occupied)

### 5. Build for Production

```bash
npm run build
```

This creates the `dist/` directory with your production-ready application.

### 6. Deploy to Cloudflare Pages

**Option A: Direct Deployment (CLI)**

```bash
npm run deploy
```

This will:
1. Build your application
2. Deploy to Cloudflare Pages using Wrangler
3. Automatically create a new project on first deployment

**Option B: Git-based Deployment (Recommended for Production)**

1. Push your code to GitHub/GitLab
2. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/) → Pages
3. Click "Create a project" → "Connect to Git"
4. Select your repository
5. Configure build settings:
   - **Build command**: `npm run build`
   - **Build output directory**: `dist`
   - **Root directory**: `/` (or leave empty)
6. Add environment variables:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_KEY`: Your Supabase anonymous key
7. Click "Save and Deploy"

**Important**: After deployment, remember to set up environment variables in the Cloudflare Pages dashboard for your Supabase credentials.

## Project Structure

```
e3d-viewer/
├── app/
│   ├── assets/css/
│   │   └── main.css              # Tailwind styles
│   ├── components/
│   │   └── Viewer3D.vue          # Three.js viewer component
│   ├── composables/
│   │   ├── use3DModel.ts         # Model upload/storage logic
│   │   └── useSupabase.ts        # Supabase client
│   ├── pages/
│   │   ├── index.vue             # Upload interface
│   │   └── viewer/[filename].vue # 3D viewer page
│   └── app.vue
├── nuxt.config.ts                # Nuxt configuration
├── tailwind.config.ts            # Tailwind config
└── wrangler.jsonc                # Cloudflare config
```

## Usage

1. **Upload**: Click or drag a 3D model file on the home page
2. **View**: Automatically redirected to the interactive viewer
3. **Controls**:
   - **Left drag**: Rotate view
   - **Right drag**: Pan view
   - **Scroll**: Zoom in/out
   - **Move/Rotate button**: Toggle transform mode
   - **Home button**: Reset camera to default

## Supported Formats

| Format | Color Support | Best For |
|--------|--------------|----------|
| **3MF** | **Yes - Full color** | Multi-material 3D printing, colored models |
| **GLB** | **Yes - Full color + materials** | Engineering models, textured assets |
| **GLTF** | **Yes - Full color + materials** | Web-optimized engineering models |
| **STL** | No (monochrome) | Simple geometry, legacy files |

## Configuration

### Environment Variables

Required in `.env`:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_KEY` - Your Supabase anonymous/public key

### Nuxt Config

- **Modules**: @nuxtjs/tailwindcss, @nuxtjs/supabase, nitro-cloudflare-dev
- **Nitro Preset**: cloudflare-pages
- **Cloudflare**: Node compatibility enabled

## Troubleshooting

**Deployment: ASSETS Binding Error**
```
Error: The name 'ASSETS' is reserved in Pages projects
```
- **Solution**: Use `npm run deploy` or `wrangler pages deploy dist`
- **DO NOT** use `wrangler deploy` (that's for Workers, not Pages)
- The project is configured for Cloudflare Pages, not Workers

**Upload Failures**
- Verify `.env` contains correct Supabase credentials
- Confirm `3d-models` bucket exists and is **public**
- Check storage quota limits in Supabase dashboard
- Verify bucket CORS is configured to allow browser uploads

**Model Won't Display**
- Verify file is valid 3D model format
- Check browser console for loading errors
- Ensure Supabase bucket is set to **public** access
- Test the Supabase public URL directly in browser

**Color Not Showing**
- STL format does not support color - use 3MF or GLB/GLTF instead
- Verify color data exists in source file (check in another viewer)
- Ensure model was exported with material/color information

**Dev Server Issues**
- Auto-selects alternative port if 3000 occupied
- Ensure all dependencies installed: `npm install`
- Verify `.env` file exists with valid credentials
- Clear `.nuxt` cache: `rm -rf .nuxt` then rebuild

**Environment Variables Not Working in Production**
- Add environment variables in Cloudflare Pages dashboard
- Go to Settings → Environment Variables
- Add both `SUPABASE_URL` and `SUPABASE_KEY`
- Redeploy after adding variables

## License

MIT
