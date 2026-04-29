<template>
  <div class="task-animation-overlay">
    <div v-if="showControls" class="animation-controls">
      <el-card class="control-panel">
        <div class="control-header">
          <span>任务执行模拟</span>
          <el-tag :type="statusColor" size="small">{{ statusText }}</el-tag>
        </div>

        <div class="control-content">
          <div class="progress-section">
            <div class="progress-label">执行进度 (距离基准)</div>
            <el-progress
              :percentage="progress"
              :format="formatProgress"
              :status="progressStatus"
            />
          </div>

          <div class="info-section">
            <div class="info-grid">
              <div class="info-item">
                <span class="label">已用时间:</span>
                <span class="value">{{ formatTime(elapsedTime) }}</span>
              </div>
              <div class="info-item">
                <span class="label">预计剩余:</span>
                <span class="value">{{ formatTime(remainingTime) }}</span>
              </div>
              <div class="info-item">
                <span class="label">当前速度:</span>
                <span class="value">{{ currentSpeed.toFixed(1) }} km/h</span>
              </div>
              <div class="info-item">
                <span class="label">平均速度:</span>
                <span class="value">{{ averageSpeed.toFixed(1) }} km/h</span>
              </div>
              <div class="info-item">
                <span class="label">总距离:</span>
                <span class="value">{{ totalDistance.toFixed(2) }} km</span>
              </div>
              <div class="info-item">
                <span class="label">已完成:</span>
                <span class="value">{{ completedDistance.toFixed(2) }} km</span>
              </div>
              <div class="info-item">
                <span class="label">当前航点:</span>
                <span class="value">{{ currentPointIndex + 1 }}/{{ routePoints.length }}</span>
              </div>
              <div class="info-item">
                <span class="label">环境因素:</span>
                <span class="value">{{ environmentalFactor }}</span>
              </div>
            </div>
          </div>

          <div class="environment-section" v-if="showEnvironmentalFactors">
            <div class="environment-label">环境模拟</div>
            <div class="environment-controls">
              <el-tag :type="weatherType" size="small" effect="plain">
                {{ weatherCondition }}
              </el-tag>
              <el-tag :type="currentType" size="small" effect="plain">
                海流: {{ currentStrength }}
              </el-tag>
            </div>
          </div>

          <div class="speed-control">
            <div class="speed-label">播放速度</div>
            <el-slider
              v-model="localSpeed"
              :min="0.1"
              :max="10"
              :step="0.1"
              :format-tooltip="formatSpeed"
              size="small"
            />
            <div class="speed-presets">
              <el-button-group size="small">
                <el-button
                  v-for="preset in speedPresets"
                  :key="preset"
                  :type="localSpeed === preset ? 'primary' : ''"
                  @click="localSpeed = preset"
                >
                  {{ preset }}x
                </el-button>
              </el-button-group>
            </div>
          </div>

          <div class="control-buttons">
            <el-button-group>
              <el-button
                type="primary"
                size="small"
                @click="startAnimation"
                :disabled="isRunning || progress >= 100"
              >
                <el-icon><VideoPlay /></el-icon> 开始
              </el-button>
              <el-button
                type="warning"
                size="small"
                @click="pauseAnimation"
                :disabled="!isRunning"
              >
                <el-icon><VideoPause /></el-icon> 暂停
              </el-button>
              <el-button
                type="info"
                size="small"
                @click="resetAnimation"
              >
                <el-icon><Refresh /></el-icon> 重置
              </el-button>
              <el-button
                type="success"
                size="small"
                @click="toggleEnvironmentalFactors"
                :disabled="isRunning"
              >
                <el-icon><MostlyCloudy /></el-icon> 环境
              </el-button>
            </el-button-group>
          </div>
        </div>
      </el-card>
    </div>

    <!-- 任务信息悬浮窗 -->
    <div v-if="showTaskInfo" class="task-info-float">
      <el-card class="task-info-card">
        <div class="task-info-header">
          <div class="task-name">{{ taskInfo?.taskName }}</div>
          <div class="task-status">
            <el-tag size="small" :type="statusColor">{{ statusText }}</el-tag>
          </div>
        </div>
        <div class="task-info-content">
          <div class="info-row">
            <span>设备: {{ taskInfo?.deviceName }}</span>
          </div>
          <div class="info-row">
            <span>航线: {{ taskInfo?.routeName }}</span>
          </div>
          <div class="info-row">
            <span>进度: {{ formatProgress(progress) }}</span>
          </div>
          <div class="info-row">
            <span>速度: {{ currentSpeed.toFixed(1) }} km/h</span>
          </div>
          <div class="info-row" v-if="currentPosition">
            <span>位置: {{ currentPosition.lat.toFixed(4) }}, {{ currentPosition.lng.toFixed(4) }}</span>
          </div>
          <div class="info-row" v-if="routeComplexity">
            <span>复杂度: {{ routeComplexity }}</span>
          </div>
        </div>
      </el-card>
    </div>

    <!-- 实时位置标记 -->
    <div v-if="showPositionMarker && currentPosition" class="position-marker">
      <div class="marker-dot"></div>
      <div class="marker-pulse"></div>
    </div>

    <!-- 路线复杂度分析 -->
    <div v-if="showRouteAnalysis" class="route-analysis-panel">
      <el-card class="analysis-card">
        <div class="analysis-header">
          <span>航线分析</span>
          <el-button size="small" @click="showRouteAnalysis = false">
            <el-icon><Close /></el-icon>
          </el-button>
        </div>
        <div class="analysis-content">
          <div class="analysis-item">
            <span>总距离: {{ totalDistance.toFixed(2) }} km</span>
          </div>
          <div class="analysis-item">
            <span>转弯次数: {{ turnCount }}</span>
          </div>
          <div class="analysis-item">
            <span>复杂度评级: {{ routeComplexity }}</span>
          </div>
          <div class="analysis-item">
            <span>预计能耗: {{ estimatedEnergy.toFixed(1) }}%</span>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue'
