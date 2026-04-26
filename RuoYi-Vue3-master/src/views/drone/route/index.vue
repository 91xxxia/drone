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
      <el-col :span="1.5"><el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete" v-hasPermi="['drone:route:remove']">删除</el-button></el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
    </el-row>

    <el-table v-loading="loading" :data="routeList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" />
      <el-table-column label="航线名称" prop="routeName" />
      <el-table-column label="预计时长(分钟)" prop="estDurationMinutes" />
      <el-table-column label="航行高度" prop="altitude" />
      <el-table-column label="创建时间" prop="createTime" width="180"><template #default="scope">{{ parseTime(scope.row.createTime) }}</template></el-table-column>
      <el-table-column label="操作" width="180" align="center">
        <template #default="scope">
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['drone:route:edit']">修改</el-button>
          <el-button link type="primary" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['drone:route:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog :title="title" v-model="open" width="620px" append-to-body>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="航线名称" prop="routeName"><el-input v-model="form.routeName" /></el-form-item>
        <el-form-item label="预计时长" prop="estDurationMinutes"><el-input-number v-model="form.estDurationMinutes" :min="0" /></el-form-item>
        <el-form-item label="航行高度" prop="altitude"><el-input-number v-model="form.altitude" :min="0" :precision="2" /></el-form-item>
        <el-form-item label="点位(JSON)" prop="points">
          <el-input v-model="pointsText" type="textarea" :rows="5" placeholder='示例: [{"seq":1,"lng":113.90,"lat":22.50}]' />
        </el-form-item>
        <el-form-item label="备注" prop="remark"><el-input v-model="form.remark" type="textarea" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitForm">确定</el-button>
        <el-button @click="cancel">取消</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="DroneRoute">
import { addRoute, delRoute, getRoute, listRoute, updateRoute } from '@/api/drone/route'

const { proxy } = getCurrentInstance()
const loading = ref(false)
const showSearch = ref(true)
const routeList = ref([])
const total = ref(0)
const title = ref('')
const open = ref(false)
const single = ref(true)
const multiple = ref(true)
const ids = ref([])
const pointsText = ref('[]')

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
    pointsText.value = JSON.stringify(form.value.points || [], null, 2)
    open.value = true
    title.value = '修改航线'
  })
}

function submitForm() {
  proxy.$refs.formRef.validate(valid => {
    if (!valid) return
    try {
      form.value.points = JSON.parse(pointsText.value || '[]')
    } catch (e) {
      proxy.$modal.msgError('点位JSON格式错误')
      return
    }
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

getList()
</script>
