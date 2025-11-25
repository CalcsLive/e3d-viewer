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

### 6. Deploy to Cloudflare Pages

```bash
npm run deploy
```

Or link your Git repository to Cloudflare Pages for automatic deployments.

## Project Structure

```
nuxt-on-cloudflare/
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
| **STL** | No (monochrome) | Simple geometry, legacy files |
| **3MF** | **Yes - Full color** | Multi-material 3D printing, colored models |
| **GLB** | **Yes - Full color + materials** | Engineering models, textured assets |
| **GLTF** | **Yes - Full color + materials** | Web-optimized engineering models |

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

**Upload Failures**
- Verify `.env` contains correct Supabase credentials
- Confirm `3d-models` bucket exists and is public
- Check storage quota limits

**Model Won't Display**
- Verify file is valid 3D model format
- Check browser console for errors
- Ensure Supabase bucket CORS is configured

**Color Not Showing**
- STL format does not support color - use 3MF or GLB/GLTF instead
- Verify color data exists in source file
- Check model was exported with color information

**Dev Server Issues**
- Auto-selects alternative port if 3000 occupied
- Ensure all dependencies installed: `npm install`
- Verify `.env` file exists with valid credentials

## License

MIT