import { VideoPlay, VideoPause, Refresh, MostlyCloudy, Close } from '@element-plus/icons-vue'

const props = defineProps({
  // 任务数据
  taskInfo: {
    type: Object,
    default: () => ({})
  },
  // 航线点
  routePoints: {
    type: Array,
    default: () => []
  },
  // 显示控制
  showControls: {
    type: Boolean,
    default: true
  },
  showTaskInfo: {
    type: Boolean,
    default: true
  },
  // 模拟参数
  animationSpeed: {
    type: Number,
    default: 1 // 1倍速
  }
})

const emit = defineEmits(['progress-update', 'status-change', 'animation-complete'])

// 动画状态
const isRunning = ref(false)
const isPaused = ref(false)
const progress = ref(0)
const currentPointIndex = ref(0)
const elapsedTime = ref(0)
const localSpeed = ref(props.animationSpeed)
const showEnvironmentalFactors = ref(false)
const showRouteAnalysis = ref(false)

const DEFAULT_SPEED_KMH = 20
const TICK_MS = 1000

// 环境模拟状态
const weatherCondition = ref('晴朗')
const currentStrength = ref('弱')
const environmentalImpact = ref(1.0)

// 速度预设
const speedPresets = [0.5, 1, 2, 5]

// 动画定时器
let animationTimer = null
let progressTimer = null

// 计算属性
const status = computed(() => {
  // 对于模拟模式，始终显示为模拟中
  if (props.taskInfo?.isSimulation) {
    if (isPaused.value) return 'paused'
    if (progress.value >= 100) return 'simulating'  // 模拟完成但仍显示为模拟中
    if (isRunning.value) return 'simulating'
    return 'pending'
  }

  if (!isRunning.value && progress.value === 0) return 'pending'
  if (isRunning.value && !isPaused.value) return 'running'
  if (isPaused.value) return 'paused'
  if (progress.value >= 100) return 'completed'
  return 'pending'
})

const statusText = computed(() => {
  const statusMap = {
    pending: '待执行',
    running: '执行中',
    simulating: '模拟中',
    paused: '已暂停',
    completed: '已完成'
  }
  return statusMap[status.value] || '未知状态'
})

const statusColor = computed(() => {
  const colorMap = {
    pending: 'info',
    running: 'primary',
    simulating: 'warning',
    paused: 'warning',
    completed: 'success'
  }
  return colorMap[status.value] || 'info'
})

const progressStatus = computed(() => {
  if (progress.value >= 100) return 'success'
  if (progress.value > 0) return 'primary'
  return ''
})

