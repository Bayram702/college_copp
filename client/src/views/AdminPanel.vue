<template>
  <div class="admin-panel">
    <div class="breadcrumbs">
      <div class="container">
        <router-link to="/">Главная</router-link> >
        <span>Панель администратора</span>
      </div>
    </div>

    <!-- Вкладки -->
    <div class="container">
      <div class="tabs">
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'users' }"
          @click="activeTab = 'users'"
        >
          <i class="fas fa-users"></i> Пользователи
        </button>
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'colleges' }"
          @click="activeTab = 'colleges'"
        >
          <i class="fas fa-graduation-cap"></i> Колледжи
        </button>
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'sectors' }"
          @click="activeTab = 'sectors'"
        >
          <i class="fas fa-layer-group"></i> Отрасли
        </button>
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'settings' }"
          @click="activeTab = 'settings'"
        >
          <i class="fas fa-cog"></i> Настройки
        </button>
      </div>
    </div>

    <!-- Основной контент -->
    <div class="container">
      <!-- Уведомления -->
      <div v-if="alertMessage" :class="['alert', `alert-${alertType}`]">
        <i :class="alertType === 'success' ? 'fas fa-check-circle' : 'fas fa-info-circle'"></i>
        <div>{{ alertMessage }}</div>
      </div>

      <!-- Вкладка: Пользователи -->
      <div v-if="activeTab === 'users'" class="tab-content active">
        <div class="specialities-header">
          <div class="search-box">
            <i class="fas fa-search"></i>
            <input v-model="userSearch" type="text" placeholder="Поиск пользователей..." @input="debouncedSearch">
          </div>
        </div>

        <!-- Фильтры -->
        <div class="filters-bar">
          <select v-model="userFilters.status" @change="applyUserFilters" class="filter-select">
            <option value="all">Все статусы</option>
            <option value="active">Активные</option>
            <option value="inactive">Неактивные</option>
          </select>
        </div>

        <!-- Таблица пользователей -->
        <div v-if="usersLoading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i> Загрузка...
        </div>
        <div v-else-if="usersError" class="error-state">
          <i class="fas fa-exclamation-triangle"></i> {{ usersError }}
          <button @click="fetchUsers" class="btn-retry">Повторить</button>
        </div>
        <div v-else class="table-container users-table-container">
          <div class="table-scroll">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Номер</th>
                  <th>Пользователь</th>
                  <th>Логин</th>
                  <th>Email</th>
                  <th>Роль</th>
                  <th>Статус</th>
                  <th>Последняя активность</th>
                  <th>Действия</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="user in users" :key="user.id">
                  <td>{{ user.id }}</td>
                  <td>
                    <div class="user-info">
                      <div class="user-avatar">{{ user.name.charAt(0) }}</div>
                      <span>{{ user.name }}</span>
                    </div>
                  </td>
                  <td>{{ user.login }}</td>
                  <td>{{ user.email }}</td>
                  <td>
                    <span class="role-badge" :class="user.role.name">{{ getRoleName(user.role.name) }}</span>
                  </td>
                  <td>
                    <span class="status-badge" :class="getStatusClass(user.status)">{{ getStatusName(user.status) }}</span>
                  </td>
                  <td>{{ formatDate(user.lastLoginAt) }}</td>
                  <td>
                    <div class="action-buttons">
                      <button class="btn-icon btn-edit" @click="editUser(user)" title="Редактировать">
                        <i class="fas fa-edit"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Пагинация -->
          <div v-if="userPagination.totalPages > 1" class="pagination">
            <button class="page-btn" :disabled="userPagination.page === 1" @click="changeUserPage(userPagination.page - 1)">
              <i class="fas fa-chevron-left"></i>
            </button>
            <button v-for="page in visibleUserPages" :key="page" class="page-btn" :class="{ active: userPagination.page === page, dots: page === '...' }" :disabled="page === '...'" @click="changeUserPage(page)">
              {{ page }}
            </button>
            <button class="page-btn" :disabled="userPagination.page === userPagination.totalPages" @click="changeUserPage(userPagination.page + 1)">
              <i class="fas fa-chevron-right"></i>
            </button>
          </div>
        </div>
      </div>

      <!-- Вкладка: Колледжи -->
      <div v-if="activeTab === 'colleges'" class="tab-content active">
        <div class="specialities-header">
          <div class="search-box">
            <i class="fas fa-search"></i>
            <input v-model="collegeSearch" type="text" placeholder="Поиск колледжей..." @input="filterColleges">
          </div>
          <button class="btn-add" @click="openCollegeModal">
            <i class="fas fa-plus"></i> Добавить колледж
          </button>
        </div>
        <div class="filters-bar">
          <select v-model="collegeFilter" @change="filterColleges" class="filter-select">
            <option value="all">Все колледжи</option>
            <option value="active">Активные</option>
            <option value="with_rep">С представителем</option>
            <option value="without_rep">Без представителя</option>
          </select>
          <select v-model="collegeSort" @change="filterColleges" class="filter-select">
            <option value="id">По номеру</option>
            <option value="name_asc">А-Я</option>
            <option value="name_desc">Я-А</option>
          </select>
        </div>

        <div v-if="collegesLoading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i> Загрузка...
        </div>
        <div v-else-if="collegesError" class="error-state">
          <i class="fas fa-exclamation-triangle"></i> {{ collegesError }}
          <button @click="fetchColleges" class="btn-retry">Повторить</button>
        </div>
        <div v-else class="table-container">
          <table class="data-table">
            <thead>
              <tr>
                <th>Номер</th>
                <th>Колледж</th>
                <th>Город</th>
                <th>Статус</th>
                <th>Профессионалитет</th>
                <th>Представитель</th>
                <th>Обновлен</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="college in filteredCollegesList" :key="college.id">
                <td>{{ college.id }}</td>
                <td>
                  <div class="college-info">
                    <strong>{{ college.name }}</strong>
                    <span class="short-name">{{ college.short_name }}</span>
                  </div>
                </td>
                <td>{{ college.city }}</td>
                <td>
                  <span class="status-badge" :class="getStatusClass(college.status)">{{ getStatusName(college.status) }}</span>
                </td>
                <td>
                  <span v-if="college.is_professionalitet" class="prof-badge">
                    <i class="fas fa-check-circle"></i> {{ college.professionalitet_cluster || 'Да' }}
                  </span>
                  <span v-else class="text-muted">Нет</span>
                </td>
                <td>
                  <div v-if="college.representatives.length > 0" class="rep-list">
                    <div v-for="rep in college.representatives" :key="rep.id" class="rep-item">
                      <i class="fas fa-user"></i> {{ rep.name }}
                      <span class="rep-status" :class="rep.status">{{ getStatusName(rep.status) }}</span>
                    </div>
                  </div>
                  <span v-else class="text-muted"><i class="fas fa-user-slash"></i> Нет</span>
                </td>
                <td>{{ formatDate(college.updated_at) }}</td>
              </tr>
            </tbody>
          </table>
          <div v-if="filteredCollegesList.length === 0" class="empty-state">
            <i class="fas fa-graduation-cap"></i>
            <p>Колледжи не найдены</p>
          </div>
        </div>
      </div>

      <!-- Вкладка: Отрасли -->
      <div v-if="activeTab === 'sectors'" class="tab-content active">
        <div class="specialities-header">
          <div class="search-box">
            <i class="fas fa-search"></i>
            <input v-model="sectorSearch" type="text" placeholder="Поиск отраслей..." @input="filterSectors">
          </div>
          <button class="btn-add" @click="openSectorModal">
            <i class="fas fa-plus"></i> Добавить отрасль
          </button>
        </div>

        <div v-if="sectorsLoading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i> Загрузка...
        </div>
        <div v-else-if="sectorsError" class="error-state">
          <i class="fas fa-exclamation-triangle"></i> {{ sectorsError }}
          <button @click="fetchSectors" class="btn-retry">Повторить</button>
        </div>
        <div v-else class="table-container">
          <table class="data-table">
            <thead>
              <tr>
                <th>Номер</th>
                <th>Отрасль</th>
                <th>Код</th>
                <th>Программ</th>
                <th>Колледжей</th>
                <th>Статус</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="sector in filteredSectorsList" :key="sector.id">
                <td>{{ sector.id }}</td>
                <td>
                  <div class="college-info">
                    <strong>{{ sector.name }}</strong>
                    <span v-if="sector.description" class="short-description">{{ sector.description }}</span>
                  </div>
                </td>
                <td><span class="short-name">{{ sector.code }}</span></td>
                <td>{{ sector.programs_count }}</td>
                <td>{{ sector.colleges_count }}</td>
                <td>
                  <span class="status-badge" :class="getActiveClass(sector.is_active)">{{ sector.is_active ? 'Активная' : 'Неактивная' }}</span>
                </td>
              </tr>
            </tbody>
          </table>
          <div v-if="filteredSectorsList.length === 0" class="empty-state">
            <i class="fas fa-layer-group"></i>
            <p>Отрасли не найдены</p>
          </div>
        </div>
      </div>

      <!-- Вкладка: Настройки -->
      <div v-if="activeTab === 'settings'" class="tab-content active">
        <div class="specialities-header">
          <div class="search-box">
            <i class="fas fa-search"></i>
            <input v-model="userSearch" type="text" placeholder="Поиск администраторов..." @input="debouncedSearch">
          </div>
        </div>

        <div class="filters-bar">
          <select v-model="userFilters.status" @change="applyUserFilters" class="filter-select">
            <option value="all">Все статусы</option>
            <option value="active">Активные</option>
            <option value="inactive">Неактивные</option>
          </select>
        </div>

        <div v-if="usersLoading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i> Загрузка...
        </div>
        <div v-else-if="usersError" class="error-state">
          <i class="fas fa-exclamation-triangle"></i> {{ usersError }}
          <button @click="fetchUsers" class="btn-retry">Повторить</button>
        </div>
        <div v-else class="table-container users-table-container">
          <div class="table-scroll">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Номер</th>
                  <th>Администратор</th>
                  <th>Логин</th>
                  <th>Email</th>
                  <th>Статус</th>
                  <th>Последняя активность</th>
                  <th>Действия</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="user in users" :key="user.id">
                  <td>{{ user.id }}</td>
                  <td>
                    <div class="user-info">
                      <div class="user-avatar">{{ user.name.charAt(0) }}</div>
                      <span>{{ user.name }}</span>
                    </div>
                  </td>
                  <td>{{ user.login }}</td>
                  <td>{{ user.email }}</td>
                  <td>
                    <span class="status-badge" :class="getStatusClass(user.status)">{{ getStatusName(user.status) }}</span>
                  </td>
                  <td>{{ formatDate(user.lastLoginAt) }}</td>
                  <td>
                    <div class="action-buttons">
                      <button class="btn-icon btn-edit" @click="editUser(user)" title="Редактировать">
                        <i class="fas fa-edit"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

    </div>

    <!-- Модальное окно пользователя -->
    <div class="modal-overlay" :class="{ active: showUserModal }" @click.self="closeUserModal" v-show="showUserModal">
      <div class="modal">
        <button class="close-modal" @click="closeUserModal">&times;</button>
        <h2>{{ editingUser ? 'Редактировать пользователя' : 'Добавить пользователя' }}</h2>
        <form @submit.prevent="saveUser" class="modal-form">
          <div class="form-row">
            <div class="form-group">
              <label>Имя <span class="required">*</span></label>
              <input v-model="userForm.name" type="text" class="form-control" :class="{ invalid: userErrors.name }" maxlength="255" @input="userForm.name = normalizeTextInput(userForm.name, 255)" required>
              <small v-if="userErrors.name" class="field-error">{{ userErrors.name }}</small>
            </div>
            <div class="form-group">
              <label>Логин <span class="required">*</span></label>
              <input v-model="userForm.login" type="text" class="form-control" :class="{ invalid: userErrors.login }" maxlength="50" @input="userForm.login = maskLogin(userForm.login)" required>
              <small v-if="userErrors.login" class="field-error">{{ userErrors.login }}</small>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Email <span class="required">*</span></label>
              <input v-model="userForm.email" type="email" class="form-control" :class="{ invalid: userErrors.email }" maxlength="255" @input="userForm.email = normalizeEmailInput(userForm.email)" required>
              <small v-if="userErrors.email" class="field-error">{{ userErrors.email }}</small>
              <small v-if="!editingUser" class="form-hint">📧 На этот email будут отправлены логин и пароль для входа</small>
            </div>
            <div class="form-group">
              <label v-if="!editingUser">Пароль <span class="required">*</span></label>
              <label v-else>Новый пароль</label>
              <div class="password-control">
                <input :type="showPassword ? 'text' : 'password'" v-model="userForm.password" class="form-control" :class="{ invalid: userErrors.password }" maxlength="100" :required="!editingUser">
                <button type="button" class="btn-generate-password" @click="generateUserPassword">
                  <i class="fas fa-wand-magic-sparkles"></i>
                  Сгенерировать
                </button>
              </div>
              <small v-if="userErrors.password" class="field-error">{{ userErrors.password }}</small>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Статус</label>
              <select v-model="userForm.status" class="form-control" :class="{ invalid: userErrors.status }">
                <option value="active">Активный</option>
                <option value="inactive">Неактивный</option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label>Телефон</label>
            <input v-model="userForm.phone" type="tel" class="form-control" :class="{ invalid: userErrors.phone }" placeholder="+7 (999) 999-99-99" @input="userForm.phone = maskRussianPhone(userForm.phone)">
            <small v-if="userErrors.phone" class="field-error">{{ userErrors.phone }}</small>
          </div>
          <div v-if="userForm.role === 'college_rep'" class="form-group">
            <label>Колледж</label>
            <select v-model="userForm.college_id" class="form-control" :class="{ invalid: userErrors.college_id }">
              <option value="">Выберите колледж</option>
              <option v-for="c in availableColleges" :key="c.id" :value="c.id">{{ c.name }}</option>
            </select>
            <small v-if="userErrors.college_id" class="field-error">{{ userErrors.college_id }}</small>
          </div>
          <div class="form-actions">
            <button type="submit" class="btn btn-primary" :disabled="saving">
              <i :class="saving ? 'fas fa-spinner fa-spin' : 'fas fa-save'"></i> {{ saving ? 'Сохранение...' : 'Сохранить' }}
            </button>
            <button type="button" class="btn btn-secondary" @click="closeUserModal">Отмена</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Модальное окно колледжа -->
    <div class="modal-overlay" :class="{ active: showCollegeModal }" @click.self="closeCollegeModal" v-show="showCollegeModal">
      <div class="modal">
        <button class="close-modal" @click="closeCollegeModal">&times;</button>
        <h2>Добавить колледж</h2>
        <form @submit.prevent="saveCollege" class="modal-form">
          <div class="form-row">
            <div class="form-group">
              <label>Название <span class="required">*</span></label>
              <input v-model="collegeForm.name" type="text" class="form-control" :class="{ invalid: collegeErrors.name }" maxlength="255" @input="collegeForm.name = normalizeTextInput(collegeForm.name, 255)" required>
              <small v-if="collegeErrors.name" class="field-error">{{ collegeErrors.name }}</small>
            </div>
            <div class="form-group">
              <label>Краткое название</label>
              <input v-model="collegeForm.shortName" type="text" class="form-control" :class="{ invalid: collegeErrors.shortName }" maxlength="50" @input="collegeForm.shortName = normalizeTextInput(collegeForm.shortName, 50)">
              <small v-if="collegeErrors.shortName" class="field-error">{{ collegeErrors.shortName }}</small>
            </div>
          </div>
          <div class="form-group">
            <label>Город</label>
            <input v-model="collegeForm.city" type="text" class="form-control" maxlength="120" @input="collegeForm.city = normalizeTextInput(collegeForm.city, 120)">
          </div>
          <div class="form-group">
            <label>Описание</label>
            <textarea v-model="collegeForm.description" class="form-control" rows="4" maxlength="1000" @input="collegeForm.description = normalizeTextInput(collegeForm.description, 1000)"></textarea>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Телефон</label>
              <input v-model="collegeForm.phone" type="tel" class="form-control" :class="{ invalid: collegeErrors.phone }" placeholder="+7 (999) 999-99-99" @input="collegeForm.phone = maskRussianPhone(collegeForm.phone)">
              <small v-if="collegeErrors.phone" class="field-error">{{ collegeErrors.phone }}</small>
            </div>
            <div class="form-group">
              <label>Email</label>
              <input v-model="collegeForm.email" type="email" class="form-control" :class="{ invalid: collegeErrors.email }" maxlength="255" @input="collegeForm.email = normalizeEmailInput(collegeForm.email)">
              <small v-if="collegeErrors.email" class="field-error">{{ collegeErrors.email }}</small>
            </div>
          </div>
          <div class="form-group">
            <label>Сайт</label>
            <input v-model="collegeForm.website" type="text" class="form-control" :class="{ invalid: collegeErrors.website }" maxlength="255" @input="collegeForm.website = normalizeUrlInput(collegeForm.website)" placeholder="https://example.ru">
            <small v-if="collegeErrors.website" class="field-error">{{ collegeErrors.website }}</small>
          </div>
          <div class="form-actions">
            <button type="submit" class="btn btn-primary" :disabled="saving">
              <i :class="saving ? 'fas fa-spinner fa-spin' : 'fas fa-save'"></i> {{ saving ? 'Сохранение...' : 'Сохранить' }}
            </button>
            <button type="button" class="btn btn-secondary" @click="closeCollegeModal">Отмена</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Модальное окно отрасли -->
    <div class="modal-overlay" :class="{ active: showSectorModal }" @click.self="closeSectorModal" v-show="showSectorModal">
      <div class="modal">
        <button class="close-modal" @click="closeSectorModal">&times;</button>
        <h2>Добавить отрасль</h2>
        <form @submit.prevent="saveSector" class="modal-form">
          <div class="form-row">
            <div class="form-group">
              <label>Название <span class="required">*</span></label>
              <input v-model="sectorForm.name" type="text" class="form-control" :class="{ invalid: sectorErrors.name }" maxlength="255" @input="sectorForm.name = normalizeTextInput(sectorForm.name, 255)" required>
              <small v-if="sectorErrors.name" class="field-error">{{ sectorErrors.name }}</small>
            </div>
            <div class="form-group">
              <label>Коды специальностей <span class="required">*</span></label>
              <input v-model="sectorForm.code" type="text" class="form-control" :class="{ invalid: sectorErrors.code }" maxlength="50" @input="sectorForm.code = maskSectorCode(sectorForm.code)" required>
              <small v-if="sectorErrors.code" class="field-error">{{ sectorErrors.code }}</small>
              <small class="form-hint">Например: 09 или 09, 04. В отрасль попадут все специальности с такими начальными кодами.</small>
            </div>
          </div>
          <div class="form-group">
            <label>Описание</label>
            <textarea v-model="sectorForm.description" class="form-control" rows="4" maxlength="1000" @input="sectorForm.description = normalizeTextInput(sectorForm.description, 1000)"></textarea>
          </div>
          <div class="form-group">
            <label>Фотография отрасли</label>
            <input
              ref="sectorImageInputRef"
              type="file"
              accept="image/jpeg,image/jpg,image/png,image/gif,image/webp"
              @change="handleSectorImageUpload"
              style="display: none"
            >
            <div class="image-upload" @click="triggerSectorImageUpload">
              <i :class="sectorImageUploading ? 'fas fa-spinner fa-spin' : 'fas fa-cloud-upload-alt'"></i>
              <p>{{ sectorImageUploading ? 'Загрузка...' : 'Нажмите для загрузки фотографии' }}</p>
              <p class="text-small">JPEG, PNG, GIF или WebP до 5 МБ</p>
            </div>
            <div v-if="sectorForm.image_url" class="image-preview">
              <img :src="resolveImageUrl(sectorForm.image_url)" alt="Фото отрасли">
              <button type="button" class="remove-image-btn" @click="sectorForm.image_url = ''" title="Удалить изображение">
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
          <div class="form-actions">
            <button type="submit" class="btn btn-primary" :disabled="saving">
              <i :class="saving ? 'fas fa-spinner fa-spin' : 'fas fa-save'"></i> {{ saving ? 'Сохранение...' : 'Сохранить' }}
            </button>
            <button type="button" class="btn btn-secondary" @click="closeSectorModal">Отмена</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import { API_URL } from '../utils/api'
