<template>
  <div class="app-container">
    <div class="filter-container">
      <el-input v-model="listQuery.zone" placeholder="Domain" style="width: 200px;" class="filter-item" @input="handleFilter('zone')" />
      <el-button v-waves class="filter-item" type="primary" icon="el-icon-refresh" @click="handleRefresh">
        Refresh
      </el-button>
      <el-button class="filter-item" style="margin-left: 10px;" type="primary" icon="el-icon-edit" @click="handleCreate">
        Add
      </el-button>
      <!--<el-button v-waves :loading="downloadLoading" class="filter-item" type="primary" icon="el-icon-download" @click="handleDownload">
        Export
      </el-button>-->
    </div>

    <el-table
      ref="multipleTable"
      :key="tableKey"
      v-loading="listLoading"
      :data="list.slice((currentPage-1)*pagesize,currentPage*pagesize)"
      border
      fit
      highlight-current-row
      style="width: 100%;"
      :row-key="getRowKey"
      @sort-change="sortChange"
      @selection-change="handleSelectionChange"
    >
      <el-table-column align="center" label="ID" width="100">
        <template slot-scope="scope">
          {{ scope.$index | orderId }}
        </template>
      </el-table-column>
      <el-table-column label="Domain" align="center">
        <template slot-scope="{row}">
          <span class="link-type" @click="handleAddRouter(row.zone)">{{ row.zone }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Owner" align="center">
        <template slot-scope="{row}">
          <span>{{ row.user }}</span>
        </template>
      </el-table-column>
      <el-table-column align="center" prop="created_at" label="Create_time">
        <template slot-scope="{row}">
          <span>{{ row.create_at | formatDate }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Actions" align="center" class-name="small-padding fixed-width">
        <template slot-scope="{row,$index}">
          <el-button type="primary" size="mini" @click="handleUpdate(row)">
            Edit
          </el-button>
          <el-button v-if="row.status!='deleted'" size="mini" type="danger" @click="handleDelete(row,$index)">
            Delete
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" :page.sync="listQuery.page" :limit.sync="listQuery.limit" @pagination="page" />

    <el-dialog :title="dialogItemTextMap[dialogItemStatus]" :visible.sync="dialogItemVisible">
      <el-form ref="itemDataForm" :rules="rules" :model="temp" label-position="left" label-width="100px" style="width: 400px; margin-left:50px;">
        <el-form-item label="Domain" prop="zone">
          <el-input v-model="temp.zone" @change="createData()" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogItemVisible = false">
          Cancel
        </el-button>
        <el-button type="primary" @click="createData()">
          Confirm
        </el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
// import { fetchList, fetchPv, createArticle, updateArticle } from '@/api/article'
import { getList, deleteDomain, addDomain } from '@/api/domain'
import { formatRFC3309 } from '@/utils/index'
import waves from '@/directive/waves' // waves directive
import { parseTime } from '@/utils/index'
import Pagination from '@/components/Pagination' // secondary package based on el-pagination

const calendarTypeOptions = [
  { key: 'CN', display_name: 'China' },
  { key: 'US', display_name: 'USA' },
  { key: 'JP', display_name: 'Japan' },
  { key: 'EU', display_name: 'Eurozone' }
]

// arr to obj, such as { CN : "China", US : "USA" }
const calendarTypeKeyValue = calendarTypeOptions.reduce((acc, cur) => {
  acc[cur.key] = cur.display_name
  return acc
}, {})

const roleTypeOptions = [
  { key: 'administrator', display_name: '管理员' },
  { key: 'editor', display_name: '编辑者' },
  { key: 'viewer', display_name: '观察者' }
]

const roleTypeKeyValue = roleTypeOptions.reduce((acc, cur) => {
  acc[cur.key] = cur.display_name
  return acc
}, {})

const activeTypeOptions = [
  { key: true, display_name: '启用' },
  { key: false, display_name: '禁用' }
]

const activeTypeKeyValue = activeTypeOptions.reduce((acc, cur) => {
  acc[cur.key] = cur.display_name
  return acc
}, {})

const actionTypeOptions = [
  // { key: 'active', display_name: '启用' },
  // { key: 'inactive', display_name: '禁用' },
  { key: 'delete', display_name: '删除' }
]

const actionTypeKeyValue = actionTypeOptions.reduce((acc, cur) => {
  acc[cur.key] = cur.display_name
  return acc
}, {})

export default {
  name: 'Domain',
  components: { Pagination },
  directives: { waves },
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
    },
    typeFilter(type) {
      return calendarTypeKeyValue[type]
    },
    roleTypeFilter(type) {
      return roleTypeKeyValue[type]
    },
    activeTypeFilter(type) {
      return activeTypeKeyValue[type]
    },
    actionTypeFilter(type) {
      return actionTypeKeyValue[type]
    }
  },
  data() {
    return {
      tableKey: 0,
      list: [],
      listOrgin: [],
      listFilteredVersion: {},
      listFilteredVersionNumber: 0,
      total: 0,
      pagesize: 10,
      currentPage: 1,
      listLoading: true,
      listQuery: {
        page: 1,
        limit: 10,
        zone: undefined,
        nickname: undefined,
        role: undefined,
        active: undefined,
        sort: '+id'
      },
      dialogItemInput: false,
      selected: [],
      importanceOptions: [1, 2, 3],
      calendarTypeOptions,
      roleTypeOptions,
      activeTypeOptions,
      sortOptions: [{ label: 'ID Ascending', key: '+id' }, { label: 'ID Descending', key: '-id' }],
      statusOptions: ['published', 'draft', 'deleted'],
      showReviewer: false,
      addZone: '',
      temp: {
        zone: ''
      },
      batchObj: {
        action: '',
        items: []
      },
      actionTypeOptions,
      dialogBatchVisible: false,
      dialogItemVisible: false,
      dialogItemStatus: '',
      dialogItemTextMap: {
        update: 'Edit',
        create: 'Create'
      },
      dialogPvVisible: false,
      pvData: [],
      rules: {
        type: [{ required: true, message: 'type is required', trigger: 'change' }],
        timestamp: [{ type: 'date', required: true, message: 'timestamp is required', trigger: 'change' }],
        title: [{ required: true, message: 'title is required', trigger: 'blur' }]
      },
      downloadLoading: false
    }
  },
  created() {
    this.getList()
  },
  methods: {
    getList() {
      this.listLoading = true
      getList().then(response => {
        this.list = response.data.map((x) => {
          x.zone = x.zone.substring(0, x.zone.length - 1)
          return x
        })
        this.listOrgin = this.list
        this.total = response.data.length

        // Just to simulate the time of the request
        // setTimeout(() => {
        //   this.listLoading = false
        // }, 1.5 * 1000)
      })
      this.listLoading = false
    },
    page() {
      this.currentPage = this.listQuery.page
      this.pagesize = this.listQuery.limit
    },
    current_change: function(currentPage) {
      this.currentPage = currentPage
    },
    handleSelectionChange(val) {
      this.selected = val
    },
    handleBatchOperation() {
      this.dialogBatchVisible = true
      this.batchObj.items = this.selected
    },
    handleRefresh() {
      this.listFilteredVersion = {}
      this.listFilteredVersionNumber = 0
      this.listQuery.zone = ''
      this.list = this.listOrgin
    },
    handleFilter(item) {
      var listFiltered = []
      switch (item) {
        case 'zone':
          if (this.listQuery.zone) {
            this.listOrgin.map((x) => {
              if (x.zone.indexOf(this.listQuery.zone) >= 0) {
                listFiltered.push(x)
              }
            })
            this.list = listFiltered
            this.listFilteredVersionNumber += 1
            this.listFilteredVersion[this.listFilteredVersionNumber] = listFiltered
          } else {
            this.list = this.listOrgin
          }
          break
        default:
          this.list = this.listOrgin
      }
    },
    getRowKey(row) {
      return row.id
    },
    handleModifyStatus(row, status) {
      this.$message({
        message: '操作Success',
        type: 'success'
      })
      row.status = status
    },
    sortChange(data) {
      const { prop, order } = data
      if (prop === 'id') {
        this.sortByID(order)
      }
    },
    sortByID(order) {
      if (order === 'ascending') {
        this.listQuery.sort = '+id'
      } else {
        this.listQuery.sort = '-id'
      }
      this.handleFilter()
    },
    resetTemp() {
      this.temp = {
        id: undefined,
        importance: 1,
        remark: '',
        timestamp: new Date(),
        title: '',
        status: 'published',
        type: ''
      }
    },
    handleCreate() {
      this.resetTemp()
      this.dialogItemInput = false
      this.dialogItemStatus = 'create'
      this.dialogItemVisible = true
      this.$nextTick(() => {
        this.$refs['itemDataForm'].clearValidate()
      })
    },
    createData() {
      this.$refs['itemDataForm'].validate((valid) => {
        if (valid) {
          addDomain(this.temp.zone).then(() => {
            // this.list.unshift(this.temp)
            this.dialogItemVisible = false
            this.$notify({
              title: 'Success',
              message: 'Created Successfully',
              type: 'success',
              duration: 2000
            })
            this.getList()
          })
        }
      })
    },
    handleUpdate(row) {
      this.temp = Object.assign({}, row) // copy obj
      this.temp.timestamp = new Date(this.temp.timestamp)
      this.dialogItemInput = true
      this.temp.password = ''
      this.dialogItemStatus = 'update'
      this.dialogItemVisible = true
      this.$nextTick(() => {
        this.$refs['itemDataForm'].clearValidate()
      })
    },
    handleDelete(row, index) {
      this.$confirm('此操作将永久删除该文件, 是否继续?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteDomain(row.zone).then(() => {
          this.$message({
            type: 'success',
            message: '删除成功!'
          })
        })
        this.list.splice(index, 1)
      }).catch(() => {
        this.$message({
          type: 'info',
          message: '已取消删除'
        })
      })
    },
    formatJson(filterVal) {
      return this.list.map(v => filterVal.map(j => {
        if (j === 'timestamp') {
          return parseTime(v[j])
        } else {
          return v[j]
        }
      }))
    },
    getSortClass: function(key) {
      const sort = this.listQuery.sort
      return sort === `+${key}` ? 'ascending' : 'descending'
    },
    handleAddRouter(p) {
      this.$router.push({ name: 'Record', title: '', params: { recordid: p }})
    }
  }
}
</script>
