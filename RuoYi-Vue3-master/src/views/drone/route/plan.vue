<template>
  <div class="app-container">
    <el-row :gutter="20" class="plan-container">
      <!-- 左侧地图区域 -->
      <el-col :span="18">
        <el-card class="map-card">
          <template #header>
            <div class="card-header">
              <span>航线绘制</span>
              <div class="header-actions">
                <el-button type="primary" @click="saveRoute" :disabled="!canSave">
                  <el-icon><Check /></el-icon> 保存航线
                </el-button>
                <el-button @click="resetRoute">
                  <el-icon><RefreshRight /></el-icon> 重置
                </el-button>
              </div>
            </div>
          </template>

          <div class="map-wrapper">
            <DroneMap
              v-model:points="routePoints"
              :enable-edit="true"
              :center="defaultCenter"
              :zoom="defaultZoom"
              @route-change="handleRouteChange"
            />
          </div>
        </el-card>
      </el-col>

      <!-- 右侧信息面板 -->
      <el-col :span="6">
        <el-card class="info-card">
          <template #header>
            <div class="card-header">
              <span>航线信息</span>
            </div>
          </template>

          <el-form :model="routeForm" :rules="rules" ref="formRef" label-width="80px">
            <el-form-item label="航线名称" prop="routeName">
              <el-input v-model="routeForm.routeName" placeholder="请输入航线名称" />
            </el-form-item>

            <el-form-item label="预计时长" prop="estDurationMinutes">
              <el-input-number
                v-model="routeForm.estDurationMinutes"
                :min="1"
                :max="1440"
                controls-position="right"
              />
              <span class="unit">分钟</span>
            </el-form-item>

            <el-form-item label="航行高度" prop="altitude">
              <el-input-number
                v-model="routeForm.altitude"
                :min="0"
                :precision="2"
                controls-position="right"
              />
              <span class="unit">米</span>
            </el-form-item>

            <el-form-item label="备注" prop="remark">
              <el-input
                v-model="routeForm.remark"
                type="textarea"
                :rows="3"
                placeholder="请输入备注信息"
              />
            </el-form-item>
          </el-form>

          <div class="route-stats">
            <h4>航线统计</h4>
            <div class="stat-item">
              <span class="label">航点数量:</span>
              <span class="value">{{ routePoints.length }}</span>
            </div>
            <div class="stat-item">
              <span class="label">总距离:</span>
              <span class="value">{{ totalDistance.toFixed(2) }} 公里</span>
            </div>
            <div class="stat-item">
              <span class="label">平均速度:</span>
              <span class="value">{{ avgSpeed.toFixed(1) }} 公里/小时</span>
            </div>
          </div>

          <div class="operation-guide">
            <h4>操作说明</h4>
            <div class="guide-item">
              <el-icon><CirclePlus /></el-icon>
              <span>点击地图添加航点</span>
            </div>
            <div class="guide-item">
              <el-icon><Edit /></el-icon>
              <span>双击航点删除</span>
            </div>
            <div class="guide-item">
              <el-icon><Aim /></el-icon>
              <span>点击适应视图居中</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 保存确认对话框 -->
    <el-dialog v-model="saveDialogVisible" title="保存航线" width="500px">
      <div class="save-confirm">
        <el-alert
          title="确认保存航线？"
          type="info"
          :description="`航线名称: ${routeForm.routeName}\n航点数量: ${routePoints.length}\n总距离: ${totalDistance.toFixed(2)} 公里`"
          show-icon
        />
      </div>
      <template #footer>
        <el-button @click="saveDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmSave">确定保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Check, RefreshRight, CirclePlus, Edit, Aim } from '@element-plus/icons-vue'
import DroneMap from '@/components/DroneMap/index.vue'
import { addRoute } from '@/api/drone/route'

const router = useRouter()
const route = useRoute()

// 表单数据
const routeForm = ref({
  routeName: '',
  estDurationMinutes: 30,
  altitude: 25.00,
  remark: ''
})

