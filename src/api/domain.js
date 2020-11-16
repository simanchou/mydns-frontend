import request from '@/utils/request'

export function getList() {
  return request({
    url: '/api/domains',
    method: 'get'
  })
}

export function addDomain(zone) {
  return request({
    url: '/api/domains?zone=' + zone,
    method: 'post'
  })
}

export function updateDomain(id, data) {
  return request({
    url: '/api/domains/' + id,
    method: 'put',
    data
  })
}

export function deleteDomain(zone) {
  return request({
    url: '/api/domains/' + zone,
    method: 'delete'
  })
}

export function batchDomain(data) {
  return request({
    url: '/api/domains/batch',
    method: 'post',
    data
  })
}
