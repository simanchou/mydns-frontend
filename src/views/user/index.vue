<template>
  <div class="app-container">
    <div class="filter-container">
      <el-input v-model="listQuery.username" placeholder="Username" style="width: 200px;" class="filter-item" @change="handleFilter('username')" />
      <el-input v-model="listQuery.nickname" placeholder="Nickname" style="width: 200px;" class="filter-item" @change="handleFilter('nickname')" />
      <el-select v-model="listQuery.role" placeholder="Role" clearable style="width: 90px" class="filter-item" @change="handleFilter('role')">
        <el-option v-for="item in roleTypeOptions" :key="item.key" :label="item.display_name" :value="item.key" />
      </el-select>
      <el-select v-model="listQuery.active" placeholder="Status" clearable class="filter-item" style="width: 130px" @change="handleFilter('status')">
        <el-option v-for="item in activeTypeOptions" :key="item.key" :label="item.display_name" :value="item.key" />
      </el-select>

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

    <el-button v-if="selected.length" type="primary" size="mini" @click="handleBatchOperation">Batch Action</el-button><!--disabled值动态显示，默认为true,当选中复选框后值为false-->
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
      <el-table-column type="selection" width="55" reserve-selection="" />
      <el-table-column align="center" label="ID" width="100">
        <template slot-scope="scope">
          {{ scope.$index | orderId }}
        </template>
      </el-table-column>
      <el-table-column label="Username" align="center">
        <template slot-scope="{row}">
          <span class="link-type" @click="handleUpdate(row)">{{ row.username }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Nickname" align="center">
        <template slot-scope="{row}">
          <span>{{ row.nickname }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Role" align="center">
        <template slot-scope="{row}">
          {{ row.roles[0] | roleTypeFilter }}
        </template>
      </el-table-column>
      <el-table-column class-name="status-col" label="Status" align="center">
        <template slot-scope="{row}">
          <el-tag :type="row.active | statusFilter">{{ row.active?'active':'inactive' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column align="center" prop="created_at" label="Create_time">
        <template slot-scope="{row}">
          <span>{{ row.create_at | formatDate }}</span>
        </template>
      </el-table-column>
      <el-table-column align="center" prop="update_at" label="Update_time">
        <template slot-scope="{row}">
          <span>{{ row.update_at | formatDate }}</span>
        </template>
      </el-table-column>
      <el-table-column label="Actions" align="center" class-name="small-padding fixed-width">
        <template slot-scope="{row,$index}">
          <el-button v-if="row.username!='admin'" type="primary" size="mini" @click="handleUpdate(row)">
            Edit
          </el-button>
          <el-button v-if="row.username!='admin'" size="mini" type="danger" @click="handleDelete(row,$index)">
            Delete
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total>0" :total="total" :page.sync="listQuery.page" :limit.sync="listQuery.limit" @pagination="page" />
    <!--
        原生分页教程https://www.cnblogs.com/dreamsqin/p/9341230.html
        <el-pagination background layout="total, sizes, prev, pager, next, jumper" :total="total" @current-change="current_change" />-->

    <el-dialog title="Edit" :visible.sync="dialogEditItemVisible">
      <el-form ref="itemDataForm" :model="temp" label-position="left" label-width="100px" style="width: 400px; margin-left:50px;">
        <el-form-item label="Username" prop="username">
          <el-input v-model="temp.username" :disabled="dialogItemInput" />
        </el-form-item>
        <el-form-item label="Nickname" prop="nickname">
          <el-input v-model="temp.nickname" />
        </el-form-item>
        <el-form-item v-if="temp.username!='admin'" label="Role" prop="role">
          <el-select v-model="temp.role" class="filter-item" placeholder="Please select">
            <el-option v-for="item in roleTypeOptions" :key="item.key" :label="item.display_name" :value="item.key" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="temp.username!='admin'" label="Active" prop="active">
          <el-select v-model="temp.active" class="filter-item" placeholder="Please select">
            <el-option v-for="item in activeTypeOptions" :key="item.key" :label="item.display_name" :value="item.key" />
          </el-select>
        </el-form-item>
        <el-form-item label="Password" prop="password">
          <el-input v-model="temp.password" placeholder="won't change if leave blank" show-password />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogEditItemVisible = false">
          Cancel
        </el-button>
        <el-button type="primary" @click="updateData()">
          Confirm
        </el-button>
      </div>
    </el-dialog>

    <el-dialog title="Add" :visible.sync="dialogAddItemVisible">
      <el-form ref="itemDataForm" :rules="rules" :model="temp" label-position="left" label-width="100px" style="width: 400px; margin-left:50px;">
        <el-form-item label="Username" prop="username">
          <el-input v-model="temp.username" :disabled="dialogItemInput" />
        </el-form-item>
        <el-form-item label="Nickname" prop="nickname">
          <el-input v-model="temp.nickname" />
        </el-form-item>
        <el-form-item label="Role" prop="role">
          <el-select v-model="temp.role" class="filter-item" placeholder="Please select">
            <el-option v-for="item in roleTypeOptions" :key="item.key" :label="item.display_name" :value="item.key" />
          </el-select>
        </el-form-item>
        <el-form-item label="Active" prop="active">
          <el-select v-model="temp.active" class="filter-item" placeholder="Please select">
            <el-option v-for="item in activeTypeOptions" :key="item.key" :label="item.display_name" :value="item.key" />
          </el-select>
        </el-form-item>
        <el-form-item label="Password" prop="password">
          <el-input v-model="temp.password" show-password />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogAddItemVisible = false">
          Cancel
        </el-button>
        <el-button type="primary" @click="createData()">
          Confirm
        </el-button>
      </div>
    </el-dialog>

    <el-dialog :visible.sync="dialogBatchVisible" title="Batch Action" width="25%">
      <el-form ref="batchDataForm" :rules="rules" :model="batchObj" label-position="left" label-width="100px" style="width: 400px; margin-left:50px;">
        <el-form-item label="Action Type" prop="actionType">
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
import { getList, updateUser, deleteUser, addUser, batchUser } from '@/api/user'
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
  { key: 'admin', display_name: 'admin' },
  { key: 'editor', display_name: 'editor' },
  { key: 'viewer', display_name: 'viewer' }
]

const roleTypeKeyValue = roleTypeOptions.reduce((acc, cur) => {
  acc[cur.key] = cur.display_name
  return acc
}, {})

const activeTypeOptions = [
  { key: true, display_name: 'active' },
  { key: false, display_name: 'inactive' }
]

const activeTypeKeyValue = activeTypeOptions.reduce((acc, cur) => {
  acc[cur.key] = cur.display_name
  return acc
}, {})

const actionTypeOptions = [
  { key: 'active', display_name: 'active' },
  { key: 'inactive', display_name: 'inactive' },
  { key: 'delete', display_name: 'delete' }
]

const actionTypeKeyValue = actionTypeOptions.reduce((acc, cur) => {
  acc[cur.key] = cur.display_name
  return acc
}, {})

export default {
  name: 'User',
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
        username: undefined,
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
      temp: {
        active: '',
        username: '',
        nickname: '',
        password: '',
        role: ''
      },
      batchObj: {
        action: '',
        items: []
      },
      actionTypeOptions,
      dialogBatchVisible: false,
      dialogEditItemVisible: false,
      dialogAddItemVisible: false,
      dialogItemStatus: '',
      dialogItemTextMap: {
        update: 'Edit',
        create: 'Create'
      },
      dialogPvVisible: false,
      pvData: [],
      rules: {
        username: [{ required: true, message: 'username is required', trigger: 'blur' }],
        nickname: [{ required: true, message: 'nickname is required', trigger: 'blur' }],
        role: [{ required: true, message: 'role is required', trigger: 'blur' }],
        active: [{ required: true, message: 'active is required', trigger: 'blur' }],
        password: [{ required: true, message: 'password is required', trigger: 'blur' }]
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
        this.list = response.data
        this.listOrgin = response.data
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
    handleFilter(item) {
      var listFiltered = []
      var listTemp = []
      switch (item) {
        case 'username':
          if (this.listQuery.username) {
            if (Object.keys(this.listFilteredVersion).length > 0) {
              listTemp = this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
            } else {
              listTemp = this.listOrgin
            }

            listTemp.map((x) => {
              if (x.username.indexOf(this.listQuery.username) >= 0) {
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
        case 'nickname':
          if (this.listQuery.nickname) {
            if (Object.keys(this.listFilteredVersion).length > 0) {
              listTemp = this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
            } else {
              listTemp = this.listOrgin
            }

            listTemp.map((x) => {
              if (x.nickname.indexOf(this.listQuery.nickname) >= 0) {
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
        case 'role':
          if (this.listQuery.role) {
            if (Object.keys(this.listFilteredVersion).length > 0) {
              listTemp = this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
            } else {
              listTemp = this.listOrgin
            }

            listTemp.map((x) => {
              if (x.roles[0].indexOf(this.listQuery.role) >= 0) {
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
        case 'status':
          if (String(this.listQuery.active)) {
            if (Object.keys(this.listFilteredVersion).length > 0) {
              listTemp = this.listFilteredVersion[Object.keys(this.listFilteredVersion).length]
            } else {
              listTemp = this.listOrgin
            }

            listTemp.map((x) => {
              if (x.active === this.listQuery.active) {
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
      this.listQuery.username = ''
      this.listQuery.nickname = ''
      this.listQuery.role = ''
      this.listQuery.active = ''
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
        active: '',
        username: '',
        nickname: '',
        password: '',
        role: '',
        roles: []
      }
    },
    handleCreate() {
      this.resetTemp()
      this.dialogItemInput = false
      this.dialogItemStatus = 'create'
      this.dialogAddItemVisible = true
      this.$nextTick(() => {
        this.$refs['itemDataForm'].clearValidate()
      })
    },
    createData() {
      if (this.temp.role) { this.temp.roles.push(this.temp.role) }
      this.$refs['itemDataForm'].validate((valid) => {
        if (valid) {
          addUser(this.temp).then(() => {
            this.list.unshift(this.temp)
            this.dialogAddItemVisible = false
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
    goToProfile() {
      this.$confirm('go to Profile if you want to change something for admin user', 'Notice', {
        confirmButtonText: 'Turn to Profile',
        cancelButtonText: 'Cancel',
        type: 'warning'
      }).then(() => {
        console.log('begin to turn to profile..........')
        this.$router.push({ name: 'Profile' })
      }).catch(() => {
        this.$message({
          type: 'info',
          message: 'You choose cancel'
        })
      })
    },
    handleUpdate(row) {
      this.temp = Object.assign({}, row) // copy obj
      if (this.temp.username === 'admin') {
        this.goToProfile()
      } else {
        this.temp.role = this.temp.roles[0]
        this.dialogItemInput = true
        this.temp.password = ''
        this.dialogItemStatus = 'update'
        this.dialogEditItemVisible = true
        this.$nextTick(() => {
          this.$refs['itemDataForm'].clearValidate()
        })
      }
    },
    updateData() {
      this.$refs['itemDataForm'].validate((valid) => {
        if (valid) {
          const tempData = Object.assign({}, this.temp)
          updateUser(tempData).then(() => {
            const index = this.list.findIndex(v => v.id === tempData.id)
            this.list.splice(index, 1, this.temp)
            this.dialogEditItemVisible = false
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
    handleDeleteOld(row, index) {
      this.$notify({
        title: 'Success',
        message: 'Delete Successfully',
        type: 'success',
        duration: 2000
      })
      this.list.splice(index, 1)
    },
    handleDelete(row, index) {
      this.$confirm('This item will be delete, and can not restore.Continue?', 'Warning', {
        confirmButtonText: 'Confirm',
        cancelButtonText: 'Cancel',
        type: 'warning'
      }).then(() => {
        deleteUser(row.id).then(() => {
          this.$message({
            type: 'success',
            message: 'Delete Successful!'
          })
          this.list.splice(index, 1)
        }).catch(() => {
          this.$message({
            type: 'error',
            message: 'Delete Fail!'
          })
        })
      }).catch(() => {
        this.$message({
          type: 'info',
          message: 'You choose cancel'
        })
      })
    },
    handleBatch() {
      this.$confirm('此操作为批处理动作,涉及多个条目, 是否继续?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        batchUser(this.batchObj).then((resp) => {
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
