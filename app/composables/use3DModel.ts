export interface ModelMetadata {
    id: string
    user_id: string
    folder_path: string
    file_hash: string
    original_filename: string
    file_size: number
    file_type: string
    source_modified_at?: string
    storage_path: string
    thumbnail_path?: string
    title?: string
    description?: string
    tags?: string[]
    is_public: boolean
    allow_download: boolean
    uploaded_at: string
    updated_at: string
    last_viewed_at?: string
    view_count: number
    download_count: number
    upload_progress?: number
}

export interface DuplicateCheckResult {
    isDuplicate: boolean
    existingModel?: ModelMetadata
}

export const use3DModel = () => {
    const supabase = useSupabaseClient()
    const user = useSupabaseUser()

    // Generate a short unique ID (8 characters)
    const generateModelId = () => {
        return Math.random().toString(36).substring(2, 10)
    }

    // Calculate SHA-256 hash of file content
    const calculateFileHash = async (file: File): Promise<string> => {
        const buffer = await file.arrayBuffer()
        const hashBuffer = await crypto.subtle.digest('SHA-256', buffer)
        const hashArray = Array.from(new Uint8Array(hashBuffer))
        return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
    }

    // Hybrid deduplication check (quick check first, then hash if needed)
    const checkDuplicate = async (
        file: File,
        folderPath: string = ''
    ): Promise<DuplicateCheckResult> => {
        const userId = user.value?.id || user.value?.sub

        if (!userId) {
            return { isDuplicate: false }
        }
        const filename = file.name
        const fileSize = file.size

        // Step 1: Quick check - same filename + size in same folder
        const { data: quickMatches, error: quickError } = await supabase
            .from('e3d_models')
            .select('*')
            .eq('user_id', userId)
            .eq('folder_path', folderPath)
            .eq('original_filename', filename)
            .eq('file_size', fileSize)

        if (quickError || !quickMatches || quickMatches.length === 0) {
            return { isDuplicate: false }
        }

        // Step 2: Found potential duplicate - compute hash to confirm
        const fileHash = await calculateFileHash(file)

        // Step 3: Check if hash matches
        const exactMatch = quickMatches.find(m => m.file_hash === fileHash)

        if (exactMatch) {
            return {
                isDuplicate: true,
                existingModel: exactMatch as ModelMetadata
            }
        }

        // Same filename/size but different content (file was modified)
        return { isDuplicate: false }
    }

    const getModelUrl = (path: string) => {
        const { data } = supabase.storage
            .from('e3d-models')
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

    // Upload with metadata tracking and folder support
    const uploadModel = async (
        file: File,
        options: {
            folderPath?: string
            title?: string
            description?: string
            tags?: string[]
            isPublic?: boolean
            onProgress?: (progress: number) => void
        } = {}
    ): Promise<{ id: string; path: string; url: string; metadata: ModelMetadata }> => {
        // Get user ID from Supabase user object
        // The user object from useSupabaseUser() contains the JWT claims
        // The user ID is in the 'sub' (subject) field, not 'id'
        const userId = user.value?.id || user.value?.sub

        if (!userId) {
            throw new Error('User must be authenticated to upload models')
        }

        const {
            folderPath = '',
            title,
            description,
            tags = [],
            isPublic = false,
            onProgress
        } = options
        const modelId = generateModelId()
        const fileExt = file.name.split('.').pop()?.toLowerCase() || 'unknown'
        const fileName = `${modelId}.${fileExt}`

        // Build storage path: users/{user_id}/{folder_path}/{model_id}.ext
        const folderPrefix = folderPath ? `${folderPath}/` : ''
        const filePath = `users/${userId}/${folderPrefix}${fileName}`

        // Calculate file hash for deduplication
        const fileHash = await calculateFileHash(file)

        // Get source file modification time
        const sourceModifiedAt = file.lastModified
            ? new Date(file.lastModified).toISOString()
            : undefined

        // Create metadata object
        const metadata: Partial<ModelMetadata> = {
            id: modelId,
            user_id: userId,
            folder_path: folderPath,
            file_hash: fileHash,
            original_filename: file.name,
            file_size: file.size,
            file_type: fileExt,
            source_modified_at: sourceModifiedAt,
            storage_path: filePath,
            title: title || file.name,
            description,
            tags,
            is_public: isPublic,
            allow_download: true,
            uploaded_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            view_count: 0,
            download_count: 0
        }

        // Upload file to storage
        const { data: uploadData, error: uploadError } = await supabase.storage
            .from('e3d-models')
            .upload(filePath, file, {
                cacheControl: '3600',
                upsert: false
            })

        if (uploadError) throw uploadError

        // Store metadata in database
        const { error: metadataError } = await supabase
            .from('e3d_models')
            .insert(metadata)

        if (metadataError) {
            // If metadata insert fails, clean up storage
            await supabase.storage.from('e3d-models').remove([filePath])
            throw metadataError
        }

        return {
            id: modelId,
            path: filePath,
            url: getModelUrl(filePath),
            metadata: metadata as ModelMetadata
        }
    }

    // Delete model and its metadata
    const deleteModel = async (modelId: string, storagePath: string) => {
        // Delete from storage
        const { error: storageError } = await supabase.storage
            .from('e3d-models')
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

    // Get user's folder structure
    const getUserFolders = async (): Promise<string[]> => {
        const userId = user.value?.id || user.value?.sub

        if (!userId) return []

        const { data, error } = await supabase
            .from('e3d_models')
            .select('folder_path')
            .eq('user_id', userId)

        if (error || !data) return []

        // Get unique folder paths
        const folders = [...new Set(data.map(m => m.folder_path).filter(Boolean))]
        return folders.sort()
    }

    return {
        uploadModel,
        getModelUrl,
        getModelMetadata,
        deleteModel,
        generateModelId,
        calculateFileHash,
        checkDuplicate,
        getUserFolders
    }
}
