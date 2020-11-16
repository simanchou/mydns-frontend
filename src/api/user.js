import request from '@/utils/request'

export function login(data) {
  return request({
    url: '/api/v1/login',
    method: 'post',
    data
  })
}

export function logout() {
  return request({
    url: '/api/v1/logout',
    method: 'post'
  })
}

export function getInfo(token) {
  return request({
    url: '/api/v1/user/info',
    method: 'get'
    // params: { token }
  })
}

export function getList() {
  return request({
    url: '/api/v1/users',
    method: 'get'
  })
}

export function addUser(data) {
  return request({
    url: '/api/v1/users',
    method: 'post',
    data
  })
}

export function updateUser(id, data) {
  return request({
    url: '/api/v1/users/' + id,
    method: 'put',
    data
  })
}

export function deleteUser(id) {
  return request({
    url: '/api/v1/users/' + id,
    method: 'delete'
  })
}

export function batchUser(data) {
  return request({
    url: '/api/v1/users/batch',
    method: 'post',
    data
  })
}
