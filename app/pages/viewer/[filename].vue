<script setup lang="ts">
const route = useRoute()
const { getModelUrl } = use3DModel()

// Decode the path parameter
const modelPath = decodeURIComponent(route.params.filename as string)
const modelUrl = getModelUrl(modelPath)
</script>

<template>
  <div class="w-full h-screen bg-gray-900">
    <ClientOnly>
      <Viewer3D :model-url="modelUrl" />
      <template #fallback>
        <div class="flex items-center justify-center h-full text-white">
          Loading Viewer...
        </div>
      </template>
    </ClientOnly>
    
    <NuxtLink 
      to="/" 
      class="absolute top-4 left-4 z-10 bg-gray-800 text-white px-4 py-2 rounded shadow hover:bg-gray-700 transition-colors"
    >
      &larr; Upload Another
    </NuxtLink>
  </div>
</template>
