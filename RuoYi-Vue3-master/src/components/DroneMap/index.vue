<template>
  <div ref="mapContainerRef" class="drone-map-container">
    <div :id="mapId" class="amap-container"></div>
    <div v-if="showControls" class="map-controls">
      <el-button-group>
        <el-button size="small" @click="enableDrawMode" :type="drawMode ? 'primary' : ''">
          <el-icon><Edit /></el-icon> 绘制航线
        </el-button>
        <el-button size="small" @click="clearRoute">
          <el-icon><Delete /></el-icon> 清除
        </el-button>
        <el-button size="small" @click="fitView">
          <el-icon><Aim /></el-icon> 适应视图
        </el-button>
      </el-button-group>
    </div>
    <div v-if="showInfo" class="map-info">
      <div class="info-panel">
        <div>点位数量: {{ points.length }}</div>
        <div>总距离: {{ totalDistance.toFixed(2) }} 公里</div>
        <div v-if="drawMode">点击地图添加航点，双击结束绘制</div>
      </div>
    </div>

    <!-- 任务动画覆盖层 -->
    <TaskAnimation
      v-if="showTaskAnimation"
      :task-info="taskInfo"
      :route-points="points"
      :animation-speed="animationSpeed"
      @progress-update="handleProgressUpdate"
      @status-change="handleStatusChange"
      @animation-complete="handleAnimationComplete"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch, computed, nextTick } from 'vue'
import { Edit, Delete, Aim } from '@element-plus/icons-vue'
import TaskAnimation from './TaskAnimation.vue'

const props = defineProps({
  // 地图配置
  center: {
    type: Array,
    default: () => [113.90, 22.50]
  },
  zoom: {
    type: Number,
    default: 12
  },
  // 功能控制
  showControls: {
    type: Boolean,
    default: true
  },
  showInfo: {
    type: Boolean,
    default: true
  },
  enableEdit: {
    type: Boolean,
    default: true
  },
  showTaskAnimation: {
    type: Boolean,
    default: false
  },
  autoFit: {
    type: Boolean,
    default: false
  },
  // 数据
  points: {
    type: Array,
    default: () => []
  },
  taskInfo: {
    type: Object,
    default: () => ({})
  },
  animationSpeed: {
    type: Number,
    default: 1
  }
})

const emit = defineEmits([
  'update:points', 'route-change', 'point-add', 'point-remove',
  'task-progress', 'task-status-change', 'task-complete'
])

const mapId = ref(`drone-map-${Math.random().toString(36).substring(2, 11)}`)
const mapContainerRef = ref(null)
const map = ref(null)
const markers = ref([])
const polyline = ref(null)
const movingMarker = ref(null)
const drawMode = ref(false)
const isDrawing = ref(false)
let resizeObserver = null

const normalizedPoints = computed(() => {
  if (!Array.isArray(props.points)) {
    return []
  }
  return props.points
    .map((point, index) => {
      const lng = Number(point.lng)
      const lat = Number(point.lat)
      if (!Number.isFinite(lng) || !Number.isFinite(lat)) {
        return null
      }
      return {
        ...point,
        seq: Number(point.seq) || index + 1,
        lng,
        lat
      }
    })
    .filter(Boolean)
})

// 计算总距离
const totalDistance = computed(() => {
  if (normalizedPoints.value.length < 2) return 0
  let distance = 0
  for (let i = 1; i < normalizedPoints.value.length; i++) {
    distance += calculateDistance(normalizedPoints.value[i - 1], normalizedPoints.value[i])
  }
  return distance
})

