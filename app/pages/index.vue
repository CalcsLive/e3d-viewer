<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'

const { uploadModel, checkDuplicate, getUserFolders } = use3DModel()
const { signOut } = useAuth()
const router = useRouter()
const user = useSupabaseUser()

const uploading = ref(false)
const uploadProgress = ref(0)
const error = ref('')
const selectedFile = ref<File | null>(null)
const selectedFolder = ref('')
const newFolderName = ref('')
const showNewFolder = ref(false)
const folders = ref<string[]>([])
const showDuplicateDialog = ref(false)
const duplicateInfo = ref<any>(null)

// Load user's folders when user changes
watch(user, async (newUser) => {
  if (newUser) {
    folders.value = await getUserFolders()
  } else {
    folders.value = []
  }
})

// Load user's folders on mount
onMounted(async () => {
  if (user.value) {
    folders.value = await getUserFolders()
  }
})

const handleLogout = async () => {
  try {
    await signOut()
    router.push('/auth/login')
  } catch (e: any) {
    error.value = e.message || 'Logout failed'
  }
}

const handleFileSelect = async (event: Event) => {
  const input = event.target as HTMLInputElement
  if (!input.files?.length) return

  const file = input.files[0]
  if (!file) return

  // Check authentication first
  if (!user.value) {
    error.value = 'Please sign in to upload models'
    router.push('/auth/login')
    return
  }

  selectedFile.value = file
  error.value = ''

  // Check for duplicates
  const duplicateCheck = await checkDuplicate(file, selectedFolder.value)

  if (duplicateCheck.isDuplicate && duplicateCheck.existingModel) {
    duplicateInfo.value = duplicateCheck.existingModel
    showDuplicateDialog.value = true
  } else {
    // No duplicate, proceed with upload
    await performUpload()
  }
}

const handleDuplicateAction = async (action: 'replace' | 'keep' | 'cancel') => {
  showDuplicateDialog.value = false

  if (action === 'cancel') {
    selectedFile.value = null
    return
  }

  if (action === 'replace') {
    // TODO: Implement replace functionality (delete old, upload new)
    error.value = 'Replace functionality coming soon. Please delete the old file first.'
    return
  }

  // Keep both - upload anyway
  await performUpload()
}

const performUpload = async () => {
  if (!selectedFile.value) return

  uploading.value = true
  uploadProgress.value = 0
  error.value = ''

  try {
    // Handle new folder creation
    let folderPath = selectedFolder.value
    if (showNewFolder.value && newFolderName.value.trim()) {
      folderPath = newFolderName.value.trim()
      folders.value.push(folderPath)
    }

    const result = await uploadModel(selectedFile.value, {
      folderPath,
      isPublic: true,  // Default to public for easy sharing
      onProgress: (progress) => {
        uploadProgress.value = progress
      }
    })

    // Navigate to viewer using model ID
    router.push(`/viewer/${result.id}`)
  } catch (e: any) {
    error.value = e.message || 'Upload failed. Please try again.'
    console.error(e)
  } finally {
    uploading.value = false
    uploadProgress.value = 0
    selectedFile.value = null
  }
}

