import request from '@/utils/request'

export function listResult(query) {
  return request({
    url: '/drone/result/list',
    method: 'get',
    params: query
  })
}

export function getResult(resultId) {
  return request({
    url: '/drone/result/' + resultId,
    method: 'get'
  })
}

export function getResultDetail(resultId) {
  return request({
    url: '/drone/result/detail/' + resultId,
    method: 'get'
  })
}

export function updateResult(data) {
  return request({
    url: '/drone/result',
    method: 'put',
    data
  })
}

export function delResult(resultId) {
  return request({
    url: '/drone/result/' + resultId,
    method: 'delete'
  })
}
