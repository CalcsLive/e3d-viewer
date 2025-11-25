<script setup lang="ts">
import * as THREE from 'three'
import { OrbitControls, TransformControls, STLLoader, ThreeMFLoader, GLTFLoader } from 'three-stdlib'
import { onMounted, onUnmounted, ref, watch } from 'vue'

const props = defineProps<{
  modelUrl?: string
}>()

const container = ref<HTMLDivElement | null>(null)
const loadingProgress = ref(0)
const isLoading = ref(false)
const loadError = ref('')
const transformMode = ref<'translate' | 'rotate' | 'hidden'>('translate')

let scene: THREE.Scene
let camera: THREE.PerspectiveCamera
let renderer: THREE.WebGLRenderer
let controls: OrbitControls
let transformControls: TransformControls
let animationId: number
let currentModel: THREE.Object3D | null = null

const init = () => {
  if (!container.value) return

  // Scene
  scene = new THREE.Scene()
  scene.background = new THREE.Color(0xf0f0f0)
  scene.add(new THREE.AmbientLight(0xffffff, 0.5))
  const dirLight = new THREE.DirectionalLight(0xffffff, 1)
  dirLight.position.set(5, 10, 7)
  scene.add(dirLight)

  // Camera
  camera = new THREE.PerspectiveCamera(75, container.value.clientWidth / container.value.clientHeight, 0.1, 1000)
  camera.position.set(5, 5, 5)

  // Renderer
  renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setSize(container.value.clientWidth, container.value.clientHeight)
  container.value.appendChild(renderer.domElement)

  // Controls
  controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true

  transformControls = new TransformControls(camera, renderer.domElement)
  transformControls.addEventListener('dragging-changed', (event) => {
    controls.enabled = !event.value
  })
  scene.add(transformControls)

  // Grid
  const gridHelper = new THREE.GridHelper(10, 10)
  scene.add(gridHelper)

  // Axes
  const axesHelper = new THREE.AxesHelper(5)
  scene.add(axesHelper)

  animate()
}

const loadModel = async (url: string) => {
  if (!scene) return

  isLoading.value = true
  loadingProgress.value = 0
  loadError.value = ''

  // Clear previous model
  if (currentModel) {
    scene.remove(currentModel)
    transformControls.detach()
    currentModel = null
  }

  const extension = url.split('.').pop()?.toLowerCase()

  try {
    let geometry: THREE.BufferGeometry | THREE.Group

    // Create loading manager for progress tracking
    const loadingManager = new THREE.LoadingManager()
    loadingManager.onProgress = (url, loaded, total) => {
      if (total > 0) {
        loadingProgress.value = Math.round((loaded / total) * 100)
      }
    }

    if (extension === 'stl') {
      const loader = new STLLoader(loadingManager)
      geometry = await loader.loadAsync(url)
      const material = new THREE.MeshStandardMaterial({ color: 0x606060 })
      currentModel = new THREE.Mesh(geometry, material)
    } else if (extension === '3mf') {
      const loader = new ThreeMFLoader(loadingManager)
      const group = await loader.loadAsync(url)
      currentModel = group
    } else if (extension === 'glb' || extension === 'gltf') {
      const loader = new GLTFLoader(loadingManager)
      const gltf = await loader.loadAsync(url)
      currentModel = gltf.scene
    } else {
      loadError.value = `Unsupported file format: ${extension}`
      console.warn('Unsupported file format:', extension)
      return
    }

    if (currentModel) {
      // Center and scale model
      const box = new THREE.Box3().setFromObject(currentModel)
      const center = box.getCenter(new THREE.Vector3())
      const size = box.getSize(new THREE.Vector3())

      const maxDim = Math.max(size.x, size.y, size.z)
      const scale = 5 / maxDim
      currentModel.scale.setScalar(scale)

      currentModel.position.sub(center.multiplyScalar(scale))
      currentModel.position.y += size.y * scale / 2 // Sit on grid

      scene.add(currentModel)
      transformControls.attach(currentModel)
    }
  } catch (error: any) {
    loadError.value = error.message || 'Failed to load 3D model'
    console.error('Error loading model:', error)
  } finally {
    isLoading.value = false
    loadingProgress.value = 100
  }
}

