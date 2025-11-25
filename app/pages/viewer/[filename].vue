<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import type { ModelMetadata } from '~/composables/use3DModel'

const route = useRoute()
const { getModelUrl, getModelMetadata } = use3DModel()

const modelId = computed(() => route.params.filename as string)
const metadata = ref<ModelMetadata | null>(null)
const modelUrl = ref<string>('')
const loading = ref(true)
const error = ref<string>('')
const showShareCopied = ref(false)

// Format file size
const formatFileSize = (bytes: number) => {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

// Format date
const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// Copy share link to clipboard
const copyShareLink = async () => {
  const url = window.location.href
  try {
    await navigator.clipboard.writeText(url)
    showShareCopied.value = true
    setTimeout(() => {
      showShareCopied.value = false
    }, 2000)
  } catch (err) {
    console.error('Failed to copy:', err)
  }
}

onMounted(async () => {
  try {
    loading.value = true

    // Fetch metadata by model ID
    const meta = await getModelMetadata(modelId.value)

    if (meta) {
      // Use metadata to get model URL
      metadata.value = meta
      modelUrl.value = getModelUrl(meta.storage_path)
    } else {
      // Model not found
      error.value = 'Model not found. It may have been deleted.'
    }
  } catch (e: any) {
    error.value = e.message || 'Failed to load model'
    console.error('Error loading model:', e)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="w-full h-screen bg-gray-900 relative">
    <!-- Loading state -->
    <div v-if="loading" class="flex items-center justify-center h-full text-white">
      <div class="text-center">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto mb-4"></div>
        <p>Loading model...</p>
      </div>
    </div>

    <!-- Error state -->
    <div v-else-if="error" class="flex items-center justify-center h-full text-white">
      <div class="text-center max-w-md px-4">
        <svg class="w-16 h-16 text-red-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <h2 class="text-2xl font-bold mb-2">Model Not Found</h2>
        <p class="text-gray-400 mb-6">{{ error }}</p>
        <NuxtLink to="/" class="inline-block bg-blue-500 hover:bg-blue-600 text-white px-6 py-2 rounded transition-colors">
          Upload a Model
        </NuxtLink>
      </div>
    </div>

    <!-- Viewer -->
    <template v-else>
      <ClientOnly>
        <Viewer3D :model-url="modelUrl" />
        <template #fallback>
          <div class="flex items-center justify-center h-full text-white">
            Loading 3D Viewer...
          </div>
        </template>
      </ClientOnly>

      <!-- Top bar with controls -->
      <div class="absolute top-4 left-4 right-4 z-10 flex items-start justify-between gap-4">
        <!-- Left: Back button -->
        <NuxtLink
          to="/"
          class="bg-gray-800 text-white px-4 py-2 rounded shadow hover:bg-gray-700 transition-colors flex items-center gap-2"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
          </svg>
          Back
        </NuxtLink>

        <!-- Right: Metadata panel -->
        <div class="bg-gray-800 text-white px-4 py-3 rounded shadow max-w-sm">
          <h3 v-if="metadata" class="font-semibold text-lg mb-2 truncate" :title="metadata.original_filename">
            {{ metadata.original_filename }}
          </h3>
          <h3 v-else class="font-semibold text-lg mb-2">3D Model</h3>

          <div v-if="metadata" class="text-sm text-gray-400 space-y-1">
            <p><span class="text-gray-500">Format:</span> {{ metadata.file_type.toUpperCase() }}</p>
            <p><span class="text-gray-500">Size:</span> {{ formatFileSize(metadata.file_size) }}</p>
            <p><span class="text-gray-500">Uploaded:</span> {{ formatDate(metadata.uploaded_at) }}</p>
          </div>

          <!-- Share button -->
          <button
            @click="copyShareLink"
            class="mt-3 w-full bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded transition-colors flex items-center justify-center gap-2"
          >
            <svg v-if="!showShareCopied" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"></path>
            </svg>
            <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            {{ showShareCopied ? 'Link Copied!' : 'Share Link' }}
          </button>
        </div>
      </div>
    </template>
  </div>
</template>
