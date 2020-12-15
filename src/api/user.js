import request from '@/utils/request'

export function login(data) {
  return request({
    url: '/auth',
    method: 'post',
    data
  })
}

export function logout() {
  return request({
    url: '/api/logout',
    method: 'post'
  })
}

export function getInfo(token) {
  return request({
    url: '/api/users/info',
    method: 'get'
    // params: { token }
  })
}

export function getList() {
  return request({
    url: '/api/users',
    method: 'get'
  })
}

export function addUser(data) {
  return request({
    url: '/api/users',
    method: 'post',
    data
  })
}

export function updateUser(data) {
  return request({
    url: '/api/users',
    method: 'put',
    data
  })
}

export function deleteUser(id) {
  return request({
    url: '/api/users/' + id,
    method: 'delete'
  })
}

export function batchUser(data) {
  return request({
    url: '/api/users/batch',
    method: 'post',
    data
  })
}

export function chPassword(data) {
  return request({
    url: '/api/users/chpw',
    method: 'post',
    data
  })
}

export function getSum() {
  return request({
    url: '/api/sys/sum',
    method: 'get'
  })
}
