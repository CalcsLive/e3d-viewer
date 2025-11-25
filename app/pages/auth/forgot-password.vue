<script setup lang="ts">
import { ref } from 'vue'

const { resetPassword } = useAuth()

const email = ref('')
const loading = ref(false)
const error = ref('')
const success = ref(false)

const handleResetPassword = async () => {
  if (!email.value) {
    error.value = 'Please enter your email address'
    return
  }

  loading.value = true
  error.value = ''

  try {
    await resetPassword(email.value)
    success.value = true
  } catch (e: any) {
    error.value = e.message || 'Failed to send reset email. Please try again.'
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
      <p class="text-gray-400 text-center mb-8">Reset your password</p>

      <div class="p-8 bg-gray-800 rounded-xl shadow-2xl border border-gray-700">
        <!-- Success Message -->
        <div v-if="success" class="mb-6 p-4 bg-green-900 border border-green-700 rounded-lg">
          <p class="text-green-300 text-sm mb-2">
            ✓ Password reset email sent!
          </p>
          <p class="text-green-200 text-xs">
            Check your inbox for instructions to reset your password.
          </p>
        </div>

        <form v-else @submit.prevent="handleResetPassword" class="space-y-6">
          <p class="text-gray-400 text-sm">
            Enter your email address and we'll send you instructions to reset your password.
          </p>

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

          <!-- Error Message -->
          <p v-if="error" class="text-red-400 text-sm">{{ error }}</p>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="loading"
            class="w-full px-4 py-3 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-medium rounded-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
          >
            <div v-if="loading" class="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
            {{ loading ? 'Sending...' : 'Send Reset Email' }}
          </button>
        </form>

        <!-- Links -->
        <div class="mt-6 text-center text-sm">
          <p class="text-gray-400">
            Remember your password?
            <NuxtLink to="/auth/login" class="text-blue-400 hover:text-blue-300 font-medium">
              Sign in
            </NuxtLink>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
