import request from '@/utils/request'

export function getDashboardStats() {
  return request({
    url: '/drone/dashboard/stats',
    method: 'get'
  })
}
