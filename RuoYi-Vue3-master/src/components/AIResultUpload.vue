<template>
  <div class="ai-result-upload">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>AI识别图片上传</span>
          <el-tag v-if="uploadedFiles.length > 0" size="small" type="success">
            已上传 {{ uploadedFiles.length }} 张
          </el-tag>
        </div>
      </template>

      <!-- 上传区域 -->
      <el-upload
        class="upload-area"
        drag
        :action="uploadUrl"
        :headers="uploadHeaders"
        :data="uploadData"
        :multiple="true"
        :limit="10"
        :on-success="handleUploadSuccess"
        :on-error="handleUploadError"
        :on-exceed="handleExceed"
        :before-upload="beforeUpload"
        :file-list="fileList"
        :on-remove="handleRemove"
        accept="image/*"
        list-type="picture-card"
      >
        <div class="upload-content">
          <el-icon class="upload-icon"><Upload /></el-icon>
          <div class="upload-text">拖拽图片到此处或点击上传</div>
          <div class="upload-hint">支持 JPG、PNG 格式，单个文件不超过 5MB</div>
        </div>
      </el-upload>

      <!-- 已上传图片预览 -->
      <div v-if="uploadedFiles.length > 0" class="uploaded-files">
        <h4>已上传图片</h4>
        <el-row :gutter="10">
          <el-col v-for="file in uploadedFiles" :key="file.url" :span="6">
            <el-card class="file-card">
              <div class="file-preview">
                <el-image
                  :src="file.url"
                  :preview-src-list="getPreviewList()"
                  fit="cover"
                  style="width: 100%; height: 120px;"
                />
              </div>
              <div class="file-info">
                <div class="file-name">{{ file.name }}</div>
                <div class="file-actions">
                  <el-button
                    size="small"
                    type="primary"
                    @click="handleAISimulate(file)"
                    :loading="file.processing"
                  >
                    AI识别
                  </el-button>
                  <el-button
                    size="small"
                    type="danger"
                    @click="handleDeleteFile(file)"
                  >
                    删除
                  </el-button>
                </div>
              </div>
              <!-- AI识别结果 -->
              <div v-if="file.aiResult" class="ai-result">
                <el-tag size="small" :type="getAITagType(file.aiResult.tag)">
                  {{ file.aiResult.tag }}
                </el-tag>
                <div class="ai-coordinates">
                  <small>位置: {{ formatCoordinates(file.aiResult.bbox) }}</small>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>

      <!-- AI模拟识别对话框 -->
      <el-dialog v-model="aiDialogVisible" title="AI识别模拟" width="500px">
        <div v-if="currentFile" class="ai-dialog-content">
          <div class="file-preview-small">
            <el-image :src="currentFile.url" fit="cover" style="width: 100%; height: 200px;" />
          </div>
          <div class="ai-form">
            <el-form :model="aiForm" label-width="80px">
              <el-form-item label="识别标签">
                <el-select v-model="aiForm.tag" placeholder="请选择识别结果" style="width: 100%">
                  <el-option label="船只" value="船只" />
                  <el-option label="漂浮物" value="漂浮物" />
                  <el-option label="障碍物" value="障碍物" />
                  <el-option label="正常水域" value="正常水域" />
                  <el-option label="其他" value="其他" />
                </el-select>
              </el-form-item>
              <el-form-item label="位置坐标">
                <el-input v-model="aiForm.bboxText" placeholder="x,y,w,h" />
              </el-form-item>
            </el-form>
          </div>
        </div>
        <template #footer>
          <el-button @click="aiDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="confirmAIResult">确认</el-button>
        </template>
      </el-dialog>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { Upload } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

