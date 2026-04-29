<template>
  <div class="app-container">
    <el-form :inline="true" :model="queryParams" ref="queryRef" v-show="showSearch">
      <el-form-item label="任务名称"><el-input v-model="queryParams.taskName" clearable @keyup.enter="handleQuery" /></el-form-item>
      <el-form-item label="执行人"><el-input v-model="queryParams.executor" clearable @keyup.enter="handleQuery" /></el-form-item>
      <el-form-item label="状态">
        <el-select v-model="queryParams.status" clearable style="width: 180px">
          <el-option v-for="dict in drone_task_status" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5"><el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['drone:task:add']">新增</el-button></el-col>
      <el-col :span="1.5"><el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete" v-hasPermi="['drone:task:remove']">删除</el-button></el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
    </el-row>

    <el-table v-loading="loading" :data="taskList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" />
      <el-table-column label="任务名称" prop="taskName" />
      <el-table-column label="执行人" prop="executor" />
      <el-table-column label="设备" prop="deviceName" />
      <el-table-column label="航线" prop="routeName" />
      <el-table-column label="状态" prop="status">
        <template #default="scope">
          <dict-tag
            v-if="!scope.row.isSimulation"
            :options="drone_task_status"
            :value="scope.row.status"
          />
          <el-tag
            v-else
            type="warning"
            size="small"
            effect="plain"
          >
            模拟中
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="计划开始" prop="plannedStartTime" width="180"><template #default="scope">{{ parseTime(scope.row.plannedStartTime) }}</template></el-table-column>
      <el-table-column label="操作" width="420" align="center">
        <template #default="scope">
          <el-button link type="primary" @click="handleStart(scope.row)" v-if="scope.row.status==='pending'" v-hasPermi="['drone:task:start']">开始</el-button>
          <el-button link type="success" @click="handleFinish(scope.row)" v-if="scope.row.status==='running'" v-hasPermi="['drone:task:finish']">完成</el-button>
          <el-button link type="warning" @click="handleCancel(scope.row)" v-if="scope.row.status==='pending' || scope.row.status==='running'" v-hasPermi="['drone:task:cancel']">取消</el-button>
          <el-button link type="danger" @click="handleDelete(scope.row)" v-if="scope.row.status==='completed' || scope.row.status==='canceled'" v-hasPermi="['drone:task:remove']">删除</el-button>
          <el-button link type="info" @click="handleViewMap(scope.row)" v-hasPermi="['drone:task:detail']">地图</el-button>
          <el-button link type="warning" @click="handleSimulate(scope.row)" v-if="scope.row.status==='pending'" v-hasPermi="['drone:task:detail']">模拟</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="title" v-model="open" width="620px" append-to-body>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="任务名称" prop="taskName"><el-input v-model="form.taskName" /></el-form-item>
        <el-form-item label="执行人" prop="executor"><el-input v-model="form.executor" /></el-form-item>
        <el-form-item label="开始时间" prop="plannedStartTime">
          <el-date-picker
            v-model="form.plannedStartTime"
            type="datetime"
            value-format="YYYY-MM-DD HH:mm:ss"
            :disabled-date="disablePastDate"
          />
        </el-form-item>
        <el-form-item label="绑定设备" prop="deviceId">
          <el-select v-model="form.deviceId" placeholder="请选择设备" filterable :loading="optionLoading" style="width: 100%">
            <el-option v-for="item in deviceOptions" :key="item.deviceId" :label="item.deviceName + '（' + item.deviceCode + '）'" :value="item.deviceId" />
          </el-select>
        </el-form-item>
        <el-form-item label="绑定航线" prop="routeId">
          <el-select v-model="form.routeId" placeholder="请选择航线" filterable :loading="optionLoading" style="width: 100%">
            <el-option v-for="item in routeOptions" :key="item.routeId" :label="item.routeName" :value="item.routeId" />
          </el-select>
        </el-form-item>
        <el-form-item label="任务描述" prop="taskDesc"><el-input v-model="form.taskDesc" type="textarea" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitForm">确定</el-button>
        <el-button @click="cancel">取消</el-button>
      </template>
    </el-dialog>

    <!-- 地图查看对话框 -->
    <el-dialog :title="mapDialogTitle" v-model="mapDialogVisible" width="1000px" append-to-body @closed="handleMapDialogClosed">
      <div class="task-map-container">
        <div class="task-info-summary">
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item label="任务名称">{{ mapTaskInfo.taskName }}</el-descriptions-item>
            <el-descriptions-item label="设备">{{ mapTaskInfo.deviceName }}</el-descriptions-item>
            <el-descriptions-item label="航线">{{ mapTaskInfo.routeName }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <dict-tag
                v-if="!mapTaskInfo.isSimulation"
                :options="drone_task_status"
                :value="mapTaskInfo.status"
              />
              <el-tag
                v-else
                type="warning"
                size="small"
                effect="plain"
              >
                模拟中
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="进度" :span="2">
              <el-progress :percentage="mapTaskInfo.progress" :format="formatProgress" />
            </el-descriptions-item>
          </el-descriptions>
        </div>

        <div class="map-wrapper">
          <DroneMap
            :key="mapComponentKey"
            v-model:points="mapTaskInfo.routePoints"
            :enable-edit="false"
            :show-controls="false"
            :show-info="false"
            :auto-fit="true"
            :show-task-animation="mapTaskInfo.isSimulation === true"
            :task-info="mapTaskInfo"
            :center="getMapCenter(mapTaskInfo.routePoints)"
            :zoom="12"
            @task-complete="handleTaskComplete"
            @task-progress="handleProgressUpdate"
          />
        </div>
      </div>
    </el-dialog>

  </div>
</template>

<script setup name="DroneTask">
import { ref, reactive, toRefs, getCurrentInstance, onBeforeUnmount, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { addTask, cancelTask, delTask, finishTask, getTask, listTask, startTask, updateTaskProgress, getTaskProgress } from '@/api/drone/task'
import { listDevice } from '@/api/drone/device'
import { getRoute, listRoute } from '@/api/drone/route'
import DroneMap from '@/components/DroneMap/index.vue'

const { proxy } = getCurrentInstance()
const { drone_task_status } = useDict('drone_task_status')

// 添加模拟状态到字典
if (drone_task_status.value) {
  drone_task_status.value.push({
    value: 'simulating',
    label: '模拟中',
    elTagType: 'warning'
  })
}

const loading = ref(false)
const showSearch = ref(true)
const taskList = ref([])
const total = ref(0)
const open = ref(false)
const title = ref('')
const multiple = ref(true)
const ids = ref([])
const optionLoading = ref(false)
const deviceOptions = ref([])
const routeOptions = ref([])
const mapDialogVisible = ref(false)
const mapDialogTitle = ref('任务地图')
const mapTaskInfo = ref({})
const mapComponentKey = ref(0)

const DEFAULT_SPEED_KMH = 20
const PROGRESS_TICK_MS = 1000
const progressTimers = new Map()

const data = reactive({
  queryParams: { pageNum: 1, pageSize: 10, taskName: undefined, executor: undefined, status: undefined },
  form: {},
  rules: {
    taskName: [{ required: true, message: '任务名称不能为空', trigger: 'blur' }],
    plannedStartTime: [
      { required: true, message: '开始时间不能为空', trigger: 'change' },
      { validator: validatePlannedStartTime, trigger: 'change' }
    ],
    deviceId: [{ required: true, message: '请选择设备', trigger: 'change' }],
    routeId: [{ required: true, message: '请选择航线', trigger: 'change' }]
  }
})

const { queryParams, form, rules } = toRefs(data)

function getList() {
  loading.value = true
  listTask(queryParams.value).then(res => {
    let data = res
    if (typeof data === 'string') {
      try {
        data = JSON.parse(data)
      } catch (e) {
        data = {}
      }
    }

    let rows = Array.isArray(data?.rows)
      ? data.rows
      : (Array.isArray(data?.data?.rows) ? data.data.rows : (Array.isArray(data) ? data : []))

    if (typeof rows === 'string') {
      try {
        const parsedRows = JSON.parse(rows)
        rows = Array.isArray(parsedRows) ? parsedRows : []
      } catch (e) {
        rows = []
      }
    }

    // 保留现有任务的进度
    const existingTasks = new Map(taskList.value.map(task => [task.taskId, task]))
    taskList.value = rows.map(row => {
      const existing = existingTasks.get(row.taskId)
      if (existing && existing.progress !== undefined && existing.progress !== null) {
        row.progress = existing.progress
      }
      return row
    })

    // 清理所有任务的isSimulation标记（只有当前在模拟的任务才应该是模拟状态）
    taskList.value.forEach(task => {
      task.isSimulation = false
    })

    try {
      (taskList.value || []).forEach(task => {
        if (task.status === 'running') {
          // 检查进度是否已经达到100%，如果是则不应再启动模拟
          if (task.progress >= 100) {
            task.status = 'completed'
            stopProgressSimulation(task.taskId)
          } else {
            startProgressSimulation(task)
          }
        } else {
          stopProgressSimulation(task.taskId)
        }
      })
    } catch (e) {
      // ignore
    }
    total.value = Number(data?.total ?? data?.data?.total ?? rows.length)
    loading.value = false
  }).catch(() => {
    loading.value = false
  })
}

function reset() {
  form.value = { taskName: undefined, executor: undefined, plannedStartTime: undefined, deviceId: undefined, routeId: undefined, taskDesc: undefined }
  proxy.resetForm('formRef')
}

function handleQuery() { queryParams.value.pageNum = 1; getList() }
function resetQuery() { proxy.resetForm('queryRef'); handleQuery() }
function handleSelectionChange(selection) { ids.value = selection.map(item => item.taskId); multiple.value = !selection.length }
async function handleAdd() {
  reset()
  await loadSelectableOptions()
  open.value = true
  title.value = '新增任务'
}
function cancel() { open.value = false; reset() }

async function loadSelectableOptions() {
  optionLoading.value = true
  try {
    const [deviceRes, routeRes, pendingTaskRes, runningTaskRes] = await Promise.all([
      listDevice({ pageNum: 1, pageSize: 1000, status: 'normal' }),
      listRoute({ pageNum: 1, pageSize: 1000 }),
      listTask({ pageNum: 1, pageSize: 1000, status: 'pending' }),
      listTask({ pageNum: 1, pageSize: 1000, status: 'running' })
    ])

    const runningOrPendingTasks = [...(pendingTaskRes.rows || []), ...(runningTaskRes.rows || [])]
    const occupiedDeviceIds = new Set(runningOrPendingTasks.map(item => item.deviceId).filter(item => item !== undefined && item !== null))
    const occupiedRouteIds = new Set(runningOrPendingTasks.map(item => item.routeId).filter(item => item !== undefined && item !== null))

    deviceOptions.value = (deviceRes.rows || []).filter(item => !occupiedDeviceIds.has(item.deviceId))
    routeOptions.value = (routeRes.rows || []).filter(item => !occupiedRouteIds.has(item.routeId))
  } finally {
    optionLoading.value = false
  }
}

function submitForm() {
  proxy.$refs.formRef.validate(valid => {
    if (!valid) return
    addTask(form.value).then(() => {
      proxy.$modal.msgSuccess('新增成功')
      open.value = false
      getList()
    })
  })
}

function handleStart(row) { startTask(row.taskId).then(() => { proxy.$modal.msgSuccess('任务已开始'); getList() }) }
function handleFinish(row) { finishTask(row.taskId).then(() => { proxy.$modal.msgSuccess('任务已完成'); getList() }) }
function handleCancel(row) { cancelTask(row.taskId).then(() => { proxy.$modal.msgSuccess('任务已取消'); getList() }) }

function handleDelete(row) {
  const taskIds = row.taskId || ids.value
  proxy.$modal.confirm('是否确认删除任务编号为"' + taskIds + '"的数据项？').then(() => delTask(taskIds)).then(() => {
    proxy.$modal.msgSuccess('删除成功')
    getList()
  })
}

function handleViewMap(row) {
  getTask(row.taskId).then(res => {
    const taskData = res.data || {}
    const routeId = taskData.routeId
    if (!routeId) {
      mapTaskInfo.value = { ...taskData, routePoints: [] }
      mapDialogTitle.value = `任务地图 - ${row.taskName}`
      mapDialogVisible.value = true
      return
    }
    getRoute(routeId).then(routeRes => {
      const routeData = routeRes.data || {}
      mapTaskInfo.value = {
        ...taskData,
        routePoints: Array.isArray(routeData.points) ? routeData.points : []
      }
      mapDialogTitle.value = `任务地图 - ${row.taskName}`
      mapComponentKey.value = Date.now() // 强制重新创建组件
      mapDialogVisible.value = true
      if (taskData.status === 'running') {
        startProgressSimulation(taskData)
        startMapProgressPolling(taskData.taskId)
      }
    }).catch((error) => {
      mapTaskInfo.value = { ...taskData, routePoints: [] }
      mapDialogTitle.value = `任务地图 - ${row.taskName}`
      mapComponentKey.value = Date.now() // 强制重新创建组件
      mapDialogVisible.value = true
      // 忽略错误提示，全局拦截器已处理
      console.log('航线点位获取失败:', error)
    })
  }).catch(error => {
    console.error('获取任务详情失败:', error)
    // 忽略错误提示，全局拦截器已处理
  })
}

function handleSimulate(row) {
  // 纯模拟模式，不改变真实任务状态
  proxy.$modal.msgSuccess('进入模拟模式')

  // 获取任务详情并打开地图进行模拟
  getTask(row.taskId).then(res => {
    const taskData = res.data || {}
    const routeId = taskData.routeId
    if (!routeId) {
      mapTaskInfo.value = {
        ...taskData,
        routePoints: [],
        status: 'running',  // 实际状态仍为running，通过isSimulation区分显示
        isSimulation: true, // 标记为模拟模式
        progress: 0          // 初始化进度
      }
      mapDialogTitle.value = `任务模拟 - ${row.taskName}`
      mapComponentKey.value = Date.now() // 强制重新创建组件
      mapDialogVisible.value = true
      return
    }
    getRoute(routeId).then(routeRes => {
      const routeData = routeRes.data || {}
      mapTaskInfo.value = {
        ...taskData,
        routePoints: Array.isArray(routeData.points) ? routeData.points : [],
        status: 'running',  // 实际状态仍为running，通过isSimulation区分显示
        isSimulation: true, // 标记为模拟模式
        progress: 0          // 初始化进度
      }
      mapDialogTitle.value = `任务模拟 - ${row.taskName}`
      mapComponentKey.value = Date.now() // 强制重新创建组件
      mapDialogVisible.value = true
    }).catch(() => {
      mapTaskInfo.value = {
        ...taskData,
        routePoints: [],
        status: 'running',  // 实际状态仍为running，通过isSimulation区分显示
        isSimulation: true, // 标记为模拟模式
        progress: 0          // 初始化进度
      }
      mapDialogTitle.value = `任务模拟 - ${row.taskName}`
      mapDialogVisible.value = true
      proxy.$modal.msgWarning('航线点位获取失败，当前仅显示任务信息')
    })
  }).catch(error => {
    console.error('获取任务详情失败:', error)
    // 忽略错误提示，全局拦截器已处理
  })
}

function validatePlannedStartTime(rule, value, callback) {
  if (!value) {
    callback()
    return
  }
  const selectedTime = new Date(value).getTime()
  if (Number.isFinite(selectedTime) && selectedTime < Date.now()) {
    callback(new Error('开始时间不能早于当前时间'))
    return
  }
  callback()
}

// 格式化进度显示
function formatProgress(percentage) {
  return `${percentage.toFixed(1)}%`
}

function disablePastDate(date) {
  const todayStart = new Date()
  todayStart.setHours(0, 0, 0, 0)
  return date.getTime() < todayStart.getTime()
}

function calculateDistance(point1, point2) {
  const R = 6371
  const dLat = (Number(point2.lat) - Number(point1.lat)) * Math.PI / 180
  const dLon = (Number(point2.lng) - Number(point1.lng)) * Math.PI / 180
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(Number(point1.lat) * Math.PI / 180) * Math.cos(Number(point2.lat) * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  return R * c
}

function calculateTotalDistance(points) {
  if (!Array.isArray(points) || points.length < 2) return 0
  let distance = 0
  for (let i = 1; i < points.length; i++) {
    distance += calculateDistance(points[i - 1], points[i])
  }
  return distance
}

function resolveTaskSpeed(task, routeData, totalDistance) {
  const candidates = [
    task?.speed,
    task?.deviceSpeed,
    task?.cruiseSpeed,
    task?.avgSpeed,
    task?.speedKmh,
    task?.speedKmH
  ]
  for (const value of candidates) {
    const speed = Number(value)
    if (Number.isFinite(speed) && speed > 0) return speed
  }

  if (routeData?.estDurationMinutes && totalDistance > 0) {
    return (totalDistance / Number(routeData.estDurationMinutes)) * 60
  }

  return DEFAULT_SPEED_KMH
}

function stopProgressSimulation(taskId) {
  if (!progressTimers.has(taskId)) return
  clearInterval(progressTimers.get(taskId))
  progressTimers.delete(taskId)
  stopMapProgressPolling(taskId)
}

async function startProgressSimulation(task) {
  if (!task || task.status !== 'running' || !task.taskId || progressTimers.has(task.taskId)) return

  try {
    const routeRes = await getRoute(task.routeId)
    const routeData = routeRes.data || {}
    const points = Array.isArray(routeData.points) ? routeData.points : []
    const totalDistance = calculateTotalDistance(points)
    if (totalDistance <= 0) return

    const speed = resolveTaskSpeed(task, routeData, totalDistance)
    if (speed <= 0) return

    const currentProgress = 0  // 强制从0开始
    const baseElapsedHours = (totalDistance * currentProgress / 100) / speed
    const startAt = Date.now() - baseElapsedHours * 3600000

    // 确保初始进度显示为0
    const listItem = taskList.value.find(item => item.taskId === task.taskId)
    if (listItem) listItem.progress = 0
    if (mapTaskInfo.value?.taskId === task.taskId) {
      mapTaskInfo.value.progress = 0
    }

    let lastProgress = currentProgress
    const timer = setInterval(async () => {
      const elapsedHours = (Date.now() - startAt) / 3600000
      const distance = speed * elapsedHours
      const progress = Math.min(100, (distance / totalDistance) * 100)
      const progressValue = Math.floor(progress * 10) / 10

      if (progressValue !== lastProgress) {
        lastProgress = progressValue
        try {
          await updateTaskProgress({ taskId: task.taskId, progress: progressValue })
        } catch (e) {
          // ignore update errors, still reflect local progress
        }

        const listItem = taskList.value.find(item => item.taskId === task.taskId)
        if (listItem) listItem.progress = progressValue

        if (mapTaskInfo.value?.taskId === task.taskId) {
          mapTaskInfo.value.progress = progressValue
        }
      }

      if (progress >= 100) {
        stopProgressSimulation(task.taskId)
        // 更新地图对话框中的任务状态
        if (mapTaskInfo.value?.taskId === task.taskId) {
          mapTaskInfo.value.status = 'completed'
        }
        // 进度更新接口会在100时完成任务，这里只刷新列表
        getList()
      }
    }, PROGRESS_TICK_MS)

    progressTimers.set(task.taskId, timer)
  } catch (e) {
    // ignore
  }
}

function startMapProgressPolling(taskId) {
  if (!taskId) return
  if (progressTimers.has(`poll-${taskId}`)) return

  const timer = setInterval(async () => {
    try {
      const res = await getTaskProgress(taskId)
      const progressValue = Number(res?.data ?? res)
      if (Number.isFinite(progressValue) && mapTaskInfo.value?.taskId === taskId) {
        mapTaskInfo.value.progress = progressValue
      }
    } catch (e) {
      // ignore
    }
  }, 2000)

  progressTimers.set(`poll-${taskId}`, timer)
}

function stopMapProgressPolling(taskId) {
  const key = `poll-${taskId}`
  if (!progressTimers.has(key)) return
  clearInterval(progressTimers.get(key))
  progressTimers.delete(key)
}

function handleMapDialogClosed() {
  if (mapTaskInfo.value?.taskId) {
    stopMapProgressPolling(mapTaskInfo.value.taskId)
  }
}

function getMapCenter(points) {
  if (!points || points.length === 0) return [113.90, 22.50]

  const lngSum = points.reduce((sum, point) => sum + (Number(point.lng) || 0), 0)
  const latSum = points.reduce((sum, point) => sum + (Number(point.lat) || 0), 0)

  return [lngSum / points.length, latSum / points.length]
}

function handleTaskComplete(data) {
  console.log('任务动画完成:', data)

  // 只有在非模拟模式下才更新真实任务状态
  if (!data.isSimulation && mapTaskInfo.value.taskId) {
    proxy.$modal.msgSuccess(`任务执行完成，总用时: ${data.totalTime} 分钟`)
    finishTask(mapTaskInfo.value.taskId).then(() => {
      getList()
    }).catch((error) => {
      // 忽略错误处理，避免重复显示错误提示（全局拦截器已处理）
      console.log('任务状态更新失败，但已由全局错误处理:', error)
      getList() // 仍然刷新列表确保状态同步
    })
  } else if (data.isSimulation) {
    // 模拟模式只显示一个提示
    proxy.$modal.msgInfo(`模拟完成，总用时: ${data.totalTime} 分钟（真实任务状态未改变）`)
  }
}

function handleProgressUpdate(data) {
  // 实时更新任务进度信息
  if (mapTaskInfo.value) {
    mapTaskInfo.value.progress = data.progress
    mapTaskInfo.value.currentPosition = data.currentPoint
  }
}

// 定时检查任务状态一致性
function checkTaskStatusConsistency() {
  setInterval(() => {
    (taskList.value || []).forEach(task => {
      // 如果任务进度达到100%但状态仍为running，则修正状态
      if (task.status === 'running' && task.progress >= 100) {
        task.status = 'completed'
        task.endTime = task.endTime || new Date()
        stopProgressSimulation(task.taskId)
        // 异步更新后端
        finishTask(task.taskId).catch(() => {
          // 忽略错误，保持状态一致性
        })
      }
    })
  }, 5000) // 每5秒检查一次
}

// 停止所有模拟和定时器
function cleanupAllTimers() {
  for (const timer of progressTimers.values()) {
    clearInterval(timer)
  }
  progressTimers.clear()

  // 关闭地图对话框
  mapDialogVisible.value = false
}

// 路由守卫
const router = useRouter()
const route = useRoute()

onBeforeUnmount(() => {
  cleanupAllTimers()
})

getList()
checkTaskStatusConsistency()
</script>

<style scoped>
.task-map-container {
  height: 600px;
  display: flex;
  flex-direction: column;
}

.task-info-summary {
  margin-bottom: 20px;
  flex-shrink: 0;
}

.map-wrapper {
  flex: 1;
  min-height: 0;
  height: calc(100% - 140px);
  border: 1px solid #ebeef5;
  border-radius: 4px;
  overflow: hidden;
  position: relative;
}

:deep(.el-descriptions__label) {
  width: 80px;
}

:deep(.el-progress) {
  margin-top: 5px;
}
</style>