import {
  firstError,
  maskLogin,
  maskRussianPhone,
  normalizeEmailInput,
  normalizeRepresentative,
  normalizeTextInput,
  normalizeUrl,
  normalizeUrlInput,
  validateRepresentative
} from '../utils/validation'
import { resolveImageUrl } from '../utils/images'

const router = useRouter()

const activeTab = ref('users')
const alertMessage = ref('')
const alertType = ref('info')
const saving = ref(false)

// Пользователи
const users = ref([])
const usersLoading = ref(false)
const usersError = ref(null)
const userSearch = ref('')
const userFilters = ref({ role: 'all', status: 'all' })
const userPagination = ref({ total: 0, page: 1, limit: 10, totalPages: 0 })

// Колледжи
const colleges = ref([])
const collegesLoading = ref(false)
const collegesError = ref(null)
const collegeSearch = ref('')
const collegeFilter = ref('all')
const collegeSort = ref('id')
const filteredCollegesList = ref([])

// Отрасли
const sectors = ref([])
const sectorsLoading = ref(false)
const sectorsError = ref(null)
const sectorSearch = ref('')
const filteredSectorsList = ref([])

// Модальное окно
const showUserModal = ref(false)
const editingUser = ref(null)
const showPassword = ref(false)
const userForm = ref({ name: '', login: '', email: '', phone: '', password: '', role: 'college_rep', status: '', college_id: '' })
const userErrors = ref({})
const availableColleges = ref([])
const showCollegeModal = ref(false)
const collegeForm = ref({ name: '', shortName: '', city: '', description: '', phone: '', email: '', website: '' })
const collegeErrors = ref({})
const showSectorModal = ref(false)
const sectorForm = ref({ name: '', code: '', description: '', image_url: '' })
const sectorErrors = ref({})
const sectorImageInputRef = ref(null)
const sectorImageUploading = ref(false)

