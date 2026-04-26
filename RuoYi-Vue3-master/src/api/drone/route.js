import request from '@/utils/request'

export function listRoute(query) {
  return request({
    url: '/drone/route/list',
    method: 'get',
    params: query
  })
}

export function getRoute(routeId) {
  return request({
    url: '/drone/route/' + routeId,
    method: 'get'
  })
}

export function addRoute(data) {
  return request({
    url: '/drone/route',
    method: 'post',
    data
  })
}

export function updateRoute(data) {
  return request({
    url: '/drone/route',
    method: 'put',
    data
  })
}

export function delRoute(routeId) {
  return request({
    url: '/drone/route/' + routeId,
    method: 'delete'
  })
}