const remainingTime = computed(() => {
  if (progress.value === 0 || elapsedTime.value === 0) {
    return Math.round(estimatedTotalTime.value)
  }

  const remainingProgress = 100 - progress.value
  const progressPerMinute = progress.value / elapsedTime.value
  if (!Number.isFinite(progressPerMinute) || progressPerMinute <= 0) return 0
  return Math.max(0, Math.round(remainingProgress / progressPerMinute))
})

const estimatedTotalTime = computed(() => {
  const baseTime = calculateEstimatedDuration()
  return baseTime * environmentalImpact.value
})

const taskSpeed = computed(() => {
  const candidates = [
    props.taskInfo?.speed,
    props.taskInfo?.deviceSpeed,
    props.taskInfo?.cruiseSpeed,
    props.taskInfo?.avgSpeed,
    props.taskInfo?.speedKmh,
    props.taskInfo?.speedKmH
  ]

  for (const value of candidates) {
    const speed = Number(value)
    if (Number.isFinite(speed) && speed > 0) return speed
  }

  return DEFAULT_SPEED_KMH
})

const effectiveSpeed = computed(() => {
  const baseSpeed = taskSpeed.value
  if (baseSpeed <= 0) return 0
  return showEnvironmentalFactors.value ? baseSpeed / environmentalImpact.value : baseSpeed
})

const currentSpeed = computed(() => {
  if (elapsedTime.value === 0) return 0
  const completed = completedDistance.value
  return (completed / elapsedTime.value) * 60 // 公里/小时
})

const averageSpeed = computed(() => {
  if (elapsedTime.value === 0) return 0
  const totalElapsedHours = elapsedTime.value / 60
  return completedDistance.value / totalElapsedHours
})

const totalDistance = computed(() => {
  return calculateTotalDistance()
})

const completedDistance = computed(() => {
  if (routePoints.value.length < 2) return 0

  let distance = 0
  const progressRatio = progress.value / 100

  // 计算已完成的路段距离
  for (let i = 1; i < routePoints.value.length; i++) {
    const segmentProgress = i / (routePoints.value.length - 1)
    if (segmentProgress <= progressRatio) {
      // 完整路段
      distance += calculateDistance(routePoints.value[i - 1], routePoints.value[i])
    } else if (segmentProgress > progressRatio && distance > 0) {
      // 部分完成的路段
      const prevSegmentProgress = (i - 1) / (routePoints.value.length - 1)
      const partialProgress = (progressRatio - prevSegmentProgress) / (1 / (routePoints.value.length - 1))
      const segmentDistance = calculateDistance(routePoints.value[i - 1], routePoints.value[i])
      distance += segmentDistance * partialProgress
      break
    }
  }

  return distance
})

const routePoints = computed(() => {
  return props.routePoints || []
})

const currentPosition = computed(() => {
  if (routePoints.value.length === 0) return null

  const progressRatio = progress.value / 100
  const targetIndex = Math.floor(progressRatio * (routePoints.value.length - 1))

  if (targetIndex >= routePoints.value.length - 1) {
    return routePoints.value[routePoints.value.length - 1]
  }

  // 计算两点之间的插值位置
  const currentIndex = Math.min(targetIndex, routePoints.value.length - 2)
  const nextIndex = currentIndex + 1

  const segmentProgress = (progressRatio * (routePoints.value.length - 1)) - currentIndex

  const current = routePoints.value[currentIndex]
  const next = routePoints.value[nextIndex]

  return {
    lat: current.lat + (next.lat - current.lat) * segmentProgress,
    lng: current.lng + (next.lng - current.lng) * segmentProgress,
    seq: current.seq
  }
})

const showPositionMarker = computed(() => {
  return isRunning.value && currentPosition.value
})

const environmentalFactor = computed(() => {
  if (!showEnvironmentalFactors.value) return '无影响'

  let factors = []
  if (weatherCondition.value !== '晴朗') factors.push(weatherCondition.value)
  if (currentStrength.value !== '弱') factors.push(`海流${currentStrength.value}`)

  return factors.length > 0 ? factors.join(', ') : '正常'
})

const weatherType = computed(() => {
  const types = {
    '晴朗': 'success',
    '多云': 'info',
    '阴天': 'warning',
    '小雨': 'danger',
    '大风': 'danger'
  }
  return types[weatherCondition.value] || 'info'
})

const currentType = computed(() => {
  const types = {
    '弱': 'success',
    '中': 'warning',
    '强': 'danger'
  }
  return types[currentStrength.value] || 'info'
})