// Загрузка списка колледжей для модалки
const loadCollegesForSelect = async () => {
  try {
    const token = localStorage.getItem('authToken')
    const res = await axios.get(`${API_URL}/colleges/admin/list`, { headers: { 'Authorization': `Bearer ${token}` } })
    if (res.data.success) {
      const currentCollegeId = editingUser.value
        ? String(userForm.value.college_id || editingUser.value.college?.id || editingUser.value.college_id || '')
        : ''
      availableColleges.value = res.data.data.filter((college) => {
        const representatives = college.representatives || []
        return representatives.length === 0 || String(college.id) === currentCollegeId
      })
    }
  } catch (e) { console.warn('Колледжи не загружены:', e) }
}

let searchTimeout = null

onMounted(() => {
  const token = localStorage.getItem('authToken')
  if (token) axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
  fetchUsers()
})

watch(activeTab, (tab) => {
  if (tab === 'users' || tab === 'settings') {
    userPagination.value.page = 1
    fetchUsers()
  }
  if (tab === 'colleges' && colleges.value.length === 0) fetchColleges()
  if (tab === 'sectors' && sectors.value.length === 0) fetchSectors()
})

// Пользователи
const fetchUsers = async () => {
  usersLoading.value = true
  usersError.value = null
  try {
    const token = localStorage.getItem('authToken')
    const params = new URLSearchParams({ page: userPagination.value.page, limit: userPagination.value.limit })
    params.append('role', activeTab.value === 'settings' ? 'admin' : 'college_rep')
    if (userFilters.value.status !== 'all') params.append('status', userFilters.value.status)
    if (userSearch.value.trim()) params.append('search', userSearch.value.trim())

    const response = await axios.get(`${API_URL}/users?${params.toString()}`, { headers: { 'Authorization': `Bearer ${token}` } })
    if (response.data.success) {
      users.value = response.data.data
      userPagination.value = response.data.pagination
    }
  } catch (err) {
    usersError.value = err.response?.status === 401 ? 'Сессия истекла' : err.message
    if (err.response?.status === 401) { localStorage.removeItem('authToken'); localStorage.removeItem('user'); router.push('/login') }
  } finally { usersLoading.value = false }
}