const props = defineProps({
  resultId: {
    type: [String, Number],
    required: true
  },
  existingFiles: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['files-updated', 'ai-result'])

// 上传配置
const uploadUrl = computed(() => `/drone/result/${props.resultId}/upload`)
const uploadHeaders = computed(() => ({
  Authorization: `Bearer ${localStorage.getItem('token')}`
}))
const uploadData = computed(() => ({
  resultId: props.resultId
}))

// 数据状态
const fileList = ref([])
const uploadedFiles = ref([...props.existingFiles])
const aiDialogVisible = ref(false)
const currentFile = ref(null)
const aiForm = ref({
  tag: '',
  bboxText: ''
})

// 处理上传成功
function handleUploadSuccess(response, uploadFile, uploadFiles) {
  if (response.code === 200) {
    ElMessage.success('上传成功')
    const newFile = {
      name: uploadFile.name,
      url: response.data.url,
      id: response.data.id
    }
    uploadedFiles.value.push(newFile)
    emit('files-updated', uploadedFiles.value)
  } else {
    ElMessage.error(response.msg || '上传失败')
  }
}

// 处理上传失败
function handleUploadError(error, uploadFile, uploadFiles) {
  console.error('上传失败:', error)
  ElMessage.error('上传失败: ' + (error.message || '未知错误'))
}

// 处理文件超出限制
function handleExceed(files, uploadFiles) {
  ElMessage.warning(`最多只能上传 10 张图片，当前已选择 ${files.length + uploadFiles.length} 张`)
}

// 上传前验证
function beforeUpload(file) {
  const isImage = file.type.startsWith('image/')
  const isLt5M = file.size / 1024 / 1024 < 5

  if (!isImage) {
    ElMessage.error('只能上传图片文件!')
    return false
  }
  if (!isLt5M) {
    ElMessage.error('图片大小不能超过 5MB!')
    return false
  }
  return true
}

// 处理文件移除
function handleRemove(file, fileList) {
  const index = uploadedFiles.value.findIndex(f => f.id === file.id)
  if (index > -1) {
    uploadedFiles.value.splice(index, 1)
    emit('files-updated', uploadedFiles.value)
  }
}

// 获取预览列表
function getPreviewList() {
  return uploadedFiles.value.map(file => file.url)
}

// 处理AI识别模拟
function handleAISimulate(file) {
  currentFile.value = file
  aiForm.value = {
    tag: file.aiResult?.tag || '',
    bboxText: file.aiResult?.bbox ? formatCoordinates(file.aiResult.bbox) : ''
  }
  aiDialogVisible.value = true
}

// 确认AI结果
function confirmAIResult() {
  if (!aiForm.value.tag) {
    ElMessage.warning('请选择识别标签')
    return
  }

  const bbox = parseCoordinates(aiForm.value.bboxText)

  const aiResult = {
    tag: aiForm.value.tag,
    bbox: bbox
  }

  // 更新文件AI结果
  const fileIndex = uploadedFiles.value.findIndex(f => f.url === currentFile.value.url)
  if (fileIndex > -1) {
    uploadedFiles.value[fileIndex].aiResult = aiResult
    uploadedFiles.value[fileIndex].processing = false
  }

  emit('ai-result', {
    file: currentFile.value,
    aiResult: aiResult,
    resultId: props.resultId
  })

  aiDialogVisible.value = false
  ElMessage.success('AI识别结果已保存')
}

// 删除文件
function handleDeleteFile(file) {
  const index = uploadedFiles.value.findIndex(f => f.url === file.url)
  if (index > -1) {
    uploadedFiles.value.splice(index, 1)
    emit('files-updated', uploadedFiles.value)
    ElMessage.success('文件已删除')
  }
}

// 格式化坐标
function formatCoordinates(bbox) {
  if (!bbox) return ''
  return `${bbox.x},${bbox.y},${bbox.w},${bbox.h}`
}

// 解析坐标
function parseCoordinates(coordText) {
  if (!coordText) return null
  const parts = coordText.split(',').map(p => parseInt(p.trim()))
  if (parts.length === 4) {
    return {
      x: parts[0],
      y: parts[1],
      w: parts[2],
      h: parts[3]
    }
  }
  return null
}

// 获取AI标签类型
function getAITagType(tag) {
  const typeMap = {
    '船只': 'primary',
    '漂浮物': 'warning',
    '障碍物': 'danger',
    '正常水域': 'success',
    '其他': 'info'
  }
  return typeMap[tag] || 'info'
}

// 监听现有文件变化
watch(() => props.existingFiles, (newFiles) => {
  uploadedFiles.value = [...newFiles]
}, { deep: true })
</script>

<style scoped>
.ai-result-upload {
  width: 100%;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.upload-area {
  margin-bottom: 20px;
}

.upload-content {
  text-align: center;
  padding: 20px;
}

.upload-icon {
  font-size: 48px;
  color: #409EFF;
  margin-bottom: 16px;
}

.upload-text {
  font-size: 16px;
  color: #606266;
  margin-bottom: 8px;
}

.upload-hint {
  font-size: 12px;
  color: #909399;
}

.uploaded-files {
  margin-top: 20px;
}

.uploaded-files h4 {
  margin: 0 0 15px 0;
  color: #303133;
}

.file-card {
  margin-bottom: 10px;
  transition: all 0.3s;
}

.file-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.file-preview {
  margin-bottom: 10px;
}

.file-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.file-name {
  font-size: 12px;
  color: #606266;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.file-actions {
  display: flex;
  gap: 5px;
  justify-content: center;
}

.ai-result {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px dashed #ebeef5;
  display: flex;
  flex-direction: column;
  gap: 5px;
  align-items: center;
}

.ai-coordinates {
  font-size: 10px;
  color: #909399;
}

.ai-dialog-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.file-preview-small {
  text-align: center;
}

.ai-form {
  padding: 0 20px;
}

:deep(.el-upload--picture-card) {
  width: 120px;
  height: 120px;
  line-height: 120px;
}

:deep(.el-upload-list--picture-card .el-upload-list__item) {
  width: 120px;
  height: 120px;
}
</style>