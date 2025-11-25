export const use3DModel = () => {
    const supabase = useSupabaseClient()

    const getModelUrl = (path: string) => {
        const { data } = supabase.storage
            .from('3d-models')
            .getPublicUrl(path)

        return data.publicUrl
    }

    const uploadModel = async (file: File) => {
        const fileExt = file.name.split('.').pop()
        const fileName = `${Math.random().toString(36).substring(2)}-${Date.now()}.${fileExt}`
        const filePath = `models/${fileName}`

        const { data, error } = await supabase.storage
            .from('3d-models')
            .upload(filePath, file)

        if (error) throw error

        return {
            path: filePath,
            url: getModelUrl(filePath)
        }
    }

    return {
        uploadModel,
        getModelUrl
    }
}
