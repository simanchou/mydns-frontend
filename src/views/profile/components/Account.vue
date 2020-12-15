<template>
  <el-form ref="itemDataForm" :rules="rules" :model="temp">
    <el-form-item label="Old Password" prop="oldPW">
      <el-input v-model.trim="temp.oldPW" show-password />
    </el-form-item>
    <el-form-item label="New Password" prop="newPW">
      <el-input v-model.trim="temp.newPW" show-password @keyup.enter.native="updateData" />
    </el-form-item>
    <el-form-item>
      <el-button type="primary" @click="updateData">Update</el-button>
    </el-form-item>
  </el-form>
</template>

<script>

import { chPassword } from '@/api/user'

export default {
  props: {
    user: {
      type: Object,
      default: () => {
        return {
          name: '',
          email: ''
        }
      }
    }
  },
  data() {
    return {
      temp: {
        oldPW: undefined,
        newPW: undefined
      },
      rules: {
        oldPW: [{ required: true, message: 'old password is required', trigger: 'blur' }],
        newPW: [{ required: true, message: 'new password is required', trigger: 'blur' }]
      }
    }
  },
  methods: {
    submit() {
      this.$message({
        message: 'User information has been updated successfully',
        type: 'success',
        duration: 5 * 1000
      })
    },
    updateData() {
      this.$refs['itemDataForm'].validate((valid) => {
        if (valid) {
          const tempData = Object.assign({}, this.temp)
          chPassword(tempData).then(() => {
            this.$notify({
              title: 'Success',
              message: 'Update Successfully',
              type: 'success',
              duration: 2000
            })
            this.temp.oldPW = ''
            this.temp.newPW = ''
          }).catch(() => {
            this.$message({
              type: 'error',
              message: 'Update Fail'
            })
          })
        }
      })
    }
  }
}
</script>
