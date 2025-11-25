<script setup lang="ts">
import { ref } from 'vue'

const { signIn } = useAuth()
const router = useRouter()

const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

const handleLogin = async () => {
  if (!email.value || !password.value) {
    error.value = 'Please enter email and password'
    return
  }

  loading.value = true
  error.value = ''

  try {
    await signIn(email.value, password.value)
    router.push('/')
  } catch (e: any) {
    error.value = e.message || 'Login failed. Please check your credentials.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-900 text-white flex flex-col items-center justify-center p-4">
    <div class="w-full max-w-md">
      <h1 class="text-4xl font-bold mb-2 text-center bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
        E3D Viewer
      </h1>
      <p class="text-gray-400 text-center mb-8">Sign in to your account</p>

      <div class="p-8 bg-gray-800 rounded-xl shadow-2xl border border-gray-700">
        <form @submit.prevent="handleLogin" class="space-y-6">
          <!-- Email -->
          <div>
            <label for="email" class="block text-sm font-medium text-gray-300 mb-2">
              Email
            </label>
            <input
              id="email"
              v-model="email"
              type="email"
              required
              autocomplete="email"
              class="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="you@example.com"
              :disabled="loading"
            />
          </div>

          <!-- Password -->
          <div>
            <label for="password" class="block text-sm font-medium text-gray-300 mb-2">
              Password
            </label>
            <input
              id="password"
              v-model="password"
              type="password"
              required
              autocomplete="current-password"
              class="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="••••••••"
              :disabled="loading"
            />
          </div>

          <!-- Error Message -->
          <p v-if="error" class="text-red-400 text-sm">{{ error }}</p>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="loading"
            class="w-full px-4 py-3 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-medium rounded-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
          >
            <div v-if="loading" class="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
            {{ loading ? 'Signing in...' : 'Sign In' }}
          </button>
        </form>

        <!-- Links -->
        <div class="mt-6 space-y-3 text-center text-sm">
          <p class="text-gray-400">
            Don't have an account?
            <NuxtLink to="/auth/signup" class="text-blue-400 hover:text-blue-300 font-medium">
              Sign up
            </NuxtLink>
          </p>
          <p class="text-gray-400">
            <NuxtLink to="/auth/forgot-password" class="text-gray-400 hover:text-gray-300">
              Forgot password?
            </NuxtLink>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