const routeComplexity = computed(() => {
  const turns = calculateTurnCount()
  const distance = totalDistance.value

  if (turns < 3 && distance < 5) return '简单'
  if (turns < 6 && distance < 15) return '中等'
  if (turns < 10 && distance < 30) return '复杂'
  return '极复杂'
})

const turnCount = computed(() => {
  return calculateTurnCount()
})

const estimatedEnergy = computed(() => {
  const baseEnergy = totalDistance.value * 2 // 基础能耗：每公里2%
  const complexityMultiplier = routeComplexity.value === '简单' ? 1 :
                              routeComplexity.value === '中等' ? 1.2 :
                              routeComplexity.value === '复杂' ? 1.5 : 2.0
  const environmentalMultiplier = showEnvironmentalFactors.value ? 1.3 : 1.0

  return Math.min(baseEnergy * complexityMultiplier * environmentalMultiplier, 100)
})

// 计算总距离
function calculateTotalDistance() {
  if (routePoints.value.length < 2) return 0
  let distance = 0
  for (let i = 1; i < routePoints.value.length; i++) {
    distance += calculateDistance(routePoints.value[i - 1], routePoints.value[i])
  }
  return distance
}

// 计算两点间距离
function calculateDistance(point1, point2) {
  const R = 6371 // 地球半径（公里）
  const dLat = (point2.lat - point1.lat) * Math.PI / 180
  const dLon = (point2.lng - point1.lng) * Math.PI / 180
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(point1.lat * Math.PI / 180) * Math.cos(point2.lat * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  return R * c
}

// 计算转弯次数
function calculateTurnCount() {
  if (routePoints.value.length < 3) return 0

  let turns = 0
  for (let i = 1; i < routePoints.value.length - 1; i++) {
    const angle = calculateAngle(routePoints.value[i - 1], routePoints.value[i], routePoints.value[i + 1])
    if (Math.abs(angle) > 30) { // 角度变化大于30度算作转弯
      turns++
    }
  }
  return turns
}

// 计算三点之间的角度
function calculateAngle(pointA, pointB, pointC) {
  const ab = { x: pointB.lng - pointA.lng, y: pointB.lat - pointA.lat }
  const bc = { x: pointC.lng - pointB.lng, y: pointC.lat - pointB.lat }

  const dotProduct = ab.x * bc.x + ab.y * bc.y
  const magnitudeAB = Math.sqrt(ab.x * ab.x + ab.y * ab.y)
  const magnitudeBC = Math.sqrt(bc.x * bc.x + bc.y * bc.y)

  const cosAngle = dotProduct / (magnitudeAB * magnitudeBC)
  const angleRad = Math.acos(Math.max(-1, Math.min(1, cosAngle)))

  return angleRad * 180 / Math.PI
}

// 计算预估时长
function calculateEstimatedDuration() {
  const distance = totalDistance.value
  const speed = taskSpeed.value
  if (distance <= 0 || speed <= 0) return 0
  return (distance / speed) * 60
}

// 格式化时间显示
function formatTime(minutes) {
  if (minutes < 60) {
    return `${Math.round(minutes)} 分钟`
  }
  const hours = Math.floor(minutes / 60)
  const mins = Math.round(minutes % 60)
  return `${hours}小时${mins}分钟`
}

// 格式化进度显示
function formatProgress(percentage) {
  return `${percentage.toFixed(1)}%`
}

// 格式化速度显示
function formatSpeed(value) {
  return `${value}x`
}

// 开始动画
function startAnimation() {
  // 只有在进度为0或者任务真正开始时才重置
  if (progress.value >= 100 && elapsedTime.value === 0) {
    resetAnimation()
  }

  if (totalDistance.value <= 0 || taskSpeed.value <= 0) {
    progress.value = 0
    return
  }

  isRunning.value = true
  isPaused.value = false

  // 距离基准的进度更新定时器
  progressTimer = setInterval(() => {
    // 只有在未达到100%时才继续更新
    if (progress.value >= 100) {
      completeAnimation()
      return
    }

    const deltaMinutes = (TICK_MS / 60000) * localSpeed.value
    elapsedTime.value += deltaMinutes

    const speed = effectiveSpeed.value
    const distanceTraveled = speed * (elapsedTime.value / 60)

    if (totalDistance.value > 0) {
      const calculatedProgress = Math.min(100, (distanceTraveled / totalDistance.value) * 100)
      // 对进度进行取整处理，避免过多小数位
      progress.value = Math.floor(calculatedProgress * 10) / 10  // 保留1位小数
    } else {
      progress.value = 0
    }

    const targetIndex = Math.floor((progress.value / 100) * (routePoints.value.length - 1))
    currentPointIndex.value = Math.min(Math.max(targetIndex, 0), routePoints.value.length - 1)

    emit('progress-update', {
      progress: progress.value,
      currentPoint: currentPosition.value,
      elapsedTime: elapsedTime.value,
      speed: speed,
      distance: completedDistance.value,
      environmentalFactors: showEnvironmentalFactors.value
    })

    // 检查是否完成，但不要立即重置
    if (progress.value >= 100) {
      completeAnimation()
    }
  }, TICK_MS)

  emit('status-change', 'running')
}

// 暂停动画
function pauseAnimation() {
  isPaused.value = true
  isRunning.value = false
  clearInterval(progressTimer)
  emit('status-change', 'paused')
}

// 重置动画
function resetAnimation() {
  isRunning.value = false
  isPaused.value = false
  progress.value = 0
  currentPointIndex.value = 0
  elapsedTime.value = 0
  clearInterval(progressTimer)
  emit('status-change', 'pending')
}

// 完成动画
function completeAnimation() {
  isRunning.value = false
  isPaused.value = false
  clearInterval(progressTimer)

  // 确保进度保持在100%
  progress.value = 100

  emit('status-change', 'completed')
  emit('animation-complete', {
    finalProgress: progress.value,
    totalTime: elapsedTime.value,
    isSimulation: props.taskInfo?.isSimulation || false,
    totalDistance: totalDistance.value,
    averageSpeed: averageSpeed.value,
    environmentalFactors: showEnvironmentalFactors.value
  })
}

// 切换环境因素
function toggleEnvironmentalFactors() {
  showEnvironmentalFactors.value = !showEnvironmentalFactors.value
  if (showEnvironmentalFactors.value) {
    // 随机生成环境条件
    const weathers = ['晴朗', '多云', '阴天', '小雨', '大风']
    const currents = ['弱', '中', '强']

    weatherCondition.value = weathers[Math.floor(Math.random() * weathers.length)]
    currentStrength.value = currents[Math.floor(Math.random() * currents.length)]

    // 计算环境影响系数
    let impact = 1.0
    if (weatherCondition.value === '小雨') impact += 0.2
    if (weatherCondition.value === '大风') impact += 0.4
    if (currentStrength.value === '中') impact += 0.1
    if (currentStrength.value === '强') impact += 0.3

    environmentalImpact.value = impact
  } else {
    environmentalImpact.value = 1.0
  }
}

// 监听任务信息变化
watch(() => props.taskInfo, (newVal, oldVal) => {
  if (newVal) {
    // 检测是否为新任务（任务ID变化或首次加载）
    const isNewTask = !oldVal || (oldVal && newVal.taskId !== oldVal.taskId)

    if (isNewTask) {
      // 新任务时强制重置动画
      resetAnimation()
      showRouteAnalysis.value = true // 新任务显示分析面板

      // 对于模拟模式，始终启动动画
      if (newVal.isSimulation) {
        startAnimation()
      } else if (newVal.status === 'running') {
        startAnimation()
      }
    } else {
      // 根据任务状态自动同步动画状态
      if (newVal.isSimulation && !isRunning.value) {
        // 模拟模式始终保持运行状态
        startAnimation()
      } else if (newVal.status === 'running' && !isRunning.value && !newVal.isSimulation) {
        startAnimation()
      } else if (newVal.status === 'completed' && progress.value < 100 && !newVal.isSimulation) {
        progress.value = 100
        completeAnimation()
      } else if (newVal.status === 'pending' && !newVal.isSimulation) {
        resetAnimation()
      }
    }
  }
}, { deep: true })

// 监听外部速度变化
watch(() => props.animationSpeed, (newSpeed) => {
  if (newSpeed !== localSpeed.value) {
    localSpeed.value = newSpeed
  }
})

onMounted(() => {
  // 对于模拟模式，始终启动动画
  if (props.taskInfo?.isSimulation) {
    startAnimation()
  } else if (props.taskInfo?.status === 'running') {
    startAnimation()
  }
})

// 组件卸载时清理定时器
onBeforeUnmount(() => {
  clearInterval(progressTimer)
  clearInterval(animationTimer)
})
</script>

<style scoped>
.task-animation-overlay {
  position: relative;
  width: 100%;
  height: 100%;
}

.animation-controls {
  position: absolute;
  top: 20px;
  left: 20px;
  z-index: 1000;
  width: 320px;
  max-height: calc(100vh - 40px);
  overflow-y: auto;
}

.control-panel {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 8px;
}

.control-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid #ebeef5;
}

