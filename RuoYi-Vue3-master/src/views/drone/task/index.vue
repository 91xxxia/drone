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
      <el-table-column label="状态" prop="status"><template #default="scope"><dict-tag :options="drone_task_status" :value="scope.row.status" /></template></el-table-column>
      <el-table-column label="计划开始" prop="plannedStartTime" width="180"><template #default="scope">{{ parseTime(scope.row.plannedStartTime) }}</template></el-table-column>
      <el-table-column label="操作" width="360" align="center">
        <template #default="scope">
          <el-button link type="primary" @click="handleStart(scope.row)" v-if="scope.row.status==='pending'" v-hasPermi="['drone:task:start']">开始</el-button>
          <el-button link type="success" @click="handleFinish(scope.row)" v-if="scope.row.status==='running'" v-hasPermi="['drone:task:finish']">完成</el-button>
          <el-button link type="warning" @click="handleCancel(scope.row)" v-if="scope.row.status==='pending' || scope.row.status==='running'" v-hasPermi="['drone:task:cancel']">取消</el-button>
          <el-button link type="danger" @click="handleDelete(scope.row)" v-if="scope.row.status==='completed' || scope.row.status==='canceled'" v-hasPermi="['drone:task:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog :title="title" v-model="open" width="620px" append-to-body>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="任务名称" prop="taskName"><el-input v-model="form.taskName" /></el-form-item>
        <el-form-item label="执行人" prop="executor"><el-input v-model="form.executor" /></el-form-item>
        <el-form-item label="开始时间" prop="plannedStartTime"><el-date-picker v-model="form.plannedStartTime" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" /></el-form-item>
        <el-form-item label="设备ID" prop="deviceId"><el-input-number v-model="form.deviceId" :min="1" /></el-form-item>
        <el-form-item label="航线ID" prop="routeId"><el-input-number v-model="form.routeId" :min="1" /></el-form-item>
        <el-form-item label="任务描述" prop="taskDesc"><el-input v-model="form.taskDesc" type="textarea" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitForm">确定</el-button>
        <el-button @click="cancel">取消</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="DroneTask">
import { addTask, cancelTask, delTask, finishTask, listTask, startTask } from '@/api/drone/task'

const { proxy } = getCurrentInstance()
const { drone_task_status } = useDict('drone_task_status')

const loading = ref(false)
const showSearch = ref(true)
const taskList = ref([])
const total = ref(0)
const open = ref(false)
const title = ref('')
const multiple = ref(true)
const ids = ref([])

const data = reactive({
  queryParams: { pageNum: 1, pageSize: 10, taskName: undefined, executor: undefined, status: undefined },
  form: {},
  rules: {
    taskName: [{ required: true, message: '任务名称不能为空', trigger: 'blur' }],
    plannedStartTime: [{ required: true, message: '开始时间不能为空', trigger: 'change' }],
    deviceId: [{ required: true, message: '设备ID不能为空', trigger: 'blur' }],
    routeId: [{ required: true, message: '航线ID不能为空', trigger: 'blur' }]
  }
})

const { queryParams, form, rules } = toRefs(data)

function getList() {
  loading.value = true
  listTask(queryParams.value).then(res => {
    taskList.value = res.rows
    total.value = res.total
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
function handleAdd() { reset(); open.value = true; title.value = '新增任务' }
function cancel() { open.value = false; reset() }

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

getList()
</script>
