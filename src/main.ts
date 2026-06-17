import './style.css'
import {
  Color3,
  Engine,
  HemisphericLight,
  Mesh,
  MeshBuilder,
  Scene,
  StandardMaterial,
  UniversalCamera,
  Vector3,
  Ray,
} from '@babylonjs/core'

const canvas = document.getElementById('renderCanvas') as HTMLCanvasElement
const engine = new Engine(canvas, true)

const inputMap: Record<string, boolean> = {}
let isPointerLocked = false
let verticalVelocity = 0
const gravity = -0.006
const jumpStrength = 0.14
const groundMoveSpeed = 0.07
const airMoveSpeed = 0.085
const playerHeight = 1.8
let isOnGround = false

const createMaterial = (scene: Scene, name: string, color: Color3) => {
  const mat = new StandardMaterial(name, scene)
  mat.diffuseColor = color
  return mat
}

const createScene = () => {
  const scene = new Scene(engine)
  scene.clearColor.set(0.1, 0.1, 0.12, 1)

  const camera = new UniversalCamera(
    'fpsCamera',
    new Vector3(0, playerHeight, -10),
    scene
  )

  camera.minZ = 0.1
  camera.fov = 1.2
  camera.rotation = new Vector3(0, 0, 0)

  const light = new HemisphericLight('light', new Vector3(0, 1, 0), scene)
  light.intensity = 1

  const ground = MeshBuilder.CreateGround(
    'ground',
    { width: 40, height: 40 },
    scene
  )
  ground.material = createMaterial(scene, 'groundMat', new Color3(0.22, 0.26, 0.3))

  const wallMaterial = createMaterial(scene, 'wallMat', new Color3(0.5, 0.5, 0.58))

  const walls: Mesh[] = []

  const wall1 = MeshBuilder.CreateBox('wall1', { width: 40, height: 6, depth: 1 }, scene)
  wall1.position = new Vector3(0, 3, 20)
  wall1.material = wallMaterial
  walls.push(wall1)

  const wall2 = wall1.clone('wall2')!
  wall2.position = new Vector3(0, 3, -20)
  walls.push(wall2)

  const wall3 = MeshBuilder.CreateBox('wall3', { width: 1, height: 6, depth: 40 }, scene)
  wall3.position = new Vector3(20, 3, 0)
  wall3.material = wallMaterial
  walls.push(wall3)

  const wall4 = wall3.clone('wall4')!
  wall4.position = new Vector3(-20, 3, 0)
  walls.push(wall4)

  const obstacleMaterial = createMaterial(scene, 'obstacleMat', new Color3(0.65, 0.4, 0.22))
  const obstacles: Mesh[] = []

  const obstaclePositions = [
    new Vector3(-6, 1, 4),
    new Vector3(-2, 1, 9),
    new Vector3(4, 1, 6),
    new Vector3(8, 1, -1),
  ]

  obstaclePositions.forEach((pos, index) => {
    const box = MeshBuilder.CreateBox(`obstacle${index}`, { size: 2 }, scene)
    box.position = pos
    box.material = obstacleMaterial
    obstacles.push(box)
  })

  const targetBoxes: Mesh[] = []
  const normalMat = createMaterial(scene, 'targetNormalMat', new Color3(0.8, 0.2, 0.2))
  const hitMat = createMaterial(scene, 'targetHitMat', new Color3(0.2, 0.9, 0.3))

  const targetPositions = [
    new Vector3(-8, 1, 6),
    new Vector3(-4, 1, 12),
    new Vector3(0, 1, 8),
    new Vector3(6, 1, 12),
    new Vector3(10, 1, 7),
  ]

  targetPositions.forEach((pos, index) => {
    const box = MeshBuilder.CreateBox(`targetBox${index}`, { size: 2 }, scene)
    box.position = pos
    box.material = normalMat
    targetBoxes.push(box)
  })

  const solidMeshes = [...walls, ...obstacles, ...targetBoxes]

  const requestPointerLock = () => {
    canvas.requestPointerLock()
  }

  canvas.addEventListener('click', () => {
    if (!isPointerLocked) {
      requestPointerLock()
    }
  })

  document.addEventListener('pointerlockchange', () => {
    isPointerLocked = document.pointerLockElement === canvas
  })

  document.addEventListener('mousemove', (event) => {
    if (!isPointerLocked) return

    const sensitivity = 0.0022

    camera.rotation.y += event.movementX * sensitivity
    camera.rotation.x += event.movementY * sensitivity

    const maxPitch = Math.PI / 2 - 0.01
    if (camera.rotation.x > maxPitch) camera.rotation.x = maxPitch
    if (camera.rotation.x < -maxPitch) camera.rotation.x = -maxPitch
  })

  window.addEventListener('keydown', (event) => {
    inputMap[event.code] = true
  })

  window.addEventListener('keyup', (event) => {
    inputMap[event.code] = false
  })

  const collidesWithBox = (position: Vector3, box: Mesh) => {
    const halfWidth = 1
    const halfDepth = 1
    const playerRadius = 0.4

    const minX = box.position.x - halfWidth - playerRadius
    const maxX = box.position.x + halfWidth + playerRadius
    const minZ = box.position.z - halfDepth - playerRadius
    const maxZ = box.position.z + halfDepth + playerRadius

    const minY = box.position.y - 1.5
    const maxY = box.position.y + 1.5

    return (
      position.x >= minX &&
      position.x <= maxX &&
      position.z >= minZ &&
      position.z <= maxZ &&
      position.y >= minY &&
      position.y <= maxY
    )
  }

  const collidesWithWalls = (position: Vector3) => {
    const limit = 19
    return (
      position.x <= -limit ||
      position.x >= limit ||
      position.z <= -limit ||
      position.z >= limit
    )
  }

  scene.onBeforeRenderObservable.add(() => {
    const forward = camera.getDirection(new Vector3(0, 0, 1))
    forward.y = 0
    forward.normalize()

    const right = camera.getDirection(new Vector3(1, 0, 0))
    right.y = 0
    right.normalize()

    const move = Vector3.Zero()

    if (inputMap['KeyW']) move.addInPlace(forward)
    if (inputMap['KeyS']) move.subtractInPlace(forward)
    if (inputMap['KeyA']) move.subtractInPlace(right)
    if (inputMap['KeyD']) move.addInPlace(right)

    if (move.length() > 0) {
      move.normalize()
      move.scaleInPlace(isOnGround ? groundMoveSpeed : airMoveSpeed)
    }

    const nextPosition = camera.position.add(new Vector3(move.x, 0, move.z))

    let blocked = collidesWithWalls(nextPosition)

    if (!blocked) {
      for (const mesh of solidMeshes) {
        if (collidesWithBox(nextPosition, mesh)) {
          blocked = true
          break
        }
      }
    }

    if (!blocked) {
      camera.position.x = nextPosition.x
      camera.position.z = nextPosition.z
    }

    if (camera.position.y <= playerHeight) {
      camera.position.y = playerHeight
      verticalVelocity = 0
      isOnGround = true
    } else {
      isOnGround = false
    }

    if (inputMap['Space'] && isOnGround) {
      verticalVelocity = jumpStrength
      isOnGround = false
    }

    verticalVelocity += gravity
    camera.position.y += verticalVelocity

    if (camera.position.y < playerHeight) {
      camera.position.y = playerHeight
      verticalVelocity = 0
      isOnGround = true
    }
  })

  window.addEventListener('pointerdown', () => {
    if (!isPointerLocked) return

    const forward = camera.getDirection(Vector3.Forward())
    const origin = camera.position.clone()
    const ray = new Ray(origin, forward, 100)

    const hit = scene.pickWithRay(ray, (mesh) => {
      return targetBoxes.includes(mesh as Mesh)
    })

    if (hit?.pickedMesh) {
      hit.pickedMesh.material = hitMat

      setTimeout(() => {
        if (hit.pickedMesh) {
          hit.pickedMesh.material = normalMat
        }
      }, 120)
    }
  })

  return scene
}

const scene = createScene()

engine.runRenderLoop(() => {
  scene.render()
})

window.addEventListener('resize', () => {
  engine.resize()
})