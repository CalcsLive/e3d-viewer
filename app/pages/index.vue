<script setup lang="ts">
import { ref } from 'vue'

const { uploadModel } = use3DModel()
const router = useRouter()
const uploading = ref(false)
const error = ref('')

const handleFile = async (event: Event) => {
  const input = event.target as HTMLInputElement
  if (!input.files?.length) return

  const file = input.files[0]
  uploading.value = true
  error.value = ''

  try {
    const { path } = await uploadModel(file)
    // Encode the path to handle slashes if any, though our path is simple
    router.push(`/viewer/${encodeURIComponent(path)}`)
  } catch (e: any) {
    error.value = e.message
    console.error(e)
  } finally {
    uploading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-900 text-white flex flex-col items-center justify-center p-4">
    <h1 class="text-4xl font-bold mb-8 bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
      E3D Viewer
    </h1>
    
    <div class="w-full max-w-md p-8 bg-gray-800 rounded-xl shadow-2xl border border-gray-700">
      <div class="mb-6 text-center">
        <p class="text-gray-400 mb-2">Supported formats: STL, 3MF, GLB, GLTF</p>
      </div>

      <label 
        class="flex flex-col items-center justify-center w-full h-64 border-2 border-gray-600 border-dashed rounded-lg cursor-pointer hover:bg-gray-700 transition-colors relative overflow-hidden"
        :class="{ 'opacity-50 cursor-not-allowed': uploading }"
      >
        <div class="flex flex-col items-center justify-center pt-5 pb-6">
          <svg v-if="!uploading" class="w-10 h-10 mb-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path></svg>
          <div v-else class="animate-spin rounded-full h-10 w-10 border-b-2 border-white mb-3"></div>
          
          <p class="mb-2 text-sm text-gray-400">
            <span class="font-semibold">{{ uploading ? 'Uploading...' : 'Click to upload' }}</span>
          </p>
        </div>
        <input 
          type="file" 
          class="hidden" 
          accept=".stl,.3mf,.glb,.gltf" 
          @change="handleFile"
          :disabled="uploading"
        />
      </label>

      <p v-if="error" class="mt-4 text-red-400 text-sm text-center">{{ error }}</p>
    </div>
  </div>
</template>
