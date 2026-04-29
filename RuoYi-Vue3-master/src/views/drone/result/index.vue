<template>
  <div class="app-container">
    <el-form :inline="true" :model="queryParams" ref="queryRef" v-show="showSearch">
      <el-form-item label="结果编号"><el-input v-model="queryParams.resultCode" clearable @keyup.enter="handleQuery" /></el-form-item>
      <el-form-item label="任务名称"><el-input v-model="queryParams.taskName" clearable @keyup.enter="handleQuery" /></el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5"><el-button type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['drone:result:export']">导出</el-button></el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
    </el-row>

    <el-table v-loading="loading" :data="resultList">
      <el-table-column label="结果编号" prop="resultCode" width="180" />
      <el-table-column label="任务名称" prop="taskName" />
      <el-table-column label="设备" prop="deviceName" />
      <el-table-column label="航线" prop="routeName" />
      <el-table-column label="执行人" prop="executor" />
      <el-table-column label="完成时间" prop="completedTime" width="180"><template #default="scope">{{ parseTime(scope.row.completedTime) }}</template></el-table-column>
      <el-table-column label="操作" width="340" align="center">
        <template #default="scope">
          <el-button link type="primary" icon="View" @click="handleDetail(scope.row)" v-hasPermi="['drone:result:detail']">详情</el-button>
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['drone:result:edit']">编辑</el-button>
          <el-button link type="success" icon="Camera" @click="handleAIUpload(scope.row)" v-hasPermi="['drone:result:ai']">AI识别</el-button>
          <el-button link type="danger" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['drone:result:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <!-- 编辑对话框 -->
    <el-dialog :title="title" v-model="open" width="700px" append-to-body>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="巡防概述" prop="overview"><el-input v-model="form.overview" type="textarea" :rows="3" /></el-form-item>
        <el-form-item label="发现情况" prop="findings"><el-input v-model="form.findings" type="textarea" :rows="3" /></el-form-item>
        <el-form-item label="处理情况" prop="handling"><el-input v-model="form.handling" type="textarea" :rows="3" /></el-form-item>
        <el-form-item label="备注" prop="remark"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitForm">确定</el-button>
        <el-button @click="cancel">取消</el-button>
      </template>
    </el-dialog>

    <!-- 详情对话框 -->
    <el-dialog :title="detailTitle" v-model="detailOpen" width="1000px" append-to-body class="result-detail-dialog">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="结果编号">{{ detailData.resultCode }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ detailData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="设备名称">{{ detailData.deviceName }}</el-descriptions-item>
        <el-descriptions-item label="航线名称">{{ detailData.routeName }}</el-descriptions-item>
        <el-descriptions-item label="巡防时长">{{ formatDuration(detailData.durationMinutes) }}</el-descriptions-item>
        <el-descriptions-item label="完成时间">{{ parseTime(detailData.completedTime) }}</el-descriptions-item>
        <el-descriptions-item label="执行人">{{ detailData.executor }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ parseTime(detailData.createTime) }}</el-descriptions-item>
      </el-descriptions>

      <div class="detail-content">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="巡防概述">{{ detailData.overview }}</el-descriptions-item>
          <el-descriptions-item label="发现情况">{{ detailData.findings || '无' }}</el-descriptions-item>
          <el-descriptions-item label="处理情况">{{ detailData.handling || '无' }}</el-descriptions-item>
          <el-descriptions-item label="备注">{{ detailData.remark || '无' }}</el-descriptions-item>
        </el-descriptions>
      </div>

      <!-- 航线分析信息 -->
      <div class="detail-analysis" v-if="hasRouteAnalysis">
        <h4>航线分析</h4>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="总距离">{{ (detailData.totalDistance != null ? detailData.totalDistance.toFixed(2) : '0.00') }} 公里</el-descriptions-item>
          <el-descriptions-item label="转弯次数">{{ analysisData.turnCount }} 次</el-descriptions-item>
          <el-descriptions-item label="复杂度评级">{{ analysisData.complexity }}</el-descriptions-item>
          <el-descriptions-item label="预计能耗">{{ analysisData.estimatedEnergy }}%</el-descriptions-item>
        </el-descriptions>
      </div>

      <div class="detail-map-container" v-if="detailData.routePoints && detailData.routePoints.length > 0">
        <h4>巡防航线</h4>
        <DroneMap
          :key="detailMapKey"
          v-model:points="detailData.routePoints"
          :enable-edit="false"
          :show-controls="false"
          :show-info="false"
          :auto-fit="true"
          :center="getMapCenter(detailData.routePoints)"
          :zoom="12"
        />
      </div>

      <div class="detail-media" v-if="detailData.mediaList && detailData.mediaList.length > 0">
        <h4>AI识别结果</h4>
        <el-row :gutter="10">
          <el-col v-for="media in detailData.mediaList" :key="media.mediaId" :xs="24" :sm="12" :md="8">
            <el-card class="media-card">
              <div class="media-preview">
                <el-image
                  :src="media.fileUrl"
                  :preview-src-list="getImagePreviewList(detailData.mediaList)"
                  fit="cover"
                  style="width: 100%; height: 150px;"
                />
              </div>
              <div class="media-info">
                <div class="ai-tag">
                  <el-tag size="small" type="success">{{ media.aiTag }}</el-tag>
                </div>
                <div class="media-coordinates" v-if="media.bboxJson">
                  <small>坐标: {{ formatBbox(media.bboxJson) }}</small>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>
    </el-dialog>
  </div>
</template>

<script setup name="DroneResult">
import { delResult, getResult, getResultDetail, listResult, updateResult } from '@/api/drone/result'
import DroneMap from '@/components/DroneMap/index.vue'
import { useRouter } from 'vue-router'
import { onActivated } from 'vue'

const { proxy } = getCurrentInstance()
const router = useRouter()
const loading = ref(false)
const showSearch = ref(true)
const resultList = ref([])
const total = ref(0)
const open = ref(false)
const detailOpen = ref(false)
const title = ref('')
const detailTitle = ref('结果详情')
const detailData = ref({})
const detailMapKey = ref(0)
const hasRouteAnalysis = ref(false)
const analysisData = ref({
  totalDistance: 0,
  turnCount: 0,
  complexity: '未知',
  estimatedEnergy: 0
})

const data = reactive({
  queryParams: { pageNum: 1, pageSize: 10, resultCode: undefined, taskName: undefined },
  form: {},
  rules: { overview: [{ required: true, message: '巡防概述不能为空', trigger: 'blur' }] }
})

const { queryParams, form, rules } = toRefs(data)

function getList() {
  loading.value = true
  listResult(queryParams.value).then(res => {
    resultList.value = res.rows
    total.value = res.total
    loading.value = false
  })
}

function handleQuery() { queryParams.value.pageNum = 1; getList() }
function resetQuery() { proxy.resetForm('queryRef'); handleQuery() }
function cancel() { open.value = false; form.value = {} }

function handleUpdate(row) {
  getResult(row.resultId).then(res => {
    form.value = res.data
    open.value = true
    title.value = '编辑结果'
  })
}

function submitForm() {
  proxy.$refs.formRef.validate(valid => {
    if (!valid) return
    updateResult(form.value).then(() => {
      proxy.$modal.msgSuccess('修改成功')
      open.value = false
      getList()
    })
  })
}

function handleDelete(row) {
  proxy.$modal.confirm('是否确认删除结果编号为"' + row.resultCode + '"的数据项？').then(() => delResult(row.resultId)).then(() => {
    proxy.$modal.msgSuccess('删除成功')
    getList()
  })
}

function handleDetail(row) {
  // 获取详情数据，包括航线点位
  getResultDetail(row.resultId).then(res => {
    detailData.value = { ...res.data }

    // 处理航线点位数据
    if (detailData.value.routePoints && typeof detailData.value.routePoints === 'string') {
      try {
        detailData.value.routePoints = JSON.parse(detailData.value.routePoints)
      } catch (e) {
        detailData.value.routePoints = []
      }
    }

    // 处理媒体数据
    if (detailData.value.mediaList && typeof detailData.value.mediaList === 'string') {
      try {
        detailData.value.mediaList = JSON.parse(detailData.value.mediaList)
      } catch (e) {
        detailData.value.mediaList = []
      }
    }

    // 解析航线分析数据
    parseRouteAnalysis(detailData.value.remark)

    detailTitle.value = `结果详情 - ${row.resultCode}`
    detailMapKey.value = Date.now() // 强制重新创建地图组件
    detailOpen.value = true
  }).catch(error => {
    console.error('获取详情失败:', error)
    proxy.$modal.msgError('获取详情失败')
  })
}

function parseRouteAnalysis(remark) {
  if (!remark) {
    hasRouteAnalysis.value = false
    return
  }

  try {
    // 解析备注中的分析数据（格式：距离:xx.xxkm;转弯:xx次;复杂度:xx;）
    const distanceMatch = remark.match(/距离:([\d.]+)km/)
    const turnMatch = remark.match(/转弯:(\d+)次/)
    const complexityMatch = remark.match(/复杂度:([^;]+)/)

    if (distanceMatch || turnMatch || complexityMatch) {
      hasRouteAnalysis.value = true
      analysisData.value = {
        totalDistance: distanceMatch ? parseFloat(distanceMatch[1]).toFixed(2) : '0.00',
        turnCount: turnMatch ? turnMatch[1] : '0',
        complexity: complexityMatch ? complexityMatch[1] : '未知',
        estimatedEnergy: calculateEstimatedEnergy(
          distanceMatch ? parseFloat(distanceMatch[1]) : 0,
          turnMatch ? parseInt(turnMatch[1]) : 0,
          complexityMatch ? complexityMatch[1] : '未知'
        )
      }
    } else {
      hasRouteAnalysis.value = false
    }
  } catch (e) {
    console.error('解析航线分析数据失败:', e)
    hasRouteAnalysis.value = false
  }
}

function calculateEstimatedEnergy(distance, turns, complexity) {
  let baseEnergy = distance * 2 // 基础能耗：每公里2%
  let complexityMultiplier = 1

  switch (complexity) {
    case '简单':
      complexityMultiplier = 1.0
      break
    case '中等':
      complexityMultiplier = 1.2
      break
    case '复杂':
      complexityMultiplier = 1.5
      break
    case '极复杂':
      complexityMultiplier = 2.0
      break
    default:
      complexityMultiplier = 1.0
  }

  let turnPenalty = Math.min(turns * 0.5, 10) // 转弯惩罚，最多10%

  return Math.min(Math.round(baseEnergy * complexityMultiplier + turnPenalty), 100)
}

function getImagePreviewList(mediaList) {
  return mediaList.map(media => media.fileUrl).filter(url => url)
}

function formatBbox(bboxJson) {
  try {
    const bbox = JSON.parse(bboxJson)
    return `x:${bbox.x}, y:${bbox.y}, w:${bbox.w}, h:${bbox.h}`
  } catch (e) {
    return bboxJson
  }
}

function getMapCenter(points) {
  if (!points || points.length === 0) return [113.90, 22.50]

  const lngSum = points.reduce((sum, point) => sum + (Number(point.lng) || 0), 0)
  const latSum = points.reduce((sum, point) => sum + (Number(point.lat) || 0), 0)

  return [lngSum / points.length, latSum / points.length]
}

function formatDuration(minutes) {
  if (minutes == null) return '未知'
  if (minutes < 1) {
    const seconds = Math.round(minutes * 60)
    return seconds > 0 ? `${seconds}秒` : '0分钟'
  }
  return `${minutes.toFixed(1)} 分钟`
}

function handleExport() {
  proxy.download('drone/result/export', { ...queryParams.value }, `drone_result_${new Date().getTime()}.xlsx`)
}

function handleAIUpload(row) {
  router.push(`/drone/result/ai/${row.resultId}`)
}

getList()

onActivated(() => {
  getList()
})
</script>

<style scoped>
.detail-content {
  margin: 25px 0;
}

.detail-analysis {
  margin: 25px 0;
}

.detail-analysis h4 {
  margin: 0 0 15px 0;
  color: #303133;
  font-size: 16px;
  font-weight: 600;
}

.detail-map-container {
  margin: 20px 0 40px 0;
  height: 400px;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  overflow: hidden;
  position: relative;
}

.detail-map-container h4 {
  margin: 0 0 15px 0;
  color: #303133;
  font-size: 16px;
  font-weight: 600;
}

:deep(.el-descriptions__label) {
  width: 100px;
}

.detail-media {
  margin: 20px 0;
}

.detail-media h4 {
  margin: 0 0 15px 0;
  color: #303133;
}

.media-card {
  margin-bottom: 10px;
  transition: all 0.3s;
}

.detail-media :deep(.el-image) {
  display: block;
}

.media-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.media-preview {
  margin-bottom: 10px;
}

.media-info {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.ai-tag {
  display: flex;
  justify-content: center;
}

.media-coordinates {
  text-align: center;
  color: #909399;
}

:deep(.result-detail-dialog .el-dialog__body) {
  max-height: 80vh;
  overflow-y: auto;
  padding: 20px;
}
</style>
