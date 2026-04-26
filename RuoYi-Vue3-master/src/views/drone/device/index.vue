<template>
  <div class="app-container">
    <el-form :model="queryParams" :inline="true" ref="queryRef" v-show="showSearch">
      <el-form-item label="设备编号" prop="deviceCode"><el-input v-model="queryParams.deviceCode" clearable @keyup.enter="handleQuery" /></el-form-item>
      <el-form-item label="设备名称" prop="deviceName"><el-input v-model="queryParams.deviceName" clearable @keyup.enter="handleQuery" /></el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" clearable style="width: 180px">
          <el-option v-for="dict in drone_device_status" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5"><el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['drone:device:add']">新增</el-button></el-col>
      <el-col :span="1.5"><el-button type="success" plain icon="Edit" :disabled="single" @click="handleUpdate" v-hasPermi="['drone:device:edit']">修改</el-button></el-col>
      <el-col :span="1.5"><el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete" v-hasPermi="['drone:device:remove']">删除</el-button></el-col>
      <el-col :span="1.5"><el-button type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['drone:device:export']">导出</el-button></el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
    </el-row>

    <el-table v-loading="loading" :data="deviceList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column label="编号" prop="deviceCode" />
      <el-table-column label="名称" prop="deviceName" />
      <el-table-column label="型号" prop="deviceModel" />
      <el-table-column label="归属人" prop="ownerName" />
      <el-table-column label="状态" prop="status"><template #default="scope"><dict-tag :options="drone_device_status" :value="scope.row.status" /></template></el-table-column>
      <el-table-column label="操作" width="180" align="center">
        <template #default="scope">
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['drone:device:edit']">修改</el-button>
          <el-button link type="primary" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['drone:device:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog :title="title" v-model="open" width="520px" append-to-body>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="设备编号" prop="deviceCode"><el-input v-model="form.deviceCode" :disabled="form.deviceId!==undefined" /></el-form-item>
        <el-form-item label="设备名称" prop="deviceName"><el-input v-model="form.deviceName" /></el-form-item>
        <el-form-item label="设备型号" prop="deviceModel"><el-input v-model="form.deviceModel" /></el-form-item>
        <el-form-item label="续航(分钟)" prop="enduranceMinutes"><el-input-number v-model="form.enduranceMinutes" :min="0" /></el-form-item>
        <el-form-item label="摄像头参数" prop="cameraSpec"><el-input v-model="form.cameraSpec" /></el-form-item>
        <el-form-item label="归属人" prop="ownerName"><el-input v-model="form.ownerName" /></el-form-item>
        <el-form-item label="状态" prop="status"><el-select v-model="form.status"><el-option v-for="dict in drone_device_status" :key="dict.value" :label="dict.label" :value="dict.value" /></el-select></el-form-item>
        <el-form-item label="备注" prop="remark"><el-input v-model="form.remark" type="textarea" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitForm">确定</el-button>
        <el-button @click="cancel">取消</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="DroneDevice">
import { addDevice, delDevice, getDevice, listDevice, updateDevice } from '@/api/drone/device'

const { proxy } = getCurrentInstance()
const { drone_device_status } = useDict('drone_device_status')

const loading = ref(false)
const showSearch = ref(true)
const total = ref(0)
const deviceList = ref([])
const title = ref('')
const open = ref(false)
const ids = ref([])
const single = ref(true)
const multiple = ref(true)

const data = reactive({
  queryParams: { pageNum: 1, pageSize: 10, deviceCode: undefined, deviceName: undefined, status: undefined },
  form: {},
  rules: {
    deviceCode: [{ required: true, message: '设备编号不能为空', trigger: 'blur' }],
    deviceName: [{ required: true, message: '设备名称不能为空', trigger: 'blur' }]
  }
})

const { queryParams, form, rules } = toRefs(data)

function getList() {
  loading.value = true
  listDevice(queryParams.value).then(res => {
    deviceList.value = res.rows
    total.value = res.total
    loading.value = false
  })
}

function reset() {
  form.value = { deviceId: undefined, deviceCode: undefined, deviceName: undefined, deviceModel: undefined, enduranceMinutes: 0, cameraSpec: undefined, ownerName: undefined, status: 'normal', remark: undefined }
  proxy.resetForm('formRef')
}

function cancel() { open.value = false; reset() }
function handleQuery() { queryParams.value.pageNum = 1; getList() }
function resetQuery() { proxy.resetForm('queryRef'); handleQuery() }
function handleSelectionChange(selection) { ids.value = selection.map(item => item.deviceId); single.value = selection.length !== 1; multiple.value = !selection.length }
function handleAdd() { reset(); open.value = true; title.value = '新增设备' }

function handleUpdate(row) {
  reset()
  const deviceId = row.deviceId || ids.value[0]
  getDevice(deviceId).then(res => {
    form.value = res.data
    open.value = true
    title.value = '修改设备'
  })
}

function submitForm() {
  proxy.$refs.formRef.validate(valid => {
    if (!valid) return
    const req = form.value.deviceId ? updateDevice(form.value) : addDevice(form.value)
    req.then(() => {
      proxy.$modal.msgSuccess(form.value.deviceId ? '修改成功' : '新增成功')
      open.value = false
      getList()
    })
  })
}

function handleDelete(row) {
  const deviceIds = row.deviceId || ids.value
  proxy.$modal.confirm('是否确认删除设备编号为"' + deviceIds + '"的数据项？').then(() => delDevice(deviceIds)).then(() => {
    proxy.$modal.msgSuccess('删除成功')
    getList()
  })
}

function handleExport() {
  proxy.download('drone/device/export', { ...queryParams.value }, `drone_device_${new Date().getTime()}.xlsx`)
}

getList()
</script>
