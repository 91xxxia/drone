import request from '@/utils/request'

export function listTask(query) {
  return request({
    url: '/drone/task/list',
    method: 'get',
    params: query
  })
}

export function getTask(taskId) {
  return request({
    url: '/drone/task/' + taskId,
    method: 'get'
  })
}

export function addTask(data) {
  return request({
    url: '/drone/task',
    method: 'post',
    data
  })
}

export function updateTask(data) {
  return request({
    url: '/drone/task',
    method: 'put',
    data
  })
}

export function startTask(taskId) {
  return request({
    url: '/drone/task/start/' + taskId,
    method: 'put'
  })
}

export function finishTask(taskId) {
  return request({
    url: '/drone/task/finish/' + taskId,
    method: 'put'
  })
}

export function cancelTask(taskId) {
  return request({
    url: '/drone/task/cancel/' + taskId,
    method: 'put'
  })
}

export function delTask(taskId) {
  return request({
    url: '/drone/task/' + taskId,
    method: 'delete'
  })
}
