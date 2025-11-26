<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import type { ModelMetadata } from '~/composables/use3DModel'

const { signOut } = useAuth()
const user = useSupabaseUser()
const router = useRouter()
const supabase = useSupabaseClient()

const models = ref<ModelMetadata[]>([])
const loading = ref(true)
const error = ref('')
const searchQuery = ref('')
const selectedFolder = ref<string | null>(null)

// Redirect if not authenticated
onMounted(async () => {
  if (!user.value) {
    router.push('/auth/login')
    return
  }

  await loadModels()
})

const loadModels = async () => {
  loading.value = true
  error.value = ''

  try {
    const userId = user.value?.id || user.value?.sub
    if (!userId) throw new Error('User not authenticated')

    const { data, error: fetchError } = await supabase
      .from('e3d_models')
      .select('*')
      .eq('user_id', userId)
      .order('uploaded_at', { ascending: false })

    if (fetchError) throw fetchError

    models.value = data as ModelMetadata[]
  } catch (e: any) {
    error.value = e.message || 'Failed to load models'
    console.error('Error loading models:', e)
  } finally {
    loading.value = false
  }
}

// Get unique folders
const folders = computed(() => {
  const folderSet = new Set(models.value.map(m => m.folder_path).filter(Boolean))
  return ['All Models', ...Array.from(folderSet).sort()]
})

// Filter models by search and folder
const filteredModels = computed(() => {
  let filtered = models.value

  // Filter by folder
  if (selectedFolder.value && selectedFolder.value !== 'All Models') {
    filtered = filtered.filter(m => m.folder_path === selectedFolder.value)
  }

  // Filter by search query
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(m =>
      m.original_filename.toLowerCase().includes(query) ||
      m.title?.toLowerCase().includes(query) ||
      m.description?.toLowerCase().includes(query) ||
      m.tags?.some(tag => tag.toLowerCase().includes(query))
    )
  }

  return filtered
})

const handleLogout = async () => {
  try {
    await signOut()
    router.push('/auth/login')
  } catch (err) {
    console.error('Logout failed:', err)
  }
}

const formatFileSize = (bytes: number) => {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const deleteModel = async (model: ModelMetadata) => {
  if (!confirm(`Delete "${model.original_filename}"?`)) return

  try {
    const userId = user.value?.id || user.value?.sub
    if (!userId) throw new Error('User not authenticated')

    // Delete from storage
    const { error: storageError } = await supabase.storage
      .from('e3d-models')
      .remove([model.storage_path])

    if (storageError) throw storageError

    // Delete from database
    const { error: dbError } = await supabase
      .from('e3d_models')
      .delete()
      .eq('id', model.id)
      .eq('user_id', userId)

    if (dbError) throw dbError

    // Remove from local list
    models.value = models.value.filter(m => m.id !== model.id)
  } catch (e: any) {
    alert('Failed to delete model: ' + e.message)
    console.error('Delete error:', e)
  }
}

const copyShareLink = async (modelId: string) => {
  const url = `${window.location.origin}/viewer/${modelId}`
  try {
    await navigator.clipboard.writeText(url)
    alert('Share link copied to clipboard!')
  } catch (err) {
    console.error('Failed to copy:', err)
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-900 text-white">
    <!-- Header -->
    <header class="bg-gray-800 border-b border-gray-700">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <h1 class="text-2xl font-bold bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
              E3D Viewer
            </h1>
            <nav class="flex gap-2">
              <NuxtLink to="/" class="px-3 py-2 text-sm bg-gray-700 hover:bg-gray-600 rounded transition-colors">
                Upload
              </NuxtLink>
              <NuxtLink to="/dashboard" class="px-3 py-2 text-sm bg-blue-600 rounded transition-colors">
                My Models
              </NuxtLink>
            </nav>
          </div>

          <div v-if="user" class="flex items-center gap-3">
            <span class="text-sm text-gray-400">{{ user.email }}</span>
            <button
              @click="handleLogout"
              class="px-3 py-2 text-sm bg-gray-700 hover:bg-gray-600 rounded transition-colors"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Search and Filters -->
      <div class="mb-6 flex flex-col sm:flex-row gap-4">
        <!-- Search -->
        <div class="flex-1">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search models..."
            class="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        <!-- Folder Filter -->
        <select
          v-model="selectedFolder"
          class="px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option v-for="folder in folders" :key="folder" :value="folder === 'All Models' ? null : folder">
            {{ folder || 'Root' }}
          </option>
        </select>
      </div>

      <!-- Model Count -->
      <div class="mb-4 text-gray-400 text-sm">
        {{ filteredModels.length }} model{{ filteredModels.length !== 1 ? 's' : '' }}
        <span v-if="searchQuery || selectedFolder">
          (filtered from {{ models.length }} total)
        </span>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-white"></div>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="text-center py-12">
        <p class="text-red-400">{{ error }}</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="filteredModels.length === 0" class="text-center py-12">
        <svg class="w-16 h-16 text-gray-600 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>
        </svg>
        <p class="text-gray-400 text-lg mb-4">
          {{ searchQuery || selectedFolder ? 'No models match your search' : 'No models yet' }}
        </p>
        <NuxtLink
          v-if="!searchQuery && !selectedFolder"
          to="/"
          class="inline-block px-6 py-2 bg-blue-600 hover:bg-blue-700 rounded transition-colors"
        >
          Upload Your First Model
        </NuxtLink>
      </div>

      <!-- Models Grid -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        <div
          v-for="model in filteredModels"
          :key="model.id"
          class="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden hover:border-blue-500 transition-colors"
        >
          <!-- Thumbnail Placeholder -->
          <div class="aspect-video bg-gray-700 flex items-center justify-center relative group cursor-pointer"
               @click="router.push(`/viewer/${model.id}`)">
            <svg class="w-12 h-12 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
            </svg>
            <div class="absolute inset-0 bg-black bg-opacity-50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
              <span class="text-white font-medium">View Model</span>
            </div>
          </div>

          <!-- Model Info -->
          <div class="p-4">
            <h3 class="font-medium text-white mb-1 truncate" :title="model.title || model.original_filename">
              {{ model.title || model.original_filename }}
            </h3>
            <div class="text-xs text-gray-400 space-y-1 mb-3">
              <p>{{ formatFileSize(model.file_size) }} • {{ model.file_type.toUpperCase() }}</p>
              <p>{{ formatDate(model.uploaded_at) }}</p>
              <p v-if="model.folder_path" class="truncate">📁 {{ model.folder_path }}</p>
            </div>

            <!-- Actions -->
            <div class="flex gap-2">
              <button
                @click="router.push(`/viewer/${model.id}`)"
                class="flex-1 px-3 py-1 text-xs bg-blue-600 hover:bg-blue-700 rounded transition-colors"
              >
                View
              </button>
              <button
                @click="copyShareLink(model.id)"
                class="px-3 py-1 text-xs bg-gray-700 hover:bg-gray-600 rounded transition-colors"
                title="Copy share link"
              >
                Share
              </button>
              <button
                @click="deleteModel(model)"
                class="px-3 py-1 text-xs bg-red-600 hover:bg-red-700 rounded transition-colors"
                title="Delete model"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>