watch(() => props.modelUrl, (newUrl) => {
  if (newUrl) loadModel(newUrl)
})

const animate = () => {
  animationId = requestAnimationFrame(animate)
  controls.update()
  renderer.render(scene, camera)
}

const onResize = () => {
  if (!container.value || !camera || !renderer) return
  camera.aspect = container.value.clientWidth / container.value.clientHeight
  camera.updateProjectionMatrix()
  renderer.setSize(container.value.clientWidth, container.value.clientHeight)
}

const setTransformMode = (mode: 'translate' | 'rotate' | 'hidden') => {
  transformMode.value = mode
  if (!transformControls) return

  if (mode === 'hidden') {
    transformControls.visible = false
  } else {
    transformControls.visible = true
    transformControls.setMode(mode)
  }
}

onMounted(() => {
  init()
  window.addEventListener('resize', onResize)
  if (props.modelUrl) loadModel(props.modelUrl)
})

onUnmounted(() => {
  window.removeEventListener('resize', onResize)
  cancelAnimationFrame(animationId)
  renderer?.dispose()
})

const resetView = () => {
  if (!controls || !camera) return
  controls.reset()
  camera.position.set(5, 5, 5)
  camera.lookAt(0, 0, 0)
}

defineExpose({
  resetView
})
</script>

<template>
  <div ref="container" class="w-full h-full relative">
    <!-- Loading overlay -->
    <div
      v-if="isLoading"
      class="absolute inset-0 bg-gray-900 bg-opacity-75 flex items-center justify-center z-20"
    >
      <div class="text-center text-white">
        <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-white mx-auto mb-4"></div>
        <p class="text-lg mb-2">Loading 3D Model...</p>
        <p class="text-sm text-gray-400">{{ loadingProgress }}%</p>
      </div>
    </div>

    <!-- Error overlay -->
    <div
      v-if="loadError"
      class="absolute inset-0 bg-gray-900 bg-opacity-90 flex items-center justify-center z-20"
    >
      <div class="text-center text-white max-w-md px-4">
        <svg class="w-16 h-16 text-red-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <p class="text-lg">{{ loadError }}</p>
      </div>
    </div>

    <!-- Controls -->
    <div class="absolute top-4 right-4 z-10 flex gap-2">
      <!-- Transform mode button group -->
      <div class="bg-white rounded shadow flex">
        <button
          @click="setTransformMode('translate')"
          :class="[
            'px-3 py-2 transition-colors border-r border-gray-300',
            transformMode === 'translate'
              ? 'bg-blue-500 text-white'
              : 'hover:bg-gray-100'
          ]"
          title="Move mode"
        >
          Move
        </button>
        <button
          @click="setTransformMode('rotate')"
          :class="[
            'px-3 py-2 transition-colors border-r border-gray-300',
            transformMode === 'rotate'
              ? 'bg-blue-500 text-white'
              : 'hover:bg-gray-100'
          ]"
          title="Rotate mode"
        >
          Rotate
        </button>
        <button
          @click="setTransformMode('hidden')"
          :class="[
            'px-3 py-2 transition-colors',
            transformMode === 'hidden'
              ? 'bg-blue-500 text-white'
              : 'hover:bg-gray-100'
          ]"
          title="Hide gizmo"
        >
          Hide
        </button>
      </div>

      <!-- Home button -->
      <button
        @click="resetView"
        class="bg-white px-3 py-2 rounded shadow hover:bg-gray-100 transition-colors"
        title="Reset camera view"
      >
        Home
      </button>
    </div>
  </div>
</template>
