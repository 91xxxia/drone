import request from '@/utils/request'

export function listDevice(query) {
  return request({
    url: '/drone/device/list',
    method: 'get',
    params: query
  })
}

export function getDevice(deviceId) {
  return request({
    url: '/drone/device/' + deviceId,
    method: 'get'
  })
}

export function addDevice(data) {
  return request({
    url: '/drone/device',
    method: 'post',
    data
  })
}

export function updateDevice(data) {
  return request({
    url: '/drone/device',
    method: 'put',
    data
  })
}

export function delDevice(deviceId) {
  return request({
    url: '/drone/device/' + deviceId,
    method: 'delete'
  })
}
