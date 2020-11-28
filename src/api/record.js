import request from '@/utils/request'

export function getList(domain) {
  return request({
    url: '/api/record?domain=' + domain,
    method: 'get'
  })
}

export function addRecord(data) {
  return request({
    url: '/api/record',
    method: 'post',
    data
  })
}

export function updateRecord(data) {
  return request({
    url: '/api/record',
    method: 'put',
    data
  })
}

export function deleteRecord(zone, id) {
  return request({
    url: '/api/record',
    method: 'delete',
    params: { domain: zone, id: id }
  })
}

export function batchRecord(data) {
  return request({
    url: '/api/record/batch',
    method: 'post',
    data
  })
}
