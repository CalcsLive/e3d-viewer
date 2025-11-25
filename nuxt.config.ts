// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  modules: [
    '@nuxtjs/tailwindcss',
    '@nuxtjs/supabase',
    'nitro-cloudflare-dev'
  ],
  supabase: {
    redirect: false
  },
  css: ['~/assets/css/main.css'],
  runtimeConfig: {
    public: {
      supabaseUrl: process.env.SUPABASE_URL,
      supabaseKey: process.env.SUPABASE_KEY
    }
  },
  nitro: {
    preset: "cloudflare-pages",
    cloudflare: {
      deployConfig: true,
      nodeCompat: true
    }
  }
})
