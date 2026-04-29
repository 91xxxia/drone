<template>
  <div class="app-container">
    <el-form :inline="true" :model="queryParams" ref="queryRef" v-show="showSearch">
      <el-form-item label="航线名称" prop="routeName"><el-input v-model="queryParams.routeName" clearable @keyup.enter="handleQuery" /></el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5"><el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['drone:route:add']">新增</el-button></el-col>
      <el-col :span="1.5"><el-button type="success" plain icon="Edit" :disabled="single" @click="handleUpdate" v-hasPermi="['drone:route:edit']">修改</el-button></el-col>
      <el-col :span="1.5"><el-button type="warning" plain icon="EditPen" @click="handleDraw" v-hasPermi="['drone:route:draw']">可视化绘制</el-button></el-col>
      <el-col :span="1.5"><el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete" v-hasPermi="['drone:route:remove']">删除</el-button></el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
    </el-row>

    <el-table v-loading="loading" :data="routeList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" />
      <el-table-column label="航线名称" prop="routeName" />
      <el-table-column label="预计时长(分钟)" prop="estDurationMinutes" />
      <el-table-column label="航行高度" prop="altitude" />
      <el-table-column label="创建时间" prop="createTime" width="180"><template #default="scope">{{ parseTime(scope.row.createTime) }}</template></el-table-column>
      <el-table-column label="操作" width="200" align="center">
        <template #default="scope">
          <el-button link type="primary" icon="View" @click="handleDetail(scope.row)" v-hasPermi="['drone:route:detail']">详情</el-button>
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['drone:route:edit']">修改</el-button>
          <el-button link type="danger" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['drone:route:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="title" v-model="open" width="620px" append-to-body>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="航线名称" prop="routeName"><el-input v-model="form.routeName" /></el-form-item>
        <el-form-item label="预计时长" prop="estDurationMinutes"><el-input-number v-model="form.estDurationMinutes" :min="0" /></el-form-item>
        <el-form-item label="航行高度" prop="altitude"><el-input-number v-model="form.altitude" :min="0" :precision="2" /></el-form-item>
        <el-form-item label="点位(JSON)" prop="points">
          <div class="points-editor">
            <el-input v-model="pointsText" type="textarea" :rows="5" placeholder='示例: [{"seq":1,"lng":113.90,"lat":22.50}]' />
            <el-button type="primary" plain icon="EditPen" @click="openDrawEditor">可视化编辑</el-button>
          </div>
        </el-form-item>
        <el-form-item label="备注" prop="remark"><el-input v-model="form.remark" type="textarea" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitForm">确定</el-button>
        <el-button @click="cancel">取消</el-button>
      </template>
    </el-dialog>

    <!-- 详情对话框 -->
    <el-dialog :title="detailTitle" v-model="detailOpen" width="980px" append-to-body class="route-detail-dialog">
      <div class="detail-layout" v-if="detailData.points && detailData.points.length > 0">
        <div class="detail-left">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="航线名称">{{ detailData.routeName }}</el-descriptions-item>
            <el-descriptions-item label="预计时长">{{ detailData.estDurationMinutes }} 分钟</el-descriptions-item>
            <el-descriptions-item label="航行高度">{{ detailData.altitude }} 米</el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ parseTime(detailData.createTime) }}</el-descriptions-item>
            <el-descriptions-item label="备注" :span="2">{{ detailData.remark || '无' }}</el-descriptions-item>
          </el-descriptions>

          <div class="detail-points">
            <h4>航点信息</h4>
            <el-table :data="detailData.points" size="small" height="220">
              <el-table-column label="序号" prop="seq" width="80" />
              <el-table-column label="经度" prop="lng" />
              <el-table-column label="纬度" prop="lat" />
            </el-table>
          </div>
        </div>

        <div class="detail-right">
          <div class="detail-map-container">
            <h4>航线预览</h4>
            <DroneMap
              :key="detailMapKey"
              v-model:points="detailData.points"
              :enable-edit="false"
              :show-controls="false"
              :show-info="false"
              :auto-fit="true"
              :center="getMapCenter(detailData.points)"
              :zoom="12"
            />
          </div>
        </div>
      </div>

      <div v-else class="detail-empty">
        <el-empty description="暂无航点数据" />
      </div>
    </el-dialog>

    <el-dialog title="航线可视化绘制" v-model="drawOpen" width="980px" append-to-body>
      <div class="draw-map-wrapper">
        <DroneMap
          v-model:points="drawPoints"
          :enable-edit="true"
          :show-info="true"
          :show-controls="true"
          :center="getMapCenter(drawPoints)"
          :zoom="12"
        />
      </div>
      <template #footer>
        <el-button @click="drawOpen = false">取消</el-button>
        <el-button type="primary" @click="applyDrawResult">应用到表单</el-button>
      </template>
    </el-dialog>

  </div>
</template>

<script setup name="DroneRoute">
import { getCurrentInstance, nextTick, reactive, ref, toRefs } from 'vue'
import { addRoute, delRoute, getRoute, listRoute, updateRoute } from '@/api/drone/route'
import DroneMap from '@/components/DroneMap/index.vue'

const { proxy } = getCurrentInstance()
const loading = ref(false)
const showSearch = ref(true)
const routeList = ref([])
const total = ref(0)
const title = ref('')
const open = ref(false)
const detailOpen = ref(false)
const detailTitle = ref('航线详情')
const single = ref(true)
const multiple = ref(true)
const ids = ref([])
const pointsText = ref('[]')
const drawOpen = ref(false)
const drawPoints = ref([])
const detailData = ref({})
const detailMapKey = ref(0)