const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => { userPagination.value.page = 1; fetchUsers() }, 300)
}

const applyUserFilters = () => {
  userPagination.value.page = 1
  fetchUsers()
}

const changeUserPage = (page) => {
  if (typeof page === 'number' && page >= 1 && page <= userPagination.value.totalPages) { userPagination.value.page = page; fetchUsers() }
}

const visibleUserPages = computed(() => {
  const pages = []; const total = userPagination.value.totalPages; const current = userPagination.value.page
  if (total <= 7) {
    for (let i = 1; i <= total; i++) pages.push(i)
  } else {
    pages.push(1)
    if (current > 4) pages.push('...')
    const start = Math.max(2, current - 1)
    const end = Math.min(total - 1, current + 1)
    for (let i = start; i <= end; i++) pages.push(i)
    if (current < total - 3) pages.push('...')
    pages.push(total)
  }
  return pages
})

const getRoleName = (role) => ({ admin: 'Администратор', college_rep: 'Представитель' }[role] || role)
const normalizeUserStatus = (status) => status === 'blocked' ? 'inactive' : status
const getStatusName = (status) => ({ active: 'Активный', inactive: 'Неактивный' }[normalizeUserStatus(status)] || status)
const getStatusClass = (status) => ({ active: 'status-active', inactive: 'status-inactive' }[normalizeUserStatus(status)] || '')
const getActiveClass = (isActive) => isActive ? 'status-active' : 'status-inactive'
const formatDate = (d) => d ? new Date(d).toLocaleDateString('ru-RU') : '—'
const isEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
const isUrl = (value) => /^https?:\/\/[^\s/$.?#].[^\s]*$/i.test(value)
const isPhone = (value) => /^\+7 \(\d{3}\) \d{3}-\d{2}-\d{2}$/.test(value)
const maskSectorCode = (value) => String(value || '').replace(/[^\d,\s]/g, '').replace(/\s+/g, ' ').slice(0, 50)

const generateUserPassword = () => {
  const lower = 'abcdefghijkmnopqrstuvwxyz'
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
  const digits = '23456789'
  const symbols = '!@#$%&*?'
  const groups = [lower, upper, digits, symbols]
  const allChars = groups.join('')
  const bytes = new Uint32Array(14)
  window.crypto.getRandomValues(bytes)
  const required = groups.map((group, index) => group[bytes[index] % group.length])
  const rest = Array.from(bytes.slice(required.length), (value) => allChars[value % allChars.length])
  const password = [...required, ...rest]
    .sort(() => window.crypto.getRandomValues(new Uint32Array(1))[0] / 4294967296 - 0.5)
    .join('')

  userForm.value.password = password
  showPassword.value = true
  delete userErrors.value.password
}

const openAddRepModal = () => {
  console.log('👤 openAddRepModal вызван')
  editingUser.value = null
  userErrors.value = {}
  userForm.value = { name: '', login: '', email: '', phone: '', password: '', role: 'college_rep', status: 'active', college_id: '' }
  showPassword.value = false
  showUserModal.value = true
  console.log('👤 showUserModal =', showUserModal.value)
  loadCollegesForSelect()
}
const closeUserModal = () => { showUserModal.value = false; userErrors.value = {} }
const editUser = (user) => {
  const role = user.role?.name || 'college_rep'
  editingUser.value = user
  userErrors.value = {}
  userForm.value = {
    name: user.name || '',
    login: user.login || '',
    email: user.email || '',
    phone: user.phone || '',
    password: '',
    role,
    status: user.status || 'active',
    college_id: role === 'college_rep' ? (user.college?.id || user.college_id || '') : ''
  }
  showUserModal.value = true
  if (role === 'college_rep') loadCollegesForSelect()
}

const saveUser = async () => {
  userErrors.value = validateRepresentative(userForm.value, { editing: !!editingUser.value })
  if (Object.keys(userErrors.value).length) {
    alertMessage.value = firstError(userErrors.value)
    alertType.value = 'error'
    return
  }
  if (!userForm.value.email?.trim()) {
    alertMessage.value = 'Email обязателен — на него будут отправлены логин и пароль'; alertType.value = 'error'; return
  }
  saving.value = true
  try {
    const token = localStorage.getItem('authToken')
    const body = normalizeRepresentative(userForm.value)
    const wasEditing = !!editingUser.value
    const passwordWasChanged = !!body.password
    let response
    if (editingUser.value) {
      response = await axios.put(`${API_URL}/users/${editingUser.value.id}`, body, { headers: { Authorization: `Bearer ${token}` } })
    } else {
      response = await axios.post(`${API_URL}/users`, body, { headers: { Authorization: `Bearer ${token}` } })
    }
    closeUserModal()
    fetchUsers()

    // Показываем результат отправки email
    if (wasEditing && passwordWasChanged && response.data.password_email_sent) {
      alertMessage.value = `Пароль изменён. Email с новым паролем отправлен на ${body.email}`
      alertType.value = 'success'
    } else if (wasEditing && passwordWasChanged) {
      alertMessage.value = `Пароль изменён. ${response.data.password_email_error || 'Email с новым паролем не отправлен'}`
      alertType.value = 'info'
    } else if (response.data.email_sent) {
      alertMessage.value = `Пользователь создан. Email с логином и паролем отправлен на ${userForm.value.email}`
      alertType.value = 'success'
    } else if (response.data.credentials) {
      alertMessage.value = `Пользователь создан. SMTP не настроен. Логин: ${response.data.credentials.login}, Пароль: ${response.data.credentials.password}`
      alertType.value = 'info'
    } else {
      alertMessage.value = 'Пользователь сохранён'
      alertType.value = 'success'
    }
  } catch (e) {
    userErrors.value = e.response?.data?.errors || {}
    alertMessage.value = 'Ошибка: ' + (e.response?.data?.error || e.message)
    alertType.value = 'error'
  }
  finally { saving.value = false }
}

// Колледжи
const fetchColleges = async () => {
  collegesLoading.value = true; collegesError.value = null
  try {
    const token = localStorage.getItem('authToken')
    const response = await axios.get(`${API_URL}/colleges/admin/list`, { headers: { 'Authorization': `Bearer ${token}` } })
    if (response.data.success) { colleges.value = response.data.data; filterColleges() }
  } catch (err) {
    collegesError.value = err.response?.status === 401 ? 'Сессия истекла' : err.message
    if (err.response?.status === 401) { localStorage.removeItem('authToken'); localStorage.removeItem('user'); router.push('/login') }
  } finally { collegesLoading.value = false }
}

const filterColleges = () => {
  let filtered = [...colleges.value]
  if (collegeSearch.value.trim()) {
    const s = collegeSearch.value.trim().toLowerCase()
    filtered = filtered.filter(c => c.name.toLowerCase().includes(s) || c.short_name?.toLowerCase().includes(s) || c.city.toLowerCase().includes(s))
  }
  if (collegeFilter.value === 'active') filtered = filtered.filter(c => c.status === 'active')
  else if (collegeFilter.value === 'with_rep') filtered = filtered.filter(c => c.representatives.length > 0)
  else if (collegeFilter.value === 'without_rep') filtered = filtered.filter(c => c.representatives.length === 0)
  if (collegeSort.value === 'name_asc') filtered.sort((a, b) => a.name.localeCompare(b.name, 'ru'))
  else if (collegeSort.value === 'name_desc') filtered.sort((a, b) => b.name.localeCompare(a.name, 'ru'))
  else filtered.sort((a, b) => Number(a.id) - Number(b.id))
  filteredCollegesList.value = filtered
}

const openCollegeModal = () => {
  collegeErrors.value = {}
  collegeForm.value = { name: '', shortName: '', city: '', description: '', phone: '', email: '', website: '' }
  showCollegeModal.value = true
}

const closeCollegeModal = () => { showCollegeModal.value = false; collegeErrors.value = {} }

const validateCollegeForm = () => {
  const errors = {}
  const form = collegeForm.value
  if (!form.name.trim() || form.name.trim().length < 3) errors.name = 'Название колледжа обязательно, минимум 3 символа'
  if (form.shortName && form.shortName.trim().length > 50) errors.shortName = 'Краткое название: максимум 50 символов'
  if (form.phone && !isPhone(form.phone)) errors.phone = 'Телефон: +7 (999) 999-99-99'
  if (form.email && !isEmail(form.email)) errors.email = 'Укажите корректный email'
  if (form.website && !isUrl(normalizeUrl(form.website))) errors.website = 'Укажите корректный URL'
  return errors
}

const saveCollege = async () => {
  collegeErrors.value = validateCollegeForm()
  if (Object.keys(collegeErrors.value).length) {
    alertMessage.value = firstError(collegeErrors.value)
    alertType.value = 'error'
    return
  }

  saving.value = true
  try {
    const token = localStorage.getItem('authToken')
    const body = {
      name: collegeForm.value.name.trim(),
      shortName: collegeForm.value.shortName.trim(),
      city: collegeForm.value.city.trim(),
      description: collegeForm.value.description.trim(),
      phone: collegeForm.value.phone.trim(),
      email: normalizeEmailInput(collegeForm.value.email),
      website: normalizeUrl(collegeForm.value.website)
    }
    await axios.post(`${API_URL}/colleges`, body, { headers: { Authorization: `Bearer ${token}` } })
    closeCollegeModal()
    await fetchColleges()
    alertMessage.value = 'Колледж добавлен'
    alertType.value = 'success'
  } catch (e) {
    collegeErrors.value = e.response?.data?.errors || {}
    alertMessage.value = 'Ошибка: ' + (e.response?.data?.error || e.message)
    alertType.value = 'error'
  } finally { saving.value = false }
}

// Отрасли
const fetchSectors = async () => {
  sectorsLoading.value = true; sectorsError.value = null
  try {
    const token = localStorage.getItem('authToken')
    const response = await axios.get(`${API_URL}/sectors?include_inactive=1`, { headers: { Authorization: `Bearer ${token}` } })
    if (response.data.success) { sectors.value = response.data.data; filterSectors() }
  } catch (err) {
    sectorsError.value = err.response?.status === 401 ? 'Сессия истекла' : err.message
    if (err.response?.status === 401) { localStorage.removeItem('authToken'); localStorage.removeItem('user'); router.push('/login') }
  } finally { sectorsLoading.value = false }
}

const filterSectors = () => {
  let filtered = [...sectors.value]
  if (sectorSearch.value.trim()) {
    const s = sectorSearch.value.trim().toLowerCase()
    filtered = filtered.filter((sector) =>
      sector.name.toLowerCase().includes(s) ||
      sector.code.toLowerCase().includes(s) ||
      sector.description?.toLowerCase().includes(s)
    )
  }
  filteredSectorsList.value = filtered
}

const openSectorModal = () => {
  sectorErrors.value = {}
  sectorForm.value = { name: '', code: '', description: '', image_url: '' }
  showSectorModal.value = true
}

const closeSectorModal = () => { showSectorModal.value = false; sectorErrors.value = {} }

const getSectorCodePrefixes = () => sectorForm.value.code
  .split(',')
  .map((item) => item.trim())
  .filter(Boolean)

const validateSectorForm = () => {
  const errors = {}
  const form = sectorForm.value
  const prefixes = getSectorCodePrefixes()
  if (!form.name.trim() || form.name.trim().length < 3) errors.name = 'Название отрасли обязательно, минимум 3 символа'
  if (prefixes.length === 0 || prefixes.some((code) => !/^\d{2}$/.test(code))) errors.code = 'Коды специальностей: две цифры, можно несколько через запятую'
  if (form.image_url && !isUrl(normalizeUrl(form.image_url))) errors.image_url = 'Укажите корректный URL изображения'
  return errors
}

const triggerSectorImageUpload = () => {
  sectorImageInputRef.value?.click()
}

const handleSectorImageUpload = async (event) => {
  const file = event.target.files?.[0]
  if (!file) return
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
  if (!allowedTypes.includes(file.type)) {
    sectorErrors.value.image_url = 'Разрешены только изображения JPEG, PNG, GIF или WebP'
    event.target.value = ''
    return
  }
  if (file.size > 5 * 1024 * 1024) {
    sectorErrors.value.image_url = 'Файл должен быть не больше 5 МБ'
    event.target.value = ''
    return
  }

  sectorImageUploading.value = true
  try {
    const token = localStorage.getItem('authToken')
    const formData = new FormData()
    formData.append('image', file)
    const response = await axios.post(`${API_URL}/upload/sector-image`, formData, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'multipart/form-data'
      }
    })
    if (response.data.success) {
      sectorForm.value.image_url = response.data.data.imageUrl
      sectorErrors.value.image_url = ''
    }
  } catch (e) {
    sectorErrors.value.image_url = e.response?.data?.error || e.message
  } finally {
    sectorImageUploading.value = false
    event.target.value = ''
  }
}

