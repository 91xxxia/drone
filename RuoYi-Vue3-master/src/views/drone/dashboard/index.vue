<template>
  <div class="app-container">
    <el-row :gutter="16">
      <el-col :span="6"><el-card><template #header>设备总数</template><div class="stat-num">{{ stats.deviceCount }}</div></el-card></el-col>
      <el-col :span="6"><el-card><template #header>航线总数</template><div class="stat-num">{{ stats.routeCount }}</div></el-card></el-col>
      <el-col :span="6"><el-card><template #header>任务总数</template><div class="stat-num">{{ stats.taskCount }}</div></el-card></el-col>
      <el-col :span="6"><el-card><template #header>结果总数</template><div class="stat-num">{{ stats.resultCount }}</div></el-card></el-col>
    </el-row>
  </div>
</template>

<script setup name="DroneDashboard">
import { getDashboardStats } from '@/api/drone/dashboard'

const stats = ref({
  deviceCount: 0,
  routeCount: 0,
  taskCount: 0,
  resultCount: 0
})

function loadStats() {
  getDashboardStats().then(res => {
    stats.value = res.data || stats.value
  })
}

loadStats()
</script>

<style scoped>
.stat-num {
  font-size: 28px;
  font-weight: 700;
  color: var(--el-color-primary);
}
</style>
