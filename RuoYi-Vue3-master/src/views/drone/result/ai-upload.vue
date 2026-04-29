<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="AI识别图片上传">
      <template #title>
        <span>返回</span>
      </template>
      <template #content>
        <span>AI识别图片上传 - {{ resultInfo?.resultCode }}</span>
      </template>
    </el-page-header>

    <el-row :gutter="20" class="mt-20">
      <!-- 左侧：结果信息 -->
      <el-col :span="8">
        <el-card class="result-info-card">
          <template #header>
            <div class="card-header">
              <span>巡防结果信息</span>
            </div>
          </template>

          <el-descriptions :column="1" border size="small">
            <el-descriptions-item label="结果编号">{{ resultInfo?.resultCode }}</el-descriptions-item>
            <el-descriptions-item label="任务名称">{{ resultInfo?.taskName }}</el-descriptions-item>
            <el-descriptions-item label="设备">{{ resultInfo?.deviceName }}</el-descriptions-item>
            <el-descriptions-item label="航线">{{ resultInfo?.routeName }}</el-descriptions-item>
            <el-descriptions-item label="完成时间">{{ parseTime(resultInfo?.completedTime) }}</el-descriptions-item>
            <el-descriptions-item label="执行人">{{ resultInfo?.executor }}</el-descriptions-item>
          </el-descriptions>

          <div class="result-content">
            <h4>巡防概述</h4>
            <p class="overview-text">{{ resultInfo?.overview }}</p>

            <h4>发现情况</h4>
            <p class="findings-text">{{ resultInfo?.findings || '无' }}</p>

            <h4>处理情况</h4>
            <p class="handling-text">{{ resultInfo?.handling || '无' }}</p>
          </div>
        </el-card>
      </el-col>

      <!-- 右侧：图片上传 -->
      <el-col :span="16">
        <AIResultUpload
          :result-id="resultId"
          :existing-files="resultInfo?.mediaList || []"
          @files-updated="handleFilesUpdated"
          @ai-result="handleAIResult"
        />
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import AIResultUpload from '@/components/AIResultUpload.vue'
import { getResultDetail } from '@/api/drone/result'

const router = useRouter()
const route = useRoute()

const resultId = route.params.resultId
const resultInfo = ref(null)

// 返回上一页
function goBack() {
  router.back()
}

// 获取结果详情
function loadResultDetail() {
  getResultDetail(resultId).then(res => {
    resultInfo.value = res.data
  }).catch(error => {
    console.error('获取结果详情失败:', error)
    ElMessage.error('获取结果详情失败')
  })
}

// 处理文件更新
function handleFilesUpdated(files) {
  console.log('文件已更新:', files)
  // 可以在这里添加保存逻辑
}

// 处理AI识别结果
function handleAIResult(data) {
  console.log('AI识别结果:', data)
  // 保存AI识别结果到后端
  // 这里可以调用API保存识别结果
}

onMounted(() => {
  loadResultDetail()
})
</script>

<style scoped>
.app-container {
  min-height: calc(100vh - 120px);
}

.mt-20 {
  margin-top: 20px;
}

.result-info-card {
  height: fit-content;
  position: sticky;
  top: 20px;
}

.card-header {
  font-weight: 600;
  color: #303133;
}

.result-content {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}

.result-content h4 {
  margin: 15px 0 10px 0;
  color: #303133;
  font-size: 14px;
}

.overview-text,
.findings-text,
.handling-text {
  font-size: 13px;
  color: #606266;
  line-height: 1.6;
  margin: 0;
}

:deep(.el-descriptions__label) {
  width: 80px;
  font-weight: 500;
}

:deep(.el-descriptions__content) {
  word-break: break-all;
}

@media (max-width: 1200px) {
  .el-col-8 {
    width: 100%;
    margin-bottom: 20px;
  }

  .el-col-16 {
    width: 100%;
  }
}
</style>