export interface ModelMetadata {
    id: string
    original_filename: string
    file_size: number
    file_type: string
    storage_path: string
    uploaded_at: string
    upload_progress?: number
}

export const use3DModel = () => {
    const supabase = useSupabaseClient()

    // Generate a short unique ID (8 characters)
    const generateModelId = () => {
        return Math.random().toString(36).substring(2, 10)
    }

    const getModelUrl = (path: string) => {
        const { data } = supabase.storage
            .from('3d-models')
            .getPublicUrl(path)

        return data.publicUrl
    }

    // Get metadata by model ID
    const getModelMetadata = async (modelId: string): Promise<ModelMetadata | null> => {
        const { data, error } = await supabase
            .from('e3d_models')
            .select('*')
            .eq('id', modelId)
            .single()

        if (error) {
            console.error('Error fetching metadata:', error)
            return null
        }

        return data as ModelMetadata
    }

    // Upload with metadata tracking
    const uploadModel = async (
        file: File,
        onProgress?: (progress: number) => void
    ): Promise<{ id: string; path: string; url: string; metadata: ModelMetadata }> => {
        const modelId = generateModelId()
        const fileExt = file.name.split('.').pop()?.toLowerCase() || 'unknown'
        const fileName = `${modelId}.${fileExt}`
        const filePath = `models/${fileName}`

        // Create metadata object
        const metadata: ModelMetadata = {
            id: modelId,
            original_filename: file.name,
            file_size: file.size,
            file_type: fileExt,
            storage_path: filePath,
            uploaded_at: new Date().toISOString()
        }

        // Upload file to storage
        const { data: uploadData, error: uploadError } = await supabase.storage
            .from('3d-models')
            .upload(filePath, file, {
                cacheControl: '3600',
                upsert: false
            })

        if (uploadError) throw uploadError

        // Store metadata in database (if table exists, otherwise skip)
        try {
            const { error: metadataError } = await supabase
                .from('e3d_models')
                .insert(metadata)

            if (metadataError) {
                console.warn('Metadata storage not available, skipping:', metadataError.message)
            }
        } catch (e) {
            console.warn('Metadata table not found, continuing without metadata storage')
        }

        return {
            id: modelId,
            path: filePath,
            url: getModelUrl(filePath),
            metadata
        }
    }

    // Delete model and its metadata
    const deleteModel = async (modelId: string, storagePath: string) => {
        // Delete from storage
        const { error: storageError } = await supabase.storage
            .from('3d-models')
            .remove([storagePath])

        if (storageError) throw storageError

        // Delete metadata
        try {
            await supabase
                .from('e3d_models')
                .delete()
                .eq('id', modelId)
        } catch (e) {
            console.warn('Metadata deletion skipped')
        }
    }

    return {
        uploadModel,
        getModelUrl,
        getModelMetadata,
        deleteModel,
        generateModelId
    }
}
