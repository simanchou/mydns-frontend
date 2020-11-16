<template>
  <div class="app-container">
    <el-table
      v-loading="listLoading"
      :data="list"
      element-loading-text="Loading"
      border
      fit
      highlight-current-row
    >
      <el-table-column align="center" label="ID" width="100">
        <template slot-scope="scope">
          {{ scope.$index | orderId }}
        </template>
      </el-table-column>
      <el-table-column label="Username" align="center">
        <template slot-scope="scope">
          {{ scope.row.username }}
        </template>
      </el-table-column>
      <el-table-column label="Nickname" align="center">
        <template slot-scope="scope">
          <span>{{ scope.row.nickname }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Role" align="center">
        <template slot-scope="scope">
          {{ scope.row.role }}
        </template>
      </el-table-column>
      <el-table-column class-name="status-col" label="Status" align="center">
        <template slot-scope="scope">
          <el-tag :type="scope.row.active | statusFilter">{{ scope.row.active?'Active':'Inactive' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column align="center" prop="created_at" label="Create_time">
        <template slot-scope="scope">
          <span>{{ scope.row.create_at | formatDate }}</span>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script>
import { getList } from '@/api/user'
import { formatRFC3309 } from '@/utils/index'

export default {
  filters: {
    statusFilter(status) {
      const statusMap = {
        true: 'success',
        false: 'danger'
      }
      return statusMap[status]
    },
    formatDate(time) {
      return formatRFC3309(time)
    },
    orderId(id) {
      id += 1
      return id
    }
  },
  data() {
    return {
      list: null,
      listLoading: true
    }
  },
  created() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      this.listLoading = true
      getList().then(response => {
        this.list = response.data
        console.log(this.list)
        this.listLoading = false
      })
    }
  }
}
</script>