const data = reactive({
  queryParams: { pageNum: 1, pageSize: 10, routeName: undefined },
  form: {},
  rules: { routeName: [{ required: true, message: '航线名称不能为空', trigger: 'blur' }] }
})

const { queryParams, form, rules } = toRefs(data)

function getList() {
  loading.value = true
  listRoute(queryParams.value).then(res => {
    routeList.value = res.rows
    total.value = res.total
    loading.value = false
  })
}

function reset() {
  form.value = { routeId: undefined, routeName: undefined, estDurationMinutes: 0, altitude: 0, remark: undefined, points: [] }
  pointsText.value = '[]'
  drawPoints.value = []
  proxy.resetForm('formRef')
}

function cancel() { open.value = false; reset() }
function handleQuery() { queryParams.value.pageNum = 1; getList() }
function resetQuery() { proxy.resetForm('queryRef'); handleQuery() }
function handleSelectionChange(selection) { ids.value = selection.map(item => item.routeId); single.value = selection.length !== 1; multiple.value = !selection.length }
function handleAdd() { reset(); open.value = true; title.value = '新增航线' }

function handleUpdate(row) {
  reset()
  const routeId = row.routeId || ids.value[0]
  getRoute(routeId).then(res => {
    form.value = res.data
    const points = Array.isArray(form.value.points) ? form.value.points : []
    drawPoints.value = points.map((point, index) => ({ ...point, seq: Number(point.seq) || index + 1 }))
    pointsText.value = JSON.stringify(drawPoints.value, null, 2)
    open.value = true
    title.value = '修改航线'
  })
}

function parsePointsText() {
  try {
    const points = JSON.parse(pointsText.value || '[]')
    if (!Array.isArray(points)) {
      proxy.$modal.msgError('点位JSON必须是数组格式')
      return null
    }
    return points
      .map((point, index) => ({
        seq: Number(point.seq) || index + 1,
        lng: Number(point.lng),
        lat: Number(point.lat)
      }))
      .filter(point => Number.isFinite(point.lng) && Number.isFinite(point.lat))
  } catch (e) {
    proxy.$modal.msgError('点位JSON格式错误')
    return null
  }
}

function submitForm() {
  proxy.$refs.formRef.validate(valid => {
    if (!valid) return
    const points = parsePointsText()
    if (!points) {
      return
    }
    form.value.points = points
    const req = form.value.routeId ? updateRoute(form.value) : addRoute(form.value)
    req.then(() => {
      proxy.$modal.msgSuccess(form.value.routeId ? '修改成功' : '新增成功')
      open.value = false
      getList()
    })
  })
}

function handleDelete(row) {
  const routeIds = row.routeId || ids.value
  proxy.$modal.confirm('是否确认删除航线编号为"' + routeIds + '"的数据项？').then(() => delRoute(routeIds)).then(() => {
    proxy.$modal.msgSuccess('删除成功')
    getList()
  })
}

function handleDetail(row) {
  getRoute(row.routeId).then(res => {
    const data = res.data || {}
    detailData.value = { ...data, points: Array.isArray(data.points) ? data.points : [] }
    detailTitle.value = `航线详情 - ${data.routeName || row.routeName}`
    detailMapKey.value = Date.now() // 强制重新创建地图组件
    detailOpen.value = true
  })
}

function getMapCenter(points) {
  if (!points || points.length === 0) return [113.90, 22.50]

  const lngSum = points.reduce((sum, point) => sum + (Number(point.lng) || 0), 0)
  const latSum = points.reduce((sum, point) => sum + (Number(point.lat) || 0), 0)

  return [lngSum / points.length, latSum / points.length]
}

function handleDraw() {
  handleAdd()
  nextTick(() => {
    openDrawEditor()
  })
}

function openDrawEditor() {
  const points = parsePointsText()
  if (points === null) {
    return
  }
  drawPoints.value = points
  drawOpen.value = true
}

function applyDrawResult() {
  drawPoints.value = drawPoints.value.map((point, index) => ({ ...point, seq: index + 1 }))
  pointsText.value = JSON.stringify(drawPoints.value, null, 2)
  drawOpen.value = false
}

getList()
</script>

<style scoped>
.detail-map-container {
  height: 360px;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  overflow: hidden;
}

.detail-map-container h4 {
  margin: 0 0 10px 0;
  color: #303133;
}

.detail-points {
  margin-top: 16px;
}

.detail-points h4 {
  margin: 0 0 10px 0;
  color: #303133;
}

:deep(.el-descriptions__label) {
  width: 100px;
}

.detail-layout {
  display: grid;
  grid-template-columns: 1.1fr 1fr;
  gap: 20px;
  align-items: start;
}

.detail-left,
.detail-right {
  min-width: 0;
}

.detail-empty {
  padding: 20px 0;
}

:deep(.route-detail-dialog .el-dialog__body) {
  max-height: 75vh;
  overflow-y: auto;
}

@media (max-width: 1200px) {
  .detail-layout {
    grid-template-columns: 1fr;
  }
  .detail-map-container {
    height: 320px;
  }
}

.points-editor {
  display: flex;
  width: 100%;
  gap: 10px;
  align-items: flex-start;
}

.points-editor :deep(.el-textarea) {
  flex: 1;
}

.draw-map-wrapper {
  height: 560px;
  position: relative;
  overflow: hidden;
  border-radius: 4px;
}
</style>