const toggleNewFolder = () => {
  showNewFolder.value = !showNewFolder.value
  if (showNewFolder.value) {
    selectedFolder.value = ''
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-900 text-white flex flex-col items-center justify-center p-4">
    <!-- User menu in top-right corner -->
    <div v-if="user" class="absolute top-4 right-4">
      <div class="flex items-center gap-3 px-4 py-2 bg-gray-800 rounded-lg border border-gray-700">
        <NuxtLink
          to="/dashboard"
          class="px-3 py-1 text-sm bg-blue-600 hover:bg-blue-700 rounded transition-colors"
        >
          My Models
        </NuxtLink>
        <div class="text-sm border-l border-gray-600 pl-3">
          <p class="text-gray-400">Signed in as</p>
          <p class="font-medium">{{ user.email }}</p>
        </div>
        <button
          @click="handleLogout"
          class="px-3 py-1 text-sm bg-gray-700 hover:bg-gray-600 rounded transition-colors"
        >
          Logout
        </button>
      </div>
    </div>

    <h1 class="text-4xl font-bold mb-8 bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
      E3D Viewer
    </h1>

    <!-- Login prompt for non-authenticated users -->
    <div v-if="!user" class="w-full max-w-md mb-6 p-4 bg-blue-900 bg-opacity-30 border border-blue-700 rounded-xl">
      <p class="text-blue-300 text-sm mb-3">
        You need to sign in to upload and manage 3D models.
      </p>
      <div class="flex gap-2">
        <NuxtLink
          to="/auth/login"
          class="flex-1 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-center rounded-lg transition-colors"
        >
          Sign In
        </NuxtLink>
        <NuxtLink
          to="/auth/signup"
          class="flex-1 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white text-center rounded-lg transition-colors"
        >
          Sign Up
        </NuxtLink>
      </div>
    </div>

    <div class="w-full max-w-md p-8 bg-gray-800 rounded-xl shadow-2xl border border-gray-700">
      <div class="mb-6">
        <p class="text-gray-400 mb-4 text-center">Supported formats: STL, 3MF, GLB, GLTF</p>

        <!-- Folder selection (only for authenticated users) -->
        <div v-if="user" class="mb-4">
          <label class="block text-sm font-medium text-gray-300 mb-2">
            Save to folder (optional)
          </label>

          <div v-if="!showNewFolder" class="space-y-2">
            <select
              v-model="selectedFolder"
              class="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="">Root folder</option>
              <option v-for="folder in folders" :key="folder" :value="folder">
                {{ folder }}
              </option>
            </select>
            <button
              @click="toggleNewFolder"
              class="text-sm text-blue-400 hover:text-blue-300"
            >
              + Create new folder
            </button>
          </div>

          <div v-else class="space-y-2">
            <input
              v-model="newFolderName"
              type="text"
              placeholder="e.g., clients/acme or projects/2025"
              class="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <button
              @click="toggleNewFolder"
              class="text-sm text-gray-400 hover:text-gray-300"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>

      <label
        class="flex flex-col items-center justify-center w-full h-64 border-2 border-gray-600 border-dashed rounded-lg transition-colors relative overflow-hidden"
        :class="{
          'opacity-50 cursor-not-allowed': uploading || !user,
          'cursor-pointer hover:bg-gray-700': user && !uploading
        }"
      >
        <!-- Progress bar background -->
        <div
          v-if="uploading && uploadProgress > 0"
          class="absolute bottom-0 left-0 h-1 bg-gradient-to-r from-blue-500 to-purple-500 transition-all duration-300"
          :style="{ width: `${uploadProgress}%` }"
        ></div>

        <div class="flex flex-col items-center justify-center pt-5 pb-6">
          <svg v-if="!uploading" class="w-10 h-10 mb-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path></svg>
          <div v-else class="animate-spin rounded-full h-10 w-10 border-b-2 border-white mb-3"></div>

          <p class="mb-2 text-sm text-gray-400">
            <span class="font-semibold">
              {{ uploading ? 'Uploading...' : user ? 'Click to upload' : 'Sign in to upload' }}
            </span>
          </p>
          <p v-if="uploading && uploadProgress > 0" class="text-xs text-gray-500">
            {{ uploadProgress }}%
          </p>
        </div>
        <input
          v-if="user"
          type="file"
          class="hidden"
          accept=".stl,.3mf,.glb,.gltf"
          @change="handleFileSelect"
          :disabled="uploading"
        />
      </label>

      <p v-if="error" class="mt-4 text-red-400 text-sm text-center">{{ error }}</p>
    </div>

    <!-- Duplicate file dialog -->
    <div
      v-if="showDuplicateDialog"
      class="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4"
    >
      <div class="bg-gray-800 rounded-xl shadow-2xl border border-gray-700 max-w-md w-full p-6">
        <h2 class="text-xl font-bold text-white mb-4">Duplicate File Detected</h2>

        <div class="mb-6 text-gray-300 space-y-2">
          <p>You already uploaded this file:</p>
          <div class="bg-gray-700 p-3 rounded">
            <p class="font-medium">{{ duplicateInfo?.title || duplicateInfo?.original_filename }}</p>
            <p class="text-sm text-gray-400">
              Uploaded {{ new Date(duplicateInfo?.uploaded_at).toLocaleDateString() }}
            </p>
            <p class="text-sm text-gray-400">
              Folder: {{ duplicateInfo?.folder_path || 'Root' }}
            </p>
          </div>
          <p class="text-sm text-gray-400">What would you like to do?</p>
        </div>

        <div class="flex flex-col gap-2">
          <button
            @click="handleDuplicateAction('keep')"
            class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
          >
            Keep Both (Upload Anyway)
          </button>
          <button
            @click="handleDuplicateAction('replace')"
            class="px-4 py-2 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg transition-colors"
          >
            Replace Existing
          </button>
          <button
            @click="handleDuplicateAction('cancel')"
            class="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg transition-colors"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