const saveSector = async () => {
  sectorErrors.value = validateSectorForm()
  if (Object.keys(sectorErrors.value).length) {
    alertMessage.value = firstError(sectorErrors.value)
    alertType.value = 'error'
    return
  }

  saving.value = true
  try {
    const token = localStorage.getItem('authToken')
    const body = {
      name: sectorForm.value.name.trim(),
      code: sectorForm.value.code.trim(),
      specialtyCodes: getSectorCodePrefixes(),
      description: sectorForm.value.description.trim(),
      image_url: sectorForm.value.image_url
    }
    await axios.post(`${API_URL}/sectors`, body, { headers: { Authorization: `Bearer ${token}` } })
    closeSectorModal()
    await fetchSectors()
    alertMessage.value = 'Отрасль добавлена'
    alertType.value = 'success'
  } catch (e) {
    sectorErrors.value = e.response?.data?.errors || {}
    alertMessage.value = 'Ошибка: ' + (e.response?.data?.error || e.message)
    alertType.value = 'error'
  } finally { saving.value = false }
}

const logout = () => {
  if (confirm('Выйти из системы?')) {
    localStorage.removeItem('authToken'); localStorage.removeItem('user')
    delete axios.defaults.headers.common['Authorization']
    router.push('/login')
  }
}
</script>

