<template>
  <div class="app-container">
    <div class="filter-container">
      <el-input v-model="listQuery.name" placeholder="Name" style="width: 200px;" class="filter-item" @input="handleFilter('name')" />
      <el-input v-model="listQuery.value" placeholder="Value" style="width: 200px;" class="filter-item" @input="handleFilter('value')" />
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

    <el-button v-if="selected.length" type="primary" size="mini" @click="handleBatchOperation">批量操作</el-button><!--disabled值动态显示，默认为true,当选中复选框后值为false-->
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
      <el-table-column type="selection" width="50" reserve-selection="" :selectable="handleSelectAble" />
      <!--<el-table-column align="center" label="ID" width="50">
        <template slot-scope="scope">
          {{ scope.$index | orderId }}
        </template>
      </el-table-column>-->
      <el-table-column label="Type" align="center" width="100">
        <template slot-scope="{row}">
          <span>{{ row.type }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Name" align="center">
        <template slot-scope="{row}">
          <span>{{ row.name }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Value" align="center">
        <template slot-scope="{row}">
          <span>{{ row.value }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Priority" align="center" width="80">
        <template slot-scope="{row}">
          <span>{{ row.type === 'MX'?row.priority:'-' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="TTL" align="center" width="80">
        <template slot-scope="{row}">
          <span>{{ row.ttl }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Actions" align="center" class-name="small-padding fixed-width" width="150">
        <template slot-scope="{row}">
          <el-button v-if="row.type!='NS'" type="primary" size="mini" @click="handleUpdate(row)">
            Edit
          </el-button>
          <el-button v-if="row.type!='NS'" size="mini" type="danger" @click="handleDelete(row)">
            Delete
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" :page.sync="listQuery.page" :limit.sync="listQuery.limit" @pagination="page" />

    <el-dialog :title="dialogItemTextMap[dialogItemStatus]" :visible.sync="dialogItemVisible">
      <el-form ref="itemDataForm" :rules="rules" :model="temp" label-position="left" label-width="100px" style="width: 400px; margin-left:50px;">
        <el-form-item label="Domain" prop="domain">
          <el-input v-model="temp.domain" :disabled="true" />
        </el-form-item>
        <el-form-item label="Type" prop="type">
          <el-select v-model="temp.type" class="filter-item" placeholder="Please select" @change="handleTypeSelect">
            <el-option v-for="item in recordTypeOptions" :key="item.key" :label="item.display_name" :value="item.key" />
          </el-select>
        </el-form-item>
        <el-form-item label="Name" prop="name">
          <el-input v-model="temp.name" />
        </el-form-item>
        <el-form-item label="Value" prop="value">
          <el-input v-model="temp.value" />
        </el-form-item>
        <el-form-item v-if="isMXType" label="Priority" prop="priority">
          <el-input v-model="temp.priority" />
        </el-form-item>
        <el-form-item label="TTL" prop="ttl">
          <el-input v-model="temp.ttl" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogItemVisible = false">
          Cancel
        </el-button>
        <el-button type="primary" @click="dialogItemStatus==='create'?createData():updateData()">
          Confirm
        </el-button>
      </div>
    </el-dialog>

    <el-dialog :visible.sync="dialogBatchVisible" title="批量操作" width="25%">
      <el-form ref="batchDataForm" :rules="rules" :model="batchObj" label-position="left" label-width="100px" style="width: 400px; margin-left:50px;">
        <el-form-item label="操作类型" prop="actionType">
          <el-select v-model="batchObj.action" class="filter-item" placeholder="Please select">
            <el-option v-for="item in actionTypeOptions" :key="item.key" :label="item.display_name" :value="item.key" />
          </el-select>
        </el-form-item>
      </el-form>

      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogBatchVisible = false">
          Cancel
        </el-button>
        <el-button type="primary" @click="handleBatch()">
          Confirm
        </el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
// import { fetchList, fetchPv, createArticle, updateArticle } from '@/api/article'
import { getList, addRecord, deleteRecord, batchRecord, updateRecord } from '@/api/record'
import { formatRFC3309 } from '@/utils/index'
import waves from '@/directive/waves' // waves directive
import { parseTime } from '@/utils/index'
import Pagination from '@/components/Pagination' // secondary package based on el-pagination
import { checkTTLMin } from '@/utils/form-rules'

const recordTypeOptions = [
  { key: 'A', display_name: 'A' },
  { key: 'CNAME', display_name: 'CNAME' },
  { key: 'TXT', display_name: 'TXT' },
  { key: 'MX', display_name: 'MX' },
  { key: 'AAAA', display_name: 'AAAA' }
]

const recordTypeKeyValue = recordTypeOptions.reduce((acc, cur) => {
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
    roleTypeFilter(type) {
      return recordTypeKeyValue[type]
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
      domain: this.$route.params.recordid,
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
        name: undefined,
        value: undefined,
        sort: '+id'
      },
      dialogItemInput: false,
      selected: [],
      importanceOptions: [1, 2, 3],
      recordTypeOptions,
      activeTypeOptions,
      sortOptions: [{ label: 'ID Ascending', key: '+id' }, { label: 'ID Descending', key: '-id' }],
      statusOptions: ['published', 'draft', 'deleted'],
      showReviewer: false,
      addZone: '',
      isMXType: false,
      temp: {
        id: '',
        domain: '',
        type: '',
        name: '',
        value: '',
        priority: 0,
        ttl: 0
      },
      batchObj: {
        domain: '',
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
        name: [{ required: true, message: 'name is required', trigger: 'change' }],
        value: [{ required: true, message: 'value is required', trigger: 'change' }],
        ttl: [{ validator: checkTTLMin, trigger: 'change' }]
      },
      downloadLoading: false
    }
  },
  created() {
    this.getList()
    this.$route.meta.title = this.$route.params.recordid
    this.$store.dispatch('tagsView/updateViewTitle', this.$route)
  },
  methods: {
    getList() {
      this.listLoading = true
      getList(this.domain).then(response => {
        this.list = response.data.map((x) => {
          if (x.value.charAt(x.value.length - 1) === '.') {
            x.value = x.value.substring(0, x.value.length - 1)
          }
          return x
        })
        this.listOrgin = this.list
        this.total = this.list.length

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
    handleSelectAble(row) {
      return row.type !== 'NS'
    },
    handleSelectionChange(val) {
      this.selected = val
    },
    handleBatchOperation() {
      this.dialogBatchVisible = true
      this.batchObj.domain = this.domain
      this.batchObj.items = this.selected
    },
    handleFilter(item) {
      var listFiltered = []
      var listTemp = []
      switch (item) {
        case 'name':
          if (this.listQuery.name) {
            if (Object.keys(this.listFilteredVersion).length > 0) {
              listTemp = this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
            } else {
              listTemp = this.listOrgin
            }

            listTemp.map((x) => {
              if (x.name.indexOf(this.listQuery.name) >= 0) {
                listFiltered.push(x)
              }
            })
            this.list = listFiltered
            this.listFilteredVersionNumber += 1
            this.listFilteredVersion[this.listFilteredVersionNumber] = listFiltered
          } else {
            if (Object.keys(this.listFilteredVersion).length > 1) {
              this.list = this.listFilteredVersion[Object.keys(this.listFilteredVersion).length - 1]
              delete this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
              this.listFilteredVersionNumber -= 1
            } else if (Object.keys(this.listFilteredVersion).length === 1) {
              this.list = this.listOrgin
              delete this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
              this.listFilteredVersionNumber -= 1
            } else {
              this.list = this.listOrgin
            }
          }
          break
        case 'value':
          if (this.listQuery.value) {
            if (Object.keys(this.listFilteredVersion).length > 0) {
              listTemp = this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
            } else {
              listTemp = this.listOrgin
            }

            listTemp.map((x) => {
              if (x.value.indexOf(this.listQuery.value) >= 0) {
                listFiltered.push(x)
              }
            })
            this.list = listFiltered
            this.listFilteredVersionNumber += 1
            this.listFilteredVersion[this.listFilteredVersionNumber] = listFiltered
          } else {
            if (Object.keys(this.listFilteredVersion).length > 1) {
              this.list = this.listFilteredVersion[Object.keys(this.listFilteredVersion).length - 1]
              delete this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
              this.listFilteredVersionNumber -= 1
            } else if (Object.keys(this.listFilteredVersion).length === 1) {
              this.list = this.listOrgin
              delete this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
              this.listFilteredVersionNumber -= 1
            } else {
              this.list = this.listOrgin
            }
          }
          break
        default:
          this.list = this.listOrgin
      }
    },
    handleRefresh() {
      this.listFilteredVersion = {}
      this.listFilteredVersionNumber = 0
      this.listQuery.value = ''
      this.listQuery.name = ''
      this.list = this.listOrgin
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
        domain: this.domain,
        type: '',
        name: '',
        value: '',
        priority: 10,
        ttl: 600
      }
    },
    handleTypeSelect() {
      if (this.temp.type === 'MX') {
        this.isMXType = true
      } else {
        this.isMXType = false
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
          addRecord(this.temp).then(() => {
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
      if (this.temp.type === 'MX') {
        this.isMXType = true
      } else {
        this.isMXType = false
      }
      this.temp.domain = this.domain
      this.dialogItemInput = true
      this.dialogItemStatus = 'update'
      this.dialogItemVisible = true
      this.$nextTick(() => {
        this.$refs['itemDataForm'].clearValidate()
      })
    },
    updateData() {
      this.$refs['itemDataForm'].validate((valid) => {
        if (valid) {
          const tempData = Object.assign({}, this.temp)
          updateRecord(tempData).then(() => {
            const index = this.list.findIndex(v => v.id === this.temp.id)
            this.list.splice(index, 1, this.temp)
            this.dialogItemVisible = false
            this.$notify({
              title: 'Success',
              message: 'Update Successfully',
              type: 'success',
              duration: 2000
            })
            this.getList()
          })
        }
      })
    },
    handleDelete(row) {
      this.$confirm('此操作将永久删除该记录, 是否继续?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteRecord(this.domain, row.id).then(() => {
          this.$message({
            type: 'success',
            message: '删除成功!'
          })
        })
        const index = this.list.findIndex((x) => {
          return x.id === row.id
        })
        this.list.splice(index, 1)
      }).catch(() => {
        this.$message({
          type: 'info',
          message: '已取消删除'
        })
      })
    },
    handleBatch() {
      this.$confirm('此操作为批处理动作,涉及多个条目, 是否继续?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        batchRecord(this.batchObj).then((resp) => {
          this.dialogBatchVisible = false
          this.$message({
            type: 'success',
            message: resp.msg
          })
          this.$refs.multipleTable.clearSelection()
          this.selected = []
          this.getList()
        })
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
    }
  }
}
</script>