// 计算两点间距离（公里）
function calculateDistance(point1, point2) {
  const R = 6371 // 地球半径
  const dLat = (point2.lat - point1.lat) * Math.PI / 180
  const dLon = (point2.lng - point1.lng) * Math.PI / 180
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(point1.lat * Math.PI / 180) * Math.cos(point2.lat * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  return R * c
}

// 初始化地图
function initMap() {
  if (!window.AMap) {
    console.error('高德地图API未加载')
    return
  }

  map.value = new window.AMap.Map(mapId.value, {
    center: props.center,
    zoom: props.zoom,
    mapStyle: 'amap://styles/blue',
    showLabel: true,
    viewMode: '2D'
  })

  // 添加地图点击事件
  map.value.on('click', handleMapClick)
  map.value.on('dblclick', handleMapDoubleClick)

  // 绘制现有航线
  drawRoute()
  if ((props.autoFit || !props.enableEdit) && normalizedPoints.value.length > 0) {
    setTimeout(() => {
      fitView()
    }, 0)
  }
}

function handleMapResize() {
  if (!map.value) return
  map.value.resize()
  if ((props.autoFit || !props.enableEdit) && normalizedPoints.value.length > 0) {
    fitView()
  }
}

function getPositionByProgress(progressValue) {
  if (!normalizedPoints.value.length) return null
  const progress = Math.max(0, Math.min(100, Number(progressValue) || 0))
  const ratio = progress / 100
  const maxIndex = normalizedPoints.value.length - 1
  const targetIndex = Math.floor(ratio * maxIndex)

  if (targetIndex >= maxIndex) {
    const last = normalizedPoints.value[maxIndex]
    return [last.lng, last.lat]
  }

  const currentIndex = Math.min(targetIndex, maxIndex - 1)
  const nextIndex = currentIndex + 1
  const segmentProgress = (ratio * maxIndex) - currentIndex
  const current = normalizedPoints.value[currentIndex]
  const next = normalizedPoints.value[nextIndex]

  const lng = current.lng + (next.lng - current.lng) * segmentProgress
  const lat = current.lat + (next.lat - current.lat) * segmentProgress
  return [lng, lat]
}

function updateMovingMarker() {
  if (!map.value) return

  const isRunning = props.taskInfo?.status === 'running'
  const position = isRunning ? getPositionByProgress(props.taskInfo?.progress) : null

  if (!position) {
    if (movingMarker.value) {
      movingMarker.value.setMap(null)
      movingMarker.value = null
    }
    return
  }

  if (!movingMarker.value) {
    movingMarker.value = new window.AMap.Marker({
      position,
      content: '<div class="task-move-marker"></div>',
      offset: new window.AMap.Pixel(-7, -7)
    })
    movingMarker.value.setMap(map.value)
  } else {
    movingMarker.value.setPosition(position)
  }
}

// 处理地图点击
function handleMapClick(e) {
  if (!drawMode.value || !props.enableEdit) return

  const lnglat = e.lnglat
  const newPoint = {
    seq: normalizedPoints.value.length + 1,
    lng: lnglat.getLng(),
    lat: lnglat.getLat()
  }

  const updatedPoints = [...normalizedPoints.value, newPoint]
  isDrawing.value = true
  emit('update:points', updatedPoints)
  emit('point-add', newPoint)

  drawRoute()
}

function handleMapDoubleClick() {
  if (!drawMode.value || !props.enableEdit) return
  drawMode.value = false
  isDrawing.value = false
  map.value?.setDefaultCursor('default')
}

// 绘制航线
function drawRoute() {
  clearRouteDisplay()

  if (!map.value || normalizedPoints.value.length === 0) return

  // 绘制标记点
  normalizedPoints.value.forEach((point, index) => {
    const marker = new window.AMap.Marker({
      position: [point.lng, point.lat],
      content: `<div class="route-point-marker">${index + 1}</div>`,
      title: `航点 ${index + 1}`
    })

    if (props.enableEdit) {
      marker.on('dblclick', () => removePoint(index))
    }

    marker.setMap(map.value)
    markers.value.push(marker)
  })

  // 绘制连线
  if (normalizedPoints.value.length > 1) {
    const path = normalizedPoints.value.map(p => [p.lng, p.lat])
    polyline.value = new window.AMap.Polyline({
      path,
      strokeColor: '#409EFF',
      strokeWeight: 4,
      strokeStyle: 'solid',
      showDir: true
    })
    polyline.value.setMap(map.value)
  }

  updateMovingMarker()
}

// 清除航线显示
function clearRouteDisplay() {
  markers.value.forEach(marker => marker.setMap(null))
  markers.value = []
  if (polyline.value) {
    polyline.value.setMap(null)
    polyline.value = null
  }
}

// 启用绘制模式
function enableDrawMode() {
  drawMode.value = !drawMode.value
  if (drawMode.value) {
    isDrawing.value = false
    map.value?.setDefaultCursor('crosshair')
  } else {
    isDrawing.value = false
    map.value?.setDefaultCursor('default')
  }
}

// 清除航线
function clearRoute() {
  emit('update:points', [])
  clearRouteDisplay()
}

// 移除指定点
function removePoint(index) {
  const updatedPoints = normalizedPoints.value.filter((_, i) => i !== index)
  // 重新排序
  updatedPoints.forEach((point, i) => {
    point.seq = i + 1
  })
  emit('update:points', updatedPoints)
  emit('point-remove', index)
  drawRoute()
}

// 适应视图
function fitView() {
  if (!map.value || normalizedPoints.value.length === 0) return

  const bounds = new window.AMap.Bounds()
  normalizedPoints.value.forEach(point => {
    bounds.extend([point.lng, point.lat])
  })
  map.value.setBounds(bounds, false, [50, 50, 50, 50])
}

// 处理任务进度更新
function handleProgressUpdate(data) {
  emit('task-progress', data)
}

// 处理任务状态变化
function handleStatusChange(status) {
  emit('task-status-change', status)
}

// 处理动画完成
function handleAnimationComplete(data) {
  emit('task-complete', data)
}

// 加载高德地图API
function loadAMap() {
  return new Promise((resolve, reject) => {
    if (window.AMap) {
      resolve()
      return
    }

    const key = import.meta.env.VITE_AMAP_KEY || 'your-amap-key'
    const url = `https://webapi.amap.com/maps?v=1.4.15&key=${key}&plugin=AMap.Polyline`

    const script = document.createElement('script')
    script.src = url
    script.onload = () => {
      // 等待AMap对象可用
      const checkAMap = () => {
        if (window.AMap) {
          resolve()
        } else {
          setTimeout(checkAMap, 100)
        }
      }
      checkAMap()
    }
    script.onerror = reject
    document.head.appendChild(script)
  })
}

// 监听点变化
watch(() => props.points, (newPoints) => {
  if (map.value) {
    drawRoute()
    emit('route-change', newPoints)
    if ((props.autoFit || !props.enableEdit) && normalizedPoints.value.length > 0) {
      setTimeout(() => {
        fitView()
      }, 0)
    }
  }
}, { deep: true })

watch(() => [props.taskInfo?.progress, props.taskInfo?.status], () => {
  updateMovingMarker()
})

onMounted(async () => {
  try {
    await loadAMap()
    // 等待DOM更新完成
    await nextTick()
    initMap()
    if (window.ResizeObserver && mapContainerRef.value) {
      resizeObserver = new window.ResizeObserver(() => {
        handleMapResize()
      })
      resizeObserver.observe(mapContainerRef.value)
    }
  } catch (error) {
    console.error('地图加载失败:', error)
  }
})

// 重置动画状态
function resetAnimation() {
  // 通知TaskAnimation组件重置
  emit('task-status-change', 'pending')
}

// 监听任务信息变化，重置动画状态
watch(() => props.taskInfo, (newTaskInfo, oldTaskInfo) => {
  if (newTaskInfo && oldTaskInfo && newTaskInfo.taskId !== oldTaskInfo.taskId) {
    // 任务ID变化时重置动画
    nextTick(() => {
      resetAnimation()
    })
  }
}, { deep: true })

// 监听任务点变化，重置动画状态并刷新地图
watch(() => props.points, () => {
  nextTick(() => {
    resetAnimation()
    if (map.value) {
      drawRoute() // 重新绘制航线
      if (props.autoFit) {
        fitView() // 自动适应视图
      }
    }
  })
}, { deep: true })

onBeforeUnmount(() => {
  if (resizeObserver) {
    resizeObserver.disconnect()
    resizeObserver = null
  }
  if (movingMarker.value) {
    movingMarker.value.setMap(null)
    movingMarker.value = null
  }
  if (map.value) {
    map.value.destroy()
  }
})
</script>

<style scoped>
.drone-map-container {
  position: relative;
  width: 100%;
  height: 100%;
  min-height: 280px;
}

.amap-container {
  width: 100%;
  height: 100%;
}

:deep(.el-dialog__body) {
  padding: 20px;
}

.map-controls {
  position: absolute;
  top: 10px;
  right: 10px;
  z-index: 1001;
  background: white;
  padding: 8px;
  border-radius: 4px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.map-info {
  position: absolute;
  bottom: 20px;
  left: 10px;
  z-index: 1001;
}

.info-panel {
  background: rgba(255, 255, 255, 0.95);
  padding: 10px 15px;
  border-radius: 6px;
  font-size: 13px;
  box-shadow: 0 4px 16px 0 rgba(0, 0, 0, 0.15);
}

.info-panel > div {
  margin-bottom: 4px;
  color: #606266;
}

.info-panel > div:last-child {
  margin-bottom: 0;
  color: #409EFF;
  font-weight: bold;
}

:global(.route-point-marker) {
  background: #409EFF;
  color: white;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: bold;
  border: 2px solid white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  cursor: pointer;
  transition: all 0.3s;
}

:global(.route-point-marker:hover) {
  background: #66b1ff;
  transform: scale(1.1);
}

:global(.task-move-marker) {
  width: 14px;
  height: 14px;
  background: #67C23A;
  border: 2px solid #fff;
  border-radius: 50%;
  box-shadow: 0 0 10px rgba(103, 194, 58, 0.8);
}
</style>