const rules = {
  routeName: [
    { required: true, message: '请输入航线名称', trigger: 'blur' },
    { min: 2, max: 50, message: '航线名称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  estDurationMinutes: [
    { required: true, message: '请输入预计时长', trigger: 'blur' }
  ],
  altitude: [
    { required: true, message: '请输入航行高度', trigger: 'blur' }
  ]
}

// 地图和航线数据
const routePoints = ref([])
const defaultCenter = ref([113.90, 22.50]) // 默认中心点
const defaultZoom = ref(12) // 默认缩放级别
const saveDialogVisible = ref(false)
const formRef = ref(null)

// 计算属性
const canSave = computed(() => {
  return routeForm.value.routeName && routePoints.value.length >= 2
})

const totalDistance = computed(() => {
  if (routePoints.value.length < 2) return 0
  let distance = 0
  for (let i = 1; i < routePoints.value.length; i++) {
    distance += calculateDistance(routePoints.value[i - 1], routePoints.value[i])
  }
  return distance
})

const avgSpeed = computed(() => {
  if (!routeForm.value.estDurationMinutes || totalDistance.value === 0) return 0
  return (totalDistance.value / routeForm.value.estDurationMinutes) * 60
})

// 计算两点间距离
function calculateDistance(point1, point2) {
  const R = 6371
  const dLat = (point2.lat - point1.lat) * Math.PI / 180
  const dLon = (point2.lng - point1.lng) * Math.PI / 180
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(point1.lat * Math.PI / 180) * Math.cos(point2.lat * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  return R * c
}

// 处理航线变化
function handleRouteChange(points) {
  // 可以在这里添加实时计算逻辑
  console.log('航线更新:', points)
}

// 保存航线
function saveRoute() {
  formRef.value?.validate((valid) => {
    if (valid && canSave.value) {
      saveDialogVisible.value = true
    } else {
      ElMessage.warning('请完善航线信息并至少添加2个航点')
    }
  })
}

// 确认保存
async function confirmSave() {
  try {
    const routeData = {
      ...routeForm.value,
      points: routePoints.value
    }

    await addRoute(routeData)
    ElMessage.success('航线保存成功')
    saveDialogVisible.value = false
    router.push('/drone/route')
  } catch (error) {
    console.error('保存失败:', error)
    ElMessage.error('保存失败: ' + (error.message || '未知错误'))
  }
}

// 重置航线
function resetRoute() {
  routeForm.value = {
    routeName: '',
    estDurationMinutes: 30,
    altitude: 25.00,
    remark: ''
  }
  routePoints.value = []
  ElMessage.info('航线已重置')
}

// 页面加载时检查URL参数（可选：支持从其他页面跳转时带入参数）
onMounted(() => {
  if (route.query.center) {
    try {
      const center = JSON.parse(route.query.center)
      defaultCenter.value = center
    } catch (e) {
      console.warn('无效的中心点参数')
    }
  }
})
</script>

<style scoped>
.plan-container {
  height: calc(100vh - 120px);
  min-height: 600px;
}

.map-card {
  height: 100%;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.map-wrapper {
  height: calc(100vh - 220px);
  min-height: 500px;
}

.info-card {
  height: 100%;
  overflow-y: auto;
}

.unit {
  margin-left: 8px;
  color: #909399;
  font-size: 12px;
}

.route-stats {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}

.route-stats h4 {
  margin: 0 0 15px 0;
  color: #303133;
  font-size: 14px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
  font-size: 13px;
}

.stat-item .label {
  color: #606266;
}

.stat-item .value {
  color: #303133;
  font-weight: 500;
}

.operation-guide {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}

.operation-guide h4 {
  margin: 0 0 15px 0;
  color: #303133;
  font-size: 14px;
}

.guide-item {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
  font-size: 12px;
  color: #606266;
}

.guide-item .el-icon {
  margin-right: 8px;
  color: #409EFF;
}

.save-confirm {
  text-align: center;
}

.save-confirm .el-alert {
  margin-bottom: 20px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
}

:deep(.el-input-number) {
  width: 120px;
}

@media (max-width: 1200px) {
  .plan-container {
    height: auto;
  }

  .map-wrapper {
    height: 500px;
  }
}
</style>