<script setup lang="ts">
import * as THREE from 'three'
import { OrbitControls, TransformControls, STLLoader, ThreeMFLoader, GLTFLoader } from 'three-stdlib'
import { onMounted, onUnmounted, ref, watch } from 'vue'

const props = defineProps<{
  modelUrl?: string
}>()

const container = ref<HTMLDivElement | null>(null)
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
  
  // Clear previous model
  if (currentModel) {
    scene.remove(currentModel)
    transformControls.detach()
    currentModel = null
  }

  const extension = url.split('.').pop()?.toLowerCase()
  
  try {
    let geometry: THREE.BufferGeometry | THREE.Group
    
    if (extension === 'stl') {
      const loader = new STLLoader()
      geometry = await loader.loadAsync(url)
      const material = new THREE.MeshStandardMaterial({ color: 0x606060 })
      currentModel = new THREE.Mesh(geometry, material)
    } else if (extension === '3mf') {
      const loader = new ThreeMFLoader()
      const group = await loader.loadAsync(url)
      currentModel = group
    } else if (extension === 'glb' || extension === 'gltf') {
      const loader = new GLTFLoader()
      const gltf = await loader.loadAsync(url)
      currentModel = gltf.scene
    } else {
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
  } catch (error) {
    console.error('Error loading model:', error)
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

const toggleTransformMode = () => {
  if (!transformControls) return
  transformControls.setMode(transformControls.mode === 'translate' ? 'rotate' : 'translate')
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
    <div class="absolute top-4 right-4 z-10 flex gap-2">
      <button @click="toggleTransformMode" class="bg-white p-2 rounded shadow hover:bg-gray-100">
        Move/Rotate
      </button>
      <button @click="resetView" class="bg-white p-2 rounded shadow hover:bg-gray-100">
        Home
      </button>
    </div>
  </div>
</template>