.control-header span {
  font-weight: 600;
  color: #303133;
  font-size: 16px;
}

.control-content {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.progress-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.progress-label {
  font-size: 13px;
  color: #606266;
  font-weight: 500;
}

.info-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  padding: 4px 0;
}

.info-item .label {
  color: #606266;
  font-weight: 400;
}

.info-item .value {
  color: #303133;
  font-weight: 600;
  font-family: monospace;
}

.environment-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 10px;
  background: rgba(245, 247, 250, 0.8);
  border-radius: 4px;
}

.environment-label {
  font-size: 13px;
  color: #606266;
  font-weight: 500;
}

.environment-controls {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.speed-control {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.speed-label {
  font-size: 13px;
  color: #606266;
  font-weight: 500;
}

.speed-presets {
  margin-top: 8px;
}

.speed-presets :deep(.el-button) {
  min-width: 40px;
  padding: 4px 8px;
}

.control-buttons {
  display: flex;
  justify-content: center;
  padding-top: 10px;
  border-top: 1px solid #ebeef5;
}

.task-info-float {
  position: absolute;
  bottom: 20px;
  right: 20px;
  z-index: 1000;
  width: 280px;
}

.task-info-card {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 8px;
}

.task-info-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
}

.task-name {
  font-weight: 600;
  color: #303133;
  font-size: 14px;
  flex: 1;
  margin-right: 10px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.task-info-content {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.info-row {
  font-size: 12px;
  color: #606266;
  display: flex;
  justify-content: space-between;
}

/* 位置标记样式 */
.position-marker {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 2000;
  pointer-events: none;
}

.marker-dot {
  width: 14px;
  height: 14px;
  background: #409EFF;
  border: 3px solid white;
  border-radius: 50%;
  box-shadow: 0 0 15px rgba(64, 158, 255, 0.9);
  position: relative;
  z-index: 2;
}

.marker-pulse {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 28px;
  height: 28px;
  border: 2px solid #409EFF;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    transform: translate(-50%, -50%) scale(0.5);
    opacity: 1;
  }
  100% {
    transform: translate(-50%, -50%) scale(2.5);
    opacity: 0;
  }
}

/* 路线分析面板 */
.route-analysis-panel {
  position: absolute;
  top: 20px;
  right: 20px;
  z-index: 1000;
  width: 250px;
}

.analysis-card {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 8px;
}

.analysis-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
}

.analysis-header span {
  font-weight: 600;
  color: #303133;
  font-size: 14px;
}

.analysis-content {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.analysis-item {
  font-size: 12px;
  color: #606266;
  display: flex;
  justify-content: space-between;
  padding: 4px 0;
}

:deep(.el-progress-bar__outer) {
  border-radius: 2px;
  background-color: #f0f2f5;
}

:deep(.el-progress__text) {
  font-size: 12px !important;
  min-width: 45px;
  font-weight: 600;
}

:deep(.el-tag) {
  border-radius: 4px;
}

:deep(.el-slider__button) {
  width: 12px;
  height: 12px;
}

:deep(.el-slider__bar) {
  background-color: #409EFF;
}

@media (max-width: 768px) {
  .animation-controls {
    width: calc(100% - 40px);
    left: 20px;
    right: 20px;
    max-height: 60vh;
  }

  .task-info-float {
    width: calc(100% - 40px);
    right: 20px;
    left: 20px;
    bottom: 80px;
  }

  .route-analysis-panel {
    width: calc(100% - 40px);
    right: 20px;
    left: 20px;
    top: auto;
    bottom: 20px;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 480px) {
  .animation-controls {
    max-height: 50vh;
  }

  .control-buttons {
    flex-wrap: wrap;
    gap: 8px;
  }

  .control-buttons :deep(.el-button-group) {
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
  }

  .control-buttons :deep(.el-button) {
    flex: 1;
    min-width: 60px;
  }
}
</style>