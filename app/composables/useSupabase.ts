// This composable is now a simple wrapper around the @nuxtjs/supabase client
// The @nuxtjs/supabase module automatically provides the client
export const useSupabase = () => {
    const client = useSupabaseClient()
    return client
}
