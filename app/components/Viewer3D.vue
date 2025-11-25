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

// View controls state
const showMoveGizmo = ref(true)
const showRotateGizmo = ref(false)
const showUCS = ref(true)
const showGround = ref(true)
const isPerspective = ref(true)
const currentView = ref<'top' | 'bottom' | 'front' | 'back' | 'left' | 'right' | 'iso'>('iso')

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
  transformControls.setMode('translate')
  scene.add(transformControls)

  // Grid (ground)
  const gridHelper = new THREE.GridHelper(10, 10)
  gridHelper.name = 'ground'
  scene.add(gridHelper)

  // Axes (UCS - User Coordinate System)
  const axesHelper = new THREE.AxesHelper(5)
  axesHelper.name = 'ucs'
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

// Toggle Move gizmo
const toggleMove = () => {
  showMoveGizmo.value = !showMoveGizmo.value
  if (showRotateGizmo.value) showRotateGizmo.value = false

  if (!transformControls) return
  if (showMoveGizmo.value) {
    transformControls.setMode('translate')
    transformControls.visible = true
  } else {
    transformControls.visible = false
  }
}

// Toggle Rotate gizmo
const toggleRotate = () => {
  showRotateGizmo.value = !showRotateGizmo.value
  if (showMoveGizmo.value) showMoveGizmo.value = false

  if (!transformControls) return
  if (showRotateGizmo.value) {
    transformControls.setMode('rotate')
    transformControls.visible = true
  } else {
    transformControls.visible = false
  }
}

// Toggle UCS (axes)
const toggleUCS = () => {
  showUCS.value = !showUCS.value
  if (!scene) return
  const axes = scene.getObjectByName('ucs')
  if (axes) axes.visible = showUCS.value
}