<style scoped>
.admin-panel { min-height: 100vh; background: #f5f7fa; }

/* Хедер панели */
.panel-header { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: white; padding: 20px 0; margin-bottom: 0; }
.panel-header .header-content { display: flex; justify-content: space-between; align-items: center; }
.panel-header .logo { display: flex; align-items: center; gap: 15px; }
.panel-header .logo-icon { width: 50px; height: 50px; background: rgba(255,255,255,0.2); border-radius: 10px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 1.3rem; }
.panel-header h1 { margin: 0; font-size: 1.4rem; }
.panel-header p { margin: 3px 0 0; opacity: 0.8; font-size: 0.9rem; }
.panel-header .logout-btn { background: rgba(255,255,255,0.2); color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; font-weight: 600; display: flex; align-items: center; gap: 8px; transition: all 0.3s; }
.panel-header .logout-btn:hover { background: rgba(255,255,255,0.3); }

/* Вкладки */
.tabs { display: flex; gap: 8px; padding: 20px 0 0; }
.tab-btn { padding: 12px 24px; background: white; border: none; border-radius: 10px 10px 0 0; cursor: pointer; font-weight: 500; transition: all 0.3s; display: flex; align-items: center; gap: 8px; color: #64748b; border-bottom: 3px solid transparent; }
.tab-btn:hover { background: #e2e8f0; }
.tab-btn.active { background: white; color: #1e3c72; border-bottom-color: #1e3c72; box-shadow: 0 -2px 10px rgba(0,0,0,0.05); }

/* Контент вкладок */
.tab-content { display: none; padding: 30px 0; }
.tab-content.active { display: block; }

/* Уведомления */
.alert { padding: 14px 18px; border-radius: 10px; margin-bottom: 20px; display: flex; align-items: center; gap: 10px; }
.alert-success { background: #d1fae5; color: #059669; }
.alert-error { background: #fee2e2; color: #dc2626; }
.alert-info { background: #dbeafe; color: #2563eb; }

/* Поиск и фильтры */
.specialities-header { display: flex; gap: 15px; margin-bottom: 15px; align-items: center; }
.search-box { flex: 1; max-width: 400px; position: relative; }
.search-box i { position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: #94a3b8; }
.search-box input { width: 100%; padding: 12px 15px 12px 45px; border: 1px solid #e1e8ed; border-radius: 8px; }
.btn-add { padding: 12px 24px; background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 8px; transition: all 0.3s; }
.btn-add:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(102,126,234,0.4); }
.filters-bar { display: flex; gap: 15px; margin-bottom: 20px; }
.filter-select { padding: 10px 15px; border: 1px solid #e1e8ed; border-radius: 8px; background: white; }

/* Таблица */
.table-container { background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
.table-scroll { width: 100%; overflow-x: auto; }
.users-table-container .table-scroll { max-height: 620px; overflow-y: auto; }
.data-table { width: 100%; border-collapse: collapse; }
.users-table-container .data-table { min-width: 920px; }
.users-table-container .data-table thead { position: sticky; top: 0; z-index: 1; }
.data-table th { background: #f8fafc; padding: 15px; text-align: left; font-weight: 600; color: #475569; border-bottom: 2px solid #e1e8ed; }
.data-table td { padding: 15px; border-bottom: 1px solid #f1f5f9; }
.data-table tbody tr:hover { background: #f8fafc; }

.user-info { display: flex; align-items: center; gap: 12px; }
.user-avatar { width: 40px; height: 40px; background: linear-gradient(135deg, #667eea, #764ba2); border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: 600; }

.role-badge, .status-badge { padding: 5px 12px; border-radius: 20px; font-size: 0.85rem; font-weight: 500; display: inline-block; }
.role-badge.college_rep { background: #d1fae5; color: #059669; }
.role-badge.admin { background: #fee2e2; color: #dc2626; }
.status-badge.status-active { background: #d1fae5; color: #059669; }
.status-badge.status-inactive { background: #fef3c7; color: #d97706; }

.prof-badge { background: #d1fae5; color: #059669; padding: 4px 10px; border-radius: 12px; font-size: 0.8rem; font-weight: 500; display: inline-flex; align-items: center; gap: 5px; }
.rep-list { display: flex; flex-direction: column; gap: 4px; }
.rep-item { display: flex; align-items: center; gap: 6px; font-size: 0.85rem; }
.rep-status { font-size: 0.7rem; padding: 2px 6px; border-radius: 8px; }
.rep-status.active { background: #d1fae5; color: #059669; }
.rep-status.inactive { background: #fef3c7; color: #d97706; }
.text-muted { color: #94a3b8; font-size: 0.85rem; }

.college-info { display: flex; flex-direction: column; gap: 4px; }
.college-info strong { color: #1e293b; }
.short-name { color: #64748b; font-size: 0.8rem; background: #f1f5f9; padding: 2px 8px; border-radius: 4px; display: inline-block; width: fit-content; }
.short-description { color: #64748b; font-size: 0.88rem; max-width: 520px; }

.action-buttons { display: flex; gap: 8px; }
.btn-icon { width: 36px; height: 36px; border: none; border-radius: 6px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.3s; }
.btn-edit { background: #dbeafe; color: #2563eb; }
.btn-edit:hover { background: #2563eb; color: white; }
.btn-delete { background: #fef3c7; color: #d97706; }
.btn-delete:hover { background: #d97706; color: white; }

.pagination { display: flex; justify-content: center; gap: 8px; padding: 20px; border-top: 1px solid #f1f5f9; }
.page-btn { width: 40px; height: 40px; border: 1px solid #e1e8ed; background: white; border-radius: 8px; cursor: pointer; }
.page-btn:hover:not(:disabled) { background: #f1f5f9; }
.page-btn.active { background: linear-gradient(135deg, #667eea, #764ba2); color: white; border-color: transparent; }
.page-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.page-btn.dots { border-color: transparent; background: transparent; }

.loading-state, .error-state { text-align: center; padding: 60px 20px; color: #64748b; }
.loading-state i { font-size: 2rem; color: #667eea; }
.error-state { color: #dc2626; }
.btn-retry { margin-top: 15px; padding: 10px 20px; background: #667eea; color: white; border: none; border-radius: 8px; cursor: pointer; }
.empty-state { text-align: center; padding: 60px 20px; color: #64748b; }
.empty-state i { font-size: 3rem; color: #cbd5e1; margin-bottom: 15px; }

/* Модальное окно */
.modal-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 2000; }
.modal { background: white; border-radius: 16px; width: 90%; max-width: 600px; padding: 30px; position: relative; max-height: 90vh; overflow-y: auto; }
.close-modal { position: absolute; top: 20px; right: 20px; background: none; border: none; font-size: 1.5rem; cursor: pointer; color: #64748b; }
.modal h2 { margin: 0 0 25px 0; color: #1e293b; }
.modal-form { display: flex; flex-direction: column; gap: 20px; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
.form-group label { display: block; margin-bottom: 8px; font-weight: 500; color: #475569; }
.form-control { width: 100%; padding: 12px 15px; border: 1px solid #e1e8ed; border-radius: 8px; font-size: 1rem; }
.form-control.invalid { border-color: #dc2626; box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.08); }
.password-control { display: flex; flex-direction: column; gap: 8px; align-items: stretch; }
.btn-generate-password { width: fit-content; min-height: 38px; padding: 0 14px; border: 1px solid #c7d2fe; border-radius: 8px; background: #eef2ff; color: #4338ca; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; gap: 8px; white-space: nowrap; transition: all 0.2s; }
.btn-generate-password:hover { background: #e0e7ff; border-color: #818cf8; }
.field-error { color: #dc2626; font-size: 0.8rem; margin-top: 4px; display: block; }
.form-actions { display: flex; gap: 15px; margin-top: 20px; }
.btn { padding: 12px 24px; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 8px; transition: all 0.3s; }
.btn-primary { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
.btn-primary:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(102,126,234,0.4); }
.btn-primary:disabled { opacity: 0.7; cursor: not-allowed; }
.btn-secondary { background: #f1f5f9; color: #475569; }
.btn-secondary:hover { background: #e2e8f0; }
.required { color: #dc2626; }
.form-hint { color: #94a3b8; font-size: 0.8rem; margin-top: 4px; display: block; }
.text-small { color: #94a3b8; font-size: 0.85rem; }
.image-upload { border: 2px dashed #cbd5e1; border-radius: 8px; padding: 24px; text-align: center; cursor: pointer; transition: all 0.2s; background: #f8fafc; }
.image-upload:hover { border-color: #2563eb; background: #eff6ff; }
.image-upload i { color: #64748b; display: block; font-size: 2.2rem; margin-bottom: 10px; }
.image-upload p { margin: 4px 0; }
.image-preview { margin-top: 14px; position: relative; width: 220px; max-width: 100%; }
.image-preview img { width: 100%; height: 140px; object-fit: cover; border-radius: 8px; box-shadow: 0 8px 20px rgba(15, 23, 42, 0.12); display: block; }
.remove-image-btn { position: absolute; top: 8px; right: 8px; width: 30px; height: 30px; border: none; border-radius: 50%; background: rgba(15, 23, 42, 0.78); color: white; cursor: pointer; display: flex; align-items: center; justify-content: center; }
.remove-image-btn:hover { background: #dc2626; }

@media (max-width: 768px) {
  .admin-panel .container {
    width: 100%;
    padding: 0 12px;
  }

  .tabs {
    overflow-x: auto;
    padding: 12px 0 0;
    gap: 6px;
  }

  .tab-btn {
    flex: 0 0 auto;
    min-height: 44px;
    padding: 10px 14px;
    border-radius: 8px 8px 0 0;
    white-space: nowrap;
  }

  .tab-content {
    padding: 18px 0;
  }

  .specialities-header,
  .filters-bar,
  .form-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .search-box,
  .btn-add,
  .filter-select,
  .btn,
  .btn-retry {
    width: 100%;
    max-width: none;
  }

  .btn-add,
  .btn,
  .btn-retry {
    justify-content: center;
    min-height: 44px;
  }

  .table-container {
    border-radius: 8px;
  }

  .users-table-container .table-scroll,
  .table-scroll {
    max-height: 70vh;
    overflow: auto;
    -webkit-overflow-scrolling: touch;
  }

  .data-table {
    min-width: 820px;
    font-size: 0.88rem;
  }

  .data-table th,
  .data-table td {
    padding: 10px;
  }

  .pagination {
    flex-wrap: wrap;
    padding: 14px;
  }

  .page-btn {
    width: 38px;
    height: 38px;
  }

  .modal-overlay {
    align-items: flex-start;
    padding: 12px;
    overflow-y: auto;
  }

  .modal {
    width: 100%;
    max-height: none;
    padding: 22px 16px;
    border-radius: 10px;
  }

  .modal h2 {
    font-size: 1.35rem;
    padding-right: 34px;
  }

  .form-row {
    grid-template-columns: 1fr;
    gap: 14px;
  }

  .btn-generate-password {
    width: 100%;
    min-height: 44px;
  }
}
</style>
