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
      <el-table-column label="操作" width="220" align="center">
        <template #default="scope">
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['drone:result:edit']">编辑</el-button>
          <el-button link type="danger" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['drone:result:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

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
  </div>
</template>

<script setup name="DroneResult">
import { delResult, getResult, listResult, updateResult } from '@/api/drone/result'

const { proxy } = getCurrentInstance()
const loading = ref(false)
const showSearch = ref(true)
const resultList = ref([])
const total = ref(0)
const open = ref(false)
const title = ref('')

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

function handleExport() {
  proxy.download('drone/result/export', { ...queryParams.value }, `drone_result_${new Date().getTime()}.xlsx`)
}

getList()
</script>