// Toggle Ground (grid)
const toggleGround = () => {
  showGround.value = !showGround.value
  if (!scene) return
  const grid = scene.getObjectByName('ground')
  if (grid) grid.visible = showGround.value
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

// Toggle Top/Bottom view
const toggleTopBottom = () => {
  if (!camera || !controls) return
  const distance = 10

  if (currentView.value === 'top') {
    currentView.value = 'bottom'
    camera.position.set(0, -distance, 0)
    camera.up.set(0, 0, 1)
  } else {
    currentView.value = 'top'
    camera.position.set(0, distance, 0)
    camera.up.set(0, 0, -1)
  }
  camera.lookAt(0, 0, 0)
  controls.update()
}

// Toggle Front/Back view
const toggleFrontBack = () => {
  if (!camera || !controls) return
  const distance = 10

  if (currentView.value === 'front') {
    currentView.value = 'back'
    camera.position.set(0, 0, -distance)
  } else {
    currentView.value = 'front'
    camera.position.set(0, 0, distance)
  }
  camera.up.set(0, 1, 0)
  camera.lookAt(0, 0, 0)
  controls.update()
}

// Toggle Left/Right view
const toggleLeftRight = () => {
  if (!camera || !controls) return
  const distance = 10

  if (currentView.value === 'left') {
    currentView.value = 'right'
    camera.position.set(distance, 0, 0)
  } else {
    currentView.value = 'left'
    camera.position.set(-distance, 0, 0)
  }
  camera.up.set(0, 1, 0)
  camera.lookAt(0, 0, 0)
  controls.update()
}

// Toggle between perspective and orthographic camera
const toggleCameraMode = () => {
  if (!camera || !renderer || !container.value) return

  isPerspective.value = !isPerspective.value

  const position = camera.position.clone()
  const target = controls.target.clone()

  // For now, we'll keep using perspective camera but adjust FOV for ortho-like effect
  // A full implementation would swap between PerspectiveCamera and OrthographicCamera
  if (!isPerspective.value) {
    // Simulate orthographic by reducing FOV and moving camera back
    camera.fov = 15
    const newDistance = camera.position.length() * 3
    camera.position.normalize().multiplyScalar(newDistance)
  } else {
    camera.fov = 75
  }

  camera.updateProjectionMatrix()
  controls.update()
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

    <!-- Engineering Control Panel (3x3 grid, bottom-right) -->
    <div class="absolute bottom-4 right-4 z-10 bg-white rounded shadow p-2">
      <div class="grid grid-cols-3 gap-1">
        <!-- Row 1: Move, Rotate, UCS -->
        <button
          @click="toggleMove"
          :class="[
            'px-3 py-2 text-sm font-medium rounded transition-colors',
            showMoveGizmo
              ? 'bg-blue-100 text-blue-700 border-2 border-blue-500'
              : 'hover:bg-gray-100 border-2 border-transparent'
          ]"
          title="Toggle Move gizmo"
        >
          Move
        </button>
        <button
          @click="toggleRotate"
          :class="[
            'px-3 py-2 text-sm font-medium rounded transition-colors',
            showRotateGizmo
              ? 'bg-red-100 text-red-700 border-2 border-red-500'
              : 'hover:bg-gray-100 border-2 border-transparent'
          ]"
          title="Toggle Rotate gizmo"
        >
          Rotate
        </button>
        <button
          @click="toggleUCS"
          :class="[
            'px-3 py-2 text-sm font-medium rounded transition-colors',
            showUCS
              ? 'bg-blue-100 text-blue-700 border-2 border-blue-500'
              : 'hover:bg-gray-100 border-2 border-transparent'
          ]"
          title="Toggle UCS (axes)"
        >
          UCS
        </button>

        <!-- Row 2: Home, Top/Bottom, Ground -->
        <button
          @click="resetView"
          class="px-3 py-2 text-sm font-medium rounded hover:bg-yellow-100 transition-colors border-2 border-transparent"
          title="Reset to isometric view"
        >
          Home
        </button>
        <button
          @click="toggleTopBottom"
          :class="[
            'px-3 py-2 text-sm font-medium rounded transition-colors',
            currentView === 'top' || currentView === 'bottom'
              ? 'bg-green-100 text-green-700 border-2 border-green-500'
              : 'hover:bg-gray-100 border-2 border-transparent'
          ]"
          :title="currentView === 'top' ? 'Switch to Bottom view' : 'Switch to Top view'"
        >
          {{ currentView === 'top' ? 'Top' : currentView === 'bottom' ? 'Bottom' : 'Top/Bottom' }}
        </button>
        <button
          @click="toggleGround"
          :class="[
            'px-3 py-2 text-sm font-medium rounded transition-colors',
            showGround
              ? 'bg-yellow-100 text-yellow-700 border-2 border-yellow-500'
              : 'hover:bg-gray-100 border-2 border-transparent'
          ]"
          title="Toggle ground grid"
        >
          Ground
        </button>

        <!-- Row 3: Left/Right, Front/Back, Ortho/Perspective -->
        <button
          @click="toggleLeftRight"
          :class="[
            'px-3 py-2 text-sm font-medium rounded transition-colors',
            currentView === 'left' || currentView === 'right'
              ? 'bg-green-100 text-green-700 border-2 border-green-500'
              : 'hover:bg-gray-100 border-2 border-transparent'
          ]"
          :title="currentView === 'left' ? 'Switch to Right view' : 'Switch to Left view'"
        >
          {{ currentView === 'left' ? 'Left' : currentView === 'right' ? 'Right' : 'Left/Right' }}
        </button>
        <button
          @click="toggleFrontBack"
          :class="[
            'px-3 py-2 text-sm font-medium rounded transition-colors',
            currentView === 'front' || currentView === 'back'
              ? 'bg-green-100 text-green-700 border-2 border-green-500'
              : 'hover:bg-gray-100 border-2 border-transparent'
          ]"
          :title="currentView === 'front' ? 'Switch to Back view' : 'Switch to Front view'"
        >
          {{ currentView === 'front' ? 'Front' : currentView === 'back' ? 'Back' : 'Front/Back' }}
        </button>
        <button
          @click="toggleCameraMode"
          :class="[
            'px-3 py-2 text-sm font-medium rounded transition-colors',
            !isPerspective
              ? 'bg-yellow-100 text-yellow-700 border-2 border-yellow-500'
              : 'hover:bg-gray-100 border-2 border-transparent'
          ]"
          :title="isPerspective ? 'Switch to Orthographic' : 'Switch to Perspective'"
        >
          {{ isPerspective ? 'Ortho' : 'Persp' }}
        </button>
      </div>
    </div>
  </div>
</template>
