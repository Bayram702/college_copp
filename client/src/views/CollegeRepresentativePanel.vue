<template>
  <div class="college-rep-panel">
    <div class="breadcrumbs">
      <div class="container">
        <router-link to="/">Главная</router-link> >
        <span>Панель представителя колледжа</span>
      </div>
    </div>
    <!-- Основной контент -->
    <div class="container" style="padding-top: 10px;">
      <!-- Состояние загрузки -->
      <div v-if="loading" class="loading-state">
        <i class="fas fa-spinner fa-spin"></i> Загрузка данных колледжа...
      </div>

      <!-- Вкладки -->
      <div class="tabs">
        <button 
          class="tab-btn" 
          :class="{ active: activeTab === 'college' }"
          @click="activeTab = 'college'"
        >
          <i class="fas fa-university"></i> Информация о колледже
        </button>
        <button 
          class="tab-btn" 
          :class="{ active: activeTab === 'specialities' }"
          @click="activeTab = 'specialities'"
        >
          <i class="fas fa-graduation-cap"></i> Управление специальностями
        </button>
      </div>
      
      <!-- Уведомления -->
      <div v-if="alertMessage" :class="['alert', `alert-${alertType}`]">
        <i :class="alertType === 'success' ? 'fas fa-check-circle' : 'fas fa-info-circle'"></i>
        <div>{{ alertMessage }}</div>
      </div>
      
      <!-- Контент вкладки 1: Информация о колледже -->
      <div v-if="activeTab === 'college'" class="tab-content active">
        <div class="alert alert-info">
          <i class="fas fa-info-circle"></i>
          <div>
            <strong>Информация:</strong> Все изменения будут отображены на публичной странице вашего колледжа.
          </div>
        </div>
        
        <!-- Секция 1: Основная информация -->
        <div class="section">
          <h2 class="section-title"><i class="fas fa-info-circle"></i> Основная информация</h2>
          
          <div class="settings-grid">
            <div class="form-group">
              <label for="college-name">Название колледжа <span class="required">*</span></label>
              <input 
                v-model="collegeData.name" 
                type="text" 
                id="college-name" 
                class="form-control"
                :class="{ invalid: collegeErrors.name }"
                maxlength="255"
                @input="collegeData.name = normalizeTextInput(collegeData.name, 255)"
                required
              >
              <small v-if="collegeErrors.name" class="field-error">{{ collegeErrors.name }}</small>
            </div>
            
            <div class="form-group">
              <label for="college-status">Статус колледжа</label>
              <select v-model="collegeData.status" id="college-status" class="form-control">
                <option value="active">Активен</option>
                <option value="inactive">Неактивен</option>
              </select>
            </div>
          </div>
          
          <div class="form-group">
            <label for="college-description">Краткое описание <span class="required">*</span></label>
            <textarea 
              v-model="collegeData.description" 
              id="college-description" 
              class="form-control" 
              :class="{ invalid: collegeErrors.description }"
              rows="4"
              maxlength="3000"
              @input="collegeData.description = normalizeMultilineInput(collegeData.description, 3000)"
              required
            ></textarea>
            <small v-if="collegeErrors.description" class="field-error">{{ collegeErrors.description }}</small>
          </div>
        </div>
        
        <!-- Секция 2: Статистика приема -->
        <div class="section">
          <h2 class="section-title"><i class="fas fa-chart-bar"></i> Статистика приема 2025</h2>
          <p class="auto-calculated-note">
            <i class="fas fa-calculator"></i>
            Количество мест рассчитываются автоматически по добавленным специальностям.
          </p>
          
          <div class="stats-grid">
            <div class="form-group">
              <label for="budget-places">Бюджетных мест</label>
              <input 
                v-model.number="collegeData.budget_places" 
                type="number" 
                id="budget-places" 
                class="form-control" 
                min="0"
                max="10000"
                readonly
              >
              <small v-if="collegeErrors.budget_places" class="field-error">{{ collegeErrors.budget_places }}</small>
            </div>
            
            <div class="form-group">
              <label for="commercial-places">Коммерческих мест</label>
              <input 
                v-model.number="collegeData.commercial_places" 
                type="number" 
                id="commercial-places" 
                class="form-control" 
                min="0"
                max="10000"
                readonly
              >
              <small v-if="collegeErrors.commercial_places" class="field-error">{{ collegeErrors.commercial_places }}</small>
            </div>
            
            <div class="form-group">
              <label for="avg-score">Средний балл аттестата</label>
              <input 
                v-model.number="collegeData.avg_score" 
                type="number" 
                step="0.1" 
                id="avg-score" 
                class="form-control" 
                min="0" 
                max="5"
                @input="collegeData.avg_score = maskScore(collegeData.avg_score)"
              >
              <small v-if="collegeErrors.avg_score" class="field-error">{{ collegeErrors.avg_score }}</small>
            </div>
            
            <div class="form-group">
              <label for="min-score">Минимальный балл аттестата</label>
              <input 
                v-model.number="collegeData.min_score" 
                type="number" 
                step="0.1" 
                id="min-score" 
                class="form-control" 
                min="0" 
                max="5"
                @input="collegeData.min_score = maskScore(collegeData.min_score)"
              >
              <small v-if="collegeErrors.min_score" class="field-error">{{ collegeErrors.min_score }}</small>
            </div>
          </div>
        </div>
        
        <!-- Секция 3: Контактная информация -->
        <div class="section">
          <h2 class="section-title"><i class="fas fa-address-book"></i> Контактная информация приемной комиссии</h2>
          
          <div class="settings-grid">
            <div class="form-group">
              <label for="college-phone">Телефон приемной комиссии <span class="required">*</span></label>
              <input 
                v-model="collegeData.phone" 
                type="text" 
                id="college-phone" 
                class="form-control"
                :class="{ invalid: collegeErrors.phone }"
                placeholder="+7 (999) 999-99-99"
                @input="collegeData.phone = maskRussianPhone(collegeData.phone)"
                required
              >
              <small v-if="collegeErrors.phone" class="field-error">{{ collegeErrors.phone }}</small>
            </div>
            
            <div class="form-group">
              <label for="college-email">Электронная почта приемной комиссии <span class="required">*</span></label>
              <input 
                v-model="collegeData.email" 
                type="email" 
                id="college-email" 
                class="form-control"
                :class="{ invalid: collegeErrors.email }"
                maxlength="255"
                @input="collegeData.email = normalizeEmailInput(collegeData.email)"
                required
              >
              <small v-if="collegeErrors.email" class="field-error">{{ collegeErrors.email }}</small>
            </div>
          </div>
          
          <div class="settings-grid">
            <div class="form-group">
              <label for="college-website">Официальный сайт</label>
              <input 
                v-model="collegeData.website" 
                type="url" 
                id="college-website" 
                class="form-control"
                :class="{ invalid: collegeErrors.website }"
                maxlength="255"
                @input="collegeData.website = normalizeUrlInput(collegeData.website)"
              >
              <small v-if="collegeErrors.website" class="field-error">{{ collegeErrors.website }}</small>
            </div>

            <div class="form-group">
              <label for="college-admission-link">Сайт приемной комиссии</label>
              <input
                v-model="collegeData.admission_link"
                type="url"
                id="college-admission-link"
                class="form-control"
                :class="{ invalid: collegeErrors.admission_link }"
                maxlength="255"
                placeholder="https://example.ru/priem"
                @input="collegeData.admission_link = normalizeUrlInput(collegeData.admission_link)"
              >
              <small v-if="collegeErrors.admission_link" class="field-error">{{ collegeErrors.admission_link }}</small>
            </div>
          </div>
          
          <div class="form-group">
            <label>Социальные сети</label>
            <div class="settings-grid">
              <div class="form-group">
                <label for="college-vk">ВКонтакте</label>
                <input 
                  v-model="collegeData.social_vk" 
                  type="url" 
                  id="college-vk" 
                  class="form-control"
                  :class="{ invalid: collegeErrors.social_vk }"
                  maxlength="255"
                  @input="collegeData.social_vk = normalizeUrlInput(collegeData.social_vk)"
                >
                <small v-if="collegeErrors.social_vk" class="field-error">{{ collegeErrors.social_vk }}</small>
              </div>
              <div class="form-group">
                <label for="college-max">MAX</label>
                <input 
                  v-model="collegeData.social_max" 
                  type="url" 
                  id="college-max" 
                  class="form-control"
                  :class="{ invalid: collegeErrors.social_max }"
                  maxlength="255"
                  @input="collegeData.social_max = normalizeUrlInput(collegeData.social_max)"
                >
                <small v-if="collegeErrors.social_max" class="field-error">{{ collegeErrors.social_max }}</small>
              </div>
            </div>
            <div class="form-group">
              <label for="college-social-other">Другие источники (каждая ссылка с новой строки)</label>
              <textarea
                v-model="socialOtherText"
                id="college-social-other"
                class="form-control"
                rows="4"
                maxlength="5000"
              ></textarea>
            </div>
          </div>
        </div>

        <!-- Секция 4: Адреса расположения -->
        <div class="section">
          <h2 class="section-title"><i class="fas fa-map-marker-alt"></i> Адреса расположения</h2>

          <div v-if="addresses.length > 0" class="addresses-table-wrapper">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Тип</th>
                  <th>Название</th>
                  <th>Адрес</th>
                  <th>Телефон</th>
                  <th>Координаты</th>
                  <th>Главный</th>
                  <th>Действия</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="addr in addresses" :key="addr.id">
                  <td>
                    <span class="address-type-badge" :class="addr.address_type || 'educational'">
                      {{ getAddressTypeName(addr.address_type) }}
                    </span>
                  </td>
                  <td>{{ addr.name }}</td>
                  <td>{{ addr.address }}</td>
                  <td>{{ addr.phone || '—' }}</td>
                  <td>{{ addr.coordinates || '—' }}</td>
                  <td>
                    <span v-if="addr.is_main" class="main-badge">✓ Главный</span>
                    <span v-else class="text-muted">—</span>
                  </td>
                  <td>
                    <div class="action-buttons">
                      <button class="btn-icon btn-edit" @click="editAddress(addr)" title="Редактировать">
                        <i class="fas fa-edit"></i>
                      </button>
                      <button class="btn-icon btn-delete" @click="deleteAddress(addr.id)" title="Удалить">
                        <i class="fas fa-trash"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="empty-addresses">
            <i class="fas fa-map-marker-alt"></i>
            <p>Адреса ещё не добавлены</p>
          </div>

          <button class="add-address-btn" @click="openAddressModal()">
            <i class="fas fa-plus"></i> Добавить адрес
          </button>
        </div>
        
        <!-- Секция 5: Изображения -->
        <div class="section">
          <h2 class="section-title"><i class="fas fa-images"></i> Изображения</h2>

          <div class="form-group">
            <label>Логотип колледжа</label>
            <input
              ref="logoInputRef"
              type="file"
              accept="image/jpeg,image/jpg,image/png,image/gif,image/webp"
              @change="(e) => handleImageUpload(e, 'logo')"
              style="display: none"
            >
            <div class="image-upload" @click="triggerImageUpload('logo')">
              <i class="fas fa-cloud-upload-alt"></i>
              <p>Нажмите для загрузки логотипа</p>
              <p class="text-small">Рекомендуемый размер: 300x300px, PNG</p>
              <p v-if="imageUploading" class="text-small">
                <i class="fas fa-spinner fa-spin"></i> Загрузка...
              </p>
            </div>
            <div v-if="collegeData.logo_image_url" class="image-preview">
              <img :src="resolveImageUrl(collegeData.logo_image_url)" alt="Логотип">
              <button class="remove-image-btn" @click="collegeData.logo_image_url = ''" title="Удалить изображение">
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>

        </div>
        
        <!-- Секция 6: Профессионалитет -->
        <div class="section">
          <h2 class="section-title"><i class="fas fa-award"></i> Участие в Профессионалитете</h2>
          
          <div class="form-group">
            <label>Участвует ли колледж в программе Профессионалитет?</label>
            <div class="radio-group">
              <div class="radio-item">
                <input
                  type="radio"
                  id="prof-yes"
                  :value="true"
                  v-model="collegeData.is_professionalitet"
                >
                <label for="prof-yes">Да, участвует</label>
              </div>
              <div class="radio-item">
                <input
                  type="radio"
                  id="prof-no"
                  :value="false"
                  v-model="collegeData.is_professionalitet"
                >
                <label for="prof-no">Не участвует</label>
              </div>
            </div>
          </div>
          
          <div v-if="collegeData.is_professionalitet" class="ovz-section">
            <div class="form-group">
              <label for="prof-cluster">Кластер Профессионалитета</label>
              <input 
                v-model="collegeData.professionalitet_cluster" 
                type="text" 
                id="prof-cluster" 
                class="form-control"
                maxlength="255"
                @input="collegeData.professionalitet_cluster = normalizeTextInput(collegeData.professionalitet_cluster, 255)"
              >
            </div>
          </div>
        </div>
        
        <!-- Секция 7: Доступная среда для ОВЗ -->
        <div class="section">
          <h2 class="section-title"><i class="fas fa-universal-access"></i> Доступная среда для ОВЗ</h2>
          
          <div class="ovz-section">
            <div class="form-group">
              <label for="ovz-programs">Программы для людей с ОВЗ (каждый пункт с новой строки)</label>
              <textarea 
                v-model="ovzText" 
                id="ovz-programs" 
                class="form-control" 
                rows="5"
              ></textarea>
            </div>
          </div>
        </div>
        
        <!-- Секция 8: Дополнительная информация -->
        <div class="section">
          <h2 class="section-title"><i class="fas fa-info-circle"></i> Дополнительная информация</h2>
          
          <div class="form-group">
            <label for="college-opportunities">Возможности в колледже (каждый пункт с новой строки)</label>
            <textarea 
              v-model="opportunitiesText" 
              id="college-opportunities" 
              class="form-control" 
              rows="5"
            ></textarea>
          </div>
          
          <div class="form-group">
            <label for="college-employers">Работодатели-партнеры (каждый с новой строки)</label>
            <textarea 
              v-model="employersText" 
              id="college-employers" 
              class="form-control" 
              rows="5"
            ></textarea>
          </div>
          
          <div class="form-group">
            <label for="college-master-classes">Учебные мастерские и лаборатории (каждая с новой строки)</label>
            <textarea 
              v-model="masterClassesText" 
              id="college-master-classes" 
              class="form-control" 
              rows="5"
            ></textarea>
          </div>
          
          <div class="form-group">
            <label for="college-professions">Кем можно работать после обучения (каждая профессия с новой строки)</label>
            <textarea 
              v-model="professionsText" 
              id="college-professions" 
              class="form-control" 
              rows="5"
            ></textarea>
          </div>
        </div>
        
        <!-- Кнопки сохранения -->
        <div class="form-actions">
          <button class="btn btn-primary" @click="saveCollegeData" :disabled="saving">
            <i :class="saving ? 'fas fa-spinner fa-spin' : 'fas fa-save'"></i> 
            {{ saving ? 'Сохранение...' : 'Сохранить изменения' }}
          </button>
        </div>
      </div>
      
      <!-- Контент вкладки 2: Управление специальностями -->
      <div v-if="activeTab === 'specialities'" class="tab-content active">
        <div class="alert alert-info">
          <i class="fas fa-info-circle"></i>
          <div>
            <strong>Информация:</strong> Здесь вы можете управлять специальностями вашего колледжа. Добавляйте новые специальности или редактируйте существующие.
          </div>
        </div>
        
        <div class="specialities-header">
          <div>
            <h2 style="margin:0;color:#1e293b;">Специальности колледжа</h2>
          </div>
          <button class="btn-add" @click="openSpecialityModal()">
            <i class="fas fa-plus"></i> Добавить специальность
          </button>
        </div>
        
        <div class="table-container">
          <table class="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Название</th>
                <th>Код</th>
                <th>Экзамены</th>
                <th>Бюджет/Коммерция</th>
                <th>Статус</th>
                <th>Действия</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="speciality in filteredSpecialities" :key="speciality.id">
                <td>{{ speciality.id }}</td>
                <td>{{ speciality.name }}</td>
                <td>{{ speciality.code }}</td>
                <td>{{ speciality.exams || '—' }}</td>
                <td>{{ speciality.budget_places }}/{{ speciality.commercial_places }}</td>
                <td>
                  <span class="status-badge" :class="getStatusClass(speciality.status)">
                    {{ getStatusName(speciality.status) }}
                  </span>
                </td>
                <td>
                  <div class="action-buttons">
                    <button class="btn-action btn-edit" @click="editSpeciality(speciality)" title="Редактировать">
                      <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn-action btn-delete" @click="deleteSpeciality(speciality.id)" title="Удалить">
                      <i class="fas fa-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Модальное окно: Специальность -->
    <div class="modal-overlay" :class="{ active: showSpecialityModal }" @click.self="closeSpecialityModal" v-show="showSpecialityModal">
      <div class="modal">
        <button class="close-modal" @click="closeSpecialityModal">&times;</button>
        <h2>{{ editingSpeciality ? 'Редактировать специальность' : 'Добавить специальность' }}</h2>
        
        <form @submit.prevent="saveSpeciality">
          <input type="hidden" v-model="specialityForm.id">
          
          <div class="settings-grid">
            <div class="form-group">
              <label>Название специальности <span class="required">*</span></label>
              <select v-model="specialityForm.sector_id" class="form-control" :class="{ invalid: specialityErrors.sector_id }" :disabled="!!editingSpeciality" @change="loadDirectorySpecialties(specialityForm.sector_id); specialityForm.specialty_id = ''; specialityForm.name = ''; specialityForm.code = ''" required>
                <option value="">Выберите отрасль</option>
                <option v-for="sector in directorySectors" :key="sector.id" :value="String(sector.id)">
                  {{ sector.code }} — {{ sector.name }}
                </option>
              </select>
              <small v-if="specialityErrors.sector_id" class="field-error">{{ specialityErrors.sector_id }}</small>
            </div>
            
            <div class="form-group">
              <label>Код специальности <span class="required">*</span></label>
              <select v-model="specialityForm.specialty_id" class="form-control" :class="{ invalid: specialityErrors.specialty_id }" :disabled="!specialityForm.sector_id || !!editingSpeciality" @change="syncDirectorySpecialtyDetails" required>
                <option value="">Выберите специальность</option>
                <option v-for="item in directorySpecialties" :key="item.id" :value="String(item.id)">
                  {{ item.code }} — {{ item.name }}
                </option>
              </select>
              <small v-if="specialityErrors.specialty_id" class="field-error">{{ specialityErrors.specialty_id }}</small>
            </div>
          </div>
          
          <div class="settings-grid">
            <div class="form-group">
              <label>Срок обучения <span class="required">*</span></label>
              <input v-model="specialityForm.duration" type="text" class="form-control" :class="{ invalid: specialityErrors.duration }" maxlength="100" @input="specialityForm.duration = normalizeTextInput(specialityForm.duration, 100)" required>
              <small v-if="specialityErrors.duration" class="field-error">{{ specialityErrors.duration }}</small>
            </div>
            
            <div class="form-group">
              <label>База приема <span class="required">*</span></label>
              <select v-model="specialityForm.base_education" class="form-control" :class="{ invalid: specialityErrors.base_education }" required>
                <option value="9">9 классов</option>
                <option value="11">11 классов</option>
              </select>
              <small v-if="specialityErrors.base_education" class="field-error">{{ specialityErrors.base_education }}</small>
            </div>
          </div>
          
          <div class="settings-grid">
            <div class="form-group">
              <label>Стоимость обучения (руб/год)</label>
              <input v-model.number="specialityForm.price_per_year" type="number" class="form-control" :class="{ invalid: specialityErrors.price_per_year }" min="0" max="10000000" @input="specialityForm.price_per_year = maskInteger(specialityForm.price_per_year, 10000000)">
              <small v-if="specialityErrors.price_per_year" class="field-error">{{ specialityErrors.price_per_year }}</small>
            </div>
          </div>
          
          <div class="settings-grid">
            <div class="form-group">
              <label>Количество бюджетных мест</label>
              <input v-model.number="specialityForm.budget_places" type="number" class="form-control" :class="{ invalid: specialityErrors.budget_places }" min="0" max="10000" @input="specialityForm.budget_places = maskInteger(specialityForm.budget_places, 10000)">
              <small v-if="specialityErrors.budget_places" class="field-error">{{ specialityErrors.budget_places }}</small>
            </div>
            <div class="form-group">
              <label>Количество коммерческих мест</label>
              <input v-model.number="specialityForm.commercial_places" type="number" class="form-control" :class="{ invalid: specialityErrors.commercial_places }" min="0" max="10000" @input="specialityForm.commercial_places = maskInteger(specialityForm.commercial_places, 10000)">
              <small v-if="specialityErrors.commercial_places" class="field-error">{{ specialityErrors.commercial_places }}</small>
            </div>
          </div>
          
          <div class="form-group">
            <label>Вступительные испытания (через запятую)</label>
            <input v-model="specialityForm.exams" type="text" class="form-control" placeholder="Например: Математика, русский язык" maxlength="500" @input="specialityForm.exams = normalizeTextInput(specialityForm.exams, 500)">
          </div>
          
          <div class="form-group">
            <label>Средний балл аттестата (прошлый год)</label>
            <input v-model.number="specialityForm.avg_score" type="number" step="0.1" class="form-control" :class="{ invalid: specialityErrors.avg_score }" min="0" max="5" @input="specialityForm.avg_score = maskScore(specialityForm.avg_score)">
            <small v-if="specialityErrors.avg_score" class="field-error">{{ specialityErrors.avg_score }}</small>
          </div>
          
          <div class="form-group">
            <label>Описание специальности</label>
            <textarea v-model="specialityForm.description" class="form-control" :class="{ invalid: specialityErrors.description }" rows="4" maxlength="3000" @input="specialityForm.description = normalizeMultilineInput(specialityForm.description, 3000)"></textarea>
            <small v-if="specialityErrors.description" class="field-error">{{ specialityErrors.description }}</small>
          </div>

          <div class="form-group">
            <label>Адрес преподавания <span class="required">*</span></label>
            <select v-model="specialityForm.teaching_address" class="form-control" :class="{ invalid: specialityErrors.teaching_address }" required>
              <option value="" disabled>{{ addresses.length ? 'Выберите адрес' : 'Сначала добавьте адрес колледжа' }}</option>
              <option v-for="item in teachingAddressOptions" :key="item.value" :value="item.value">
                {{ item.label }}
              </option>
            </select>
            <small v-if="specialityErrors.teaching_address" class="field-error">{{ specialityErrors.teaching_address }}</small>
          </div>

          <div class="settings-grid">
            <div class="form-group">
              <label>Способ подачи документов</label>
              <select v-model="specialityForm.admission_method" class="form-control" :class="{ invalid: specialityErrors.admission_method }">
                <option value="">Использовать настройки колледжа</option>
                <option value="offline">Очно</option>
                <option value="email">Онлайн через электронную почту</option>
                <option value="platform">Своя платформа</option>
                <option value="gosuslugi">ГосУслуги</option>
                <option value="edu_rb">https://college.edu-rb.ru/</option>
              </select>
              <small v-if="specialityErrors.admission_method" class="field-error">{{ specialityErrors.admission_method }}</small>
            </div>
            <div class="form-group">
              <label>Ссылка или адрес подачи</label>
              <input v-model="specialityForm.admission_link" type="text" class="form-control" :class="{ invalid: specialityErrors.admission_link }" maxlength="255" @input="specialityForm.admission_link = normalizeUrlInput(specialityForm.admission_link)">
              <small v-if="specialityErrors.admission_link" class="field-error">{{ specialityErrors.admission_link }}</small>
            </div>
          </div>

          <div class="form-group">
            <label>Краткая инструкция по подаче</label>
            <textarea v-model="specialityForm.admission_instructions" class="form-control" :class="{ invalid: specialityErrors.admission_instructions }" rows="3" maxlength="1000" @input="specialityForm.admission_instructions = normalizeMultilineInput(specialityForm.admission_instructions, 1000)"></textarea>
            <small v-if="specialityErrors.admission_instructions" class="field-error">{{ specialityErrors.admission_instructions }}</small>
          </div>
          
          <div class="form-group">
            <label>Статус специальности</label>
            <select v-model="specialityForm.status" class="form-control">
              <option value="active">Активна</option>
              <option value="inactive">Неактивна</option>
              <option value="draft">Черновик</option>
            </select>
          </div>
          
          <div class="form-actions">
            <button type="submit" class="btn btn-primary" :disabled="saving">
              <i :class="saving ? 'fas fa-spinner fa-spin' : 'fas fa-save'"></i> 
              {{ saving ? 'Сохранение...' : 'Сохранить специальность' }}
            </button>
            <button type="button" class="btn btn-secondary" @click="closeSpecialityModal">
              Отмена
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Модальное окно: Адрес -->
    <div class="modal-overlay" :class="{ active: showAddressModal }" @click.self="closeAddressModal" v-show="showAddressModal">
      <div class="modal modal-lg">
        <button class="close-modal" @click="closeAddressModal">&times;</button>
        <h2>{{ editingAddress ? 'Редактировать адрес' : 'Добавить адрес' }}</h2>

        <form @submit.prevent="saveAddress">
          <input type="hidden" v-model="addressForm.id">

          <div class="form-row">
            <div class="form-group">
              <label>Тип адреса <span class="required">*</span></label>
              <select v-model="addressForm.address_type" class="form-control" required>
                <option value="">Выберите тип</option>
                <option value="legal">Юридический адрес</option>
                <option value="actual">Фактический адрес</option>
                <option value="educational">Учебный корпус</option>
                <option value="branch">Филиал</option>
                <option value="other">Другое</option>
              </select>
            </div>
            <div class="form-group">
              <label>Название корпуса <span class="required">*</span></label>
              <input v-model="addressForm.name" type="text" class="form-control" maxlength="255" @input="addressForm.name = normalizeTextInput(addressForm.name, 255)" required placeholder="Например: Главный корпус">
            </div>
          </div>

          <div class="form-group">
            <label>Полный адрес <span class="required">*</span></label>
            <input v-model="addressForm.address" type="text" class="form-control" maxlength="500" @input="addressForm.address = normalizeTextInput(addressForm.address, 500)" required placeholder="г. Уфа, ул. Борисоглебская, 32">
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Телефон</label>
              <input v-model="addressForm.phone" type="text" class="form-control" placeholder="+7 (347) 123-45-67" @input="addressForm.phone = maskRussianPhone(addressForm.phone)">
            </div>
            <div class="form-group">
              <label>Email</label>
              <input v-model="addressForm.email" type="email" class="form-control" maxlength="255" placeholder="info@college.ru" @input="addressForm.email = normalizeEmailInput(addressForm.email)">
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Координаты (широта, долгота)</label>
              <input v-model="addressForm.coordinates" type="text" class="form-control" maxlength="50" placeholder="54.7355, 55.9587" @input="addressForm.coordinates = normalizeCoordinatesInput(addressForm.coordinates)">
              <small class="form-hint">Формат: широта, долгота (можно получить из Яндекс.Карт)</small>
            </div>
            <div class="form-group">
              <label>Режим работы</label>
              <input v-model="addressForm.working_hours" type="text" class="form-control" maxlength="255" placeholder="Пн-Пт: 8:00-17:00" @input="addressForm.working_hours = normalizeTextInput(addressForm.working_hours, 255)">
            </div>
          </div>

          <div class="form-group">
            <label>Контактное лицо</label>
            <input v-model="addressForm.contact_person" type="text" class="form-control" maxlength="255" placeholder="ФИО ответственного лица" @input="addressForm.contact_person = normalizeTextInput(addressForm.contact_person, 255)">
          </div>

          <div class="form-group">
            <label class="checkbox-label">
              <input type="checkbox" v-model="addressForm.is_main">
              <span>Это главный корпус колледжа</span>
            </label>
          </div>

          <div class="form-actions">
            <button type="submit" class="btn btn-primary" :disabled="saving">
              <i :class="saving ? 'fas fa-spinner fa-spin' : 'fas fa-save'"></i>
              {{ saving ? 'Сохранение...' : 'Сохранить адрес' }}
            </button>
            <button type="button" class="btn btn-secondary" @click="closeAddressModal">Отмена</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  firstError,
  maskInteger,
  maskRussianPhone,
  maskScore,
  maskSpecialtyCode,
  normalizeAddress,
  normalizeCollege,
  normalizeCoordinatesInput,
  normalizeEmailInput,
  normalizeMultilineInput,
  normalizeSpecialty,
  normalizeTextInput,
  normalizeUrlInput,
  validateAddress,
  validateCollege,
  validateSpecialty
} from '../utils/validation'
import { API_URL } from '../utils/api'
import { resolveImageUrl } from '../utils/images'

const router = useRouter()

const activeTab = ref('college')
const alertMessage = ref('')
const alertType = ref('info')
const saving = ref(false)
const loading = ref(true)
const imageUploading = ref(false)
const collegeErrors = ref({})
const specialityErrors = ref({})

// Refs для input элементов загрузки файлов
const logoInputRef = ref(null)

// Данные колледжа (загружаются из БД)
const collegeData = ref({
  id: null,
  name: '',
  status: 'active',
  description: '',
  budget_places: 0,
  commercial_places: 0,
  avg_score: 0,
  min_score: 0,
  phone: '',
  email: '',
  website: '',
  social_vk: '',
  social_max: '',
  social_other: [],
  admission_method: '',
  admission_link: '',
  admission_instructions: '',
  logo_image_url: '',
  is_professionalitet: false,
  professionalitet_cluster: '',
  opportunities: [],
  employers: [],
  workshops: [],
  professions: [],
  ovz_programs: []
})

// Специальности (загружаются из БД)
const specialities = ref([])
const specialitySearch = ref('')
const directorySectors = ref([])
const directorySpecialties = ref([])

// Адреса (загружаются из БД)
const addresses = ref([])

// Модальные окна
const showSpecialityModal = ref(false)
const editingSpeciality = ref(null)
const showAddressModal = ref(false)
const editingAddress = ref(null)

const specialityForm = ref({
  id: '', sector_id: '', specialty_id: '', name: '', code: '', duration: '', base_education: '9', form: 'full-time',
  budget_places: 0, commercial_places: 0, price_per_year: 0, exams: '', avg_score: 0,
  description: '', qualification: '', status: 'active', teaching_address: '',
  admission_method: '', admission_link: '', admission_instructions: ''
})

const addressForm = ref({
  id: '', name: '', address: '', phone: '', email: '', coordinates: '',
  address_type: 'educational', working_hours: '', contact_person: '', is_main: false
})

// Вычисляемые свойства для списков
const sanitizeLines = (value, maxLineLength = 255, maxItems = 50) => value
  .split('\n')
  .map((line) => normalizeTextInput(line, maxLineLength).trim())
  .filter(Boolean)
  .slice(0, maxItems)

const sanitizeUrlLines = (value) => value
  .split('\n')
  .map((line) => normalizeUrlInput(line))
  .filter(Boolean)
  .slice(0, 20)

const ovzText = computed({
  get: () => (collegeData.value.ovz_programs || []).join('\n'),
  set: (v) => collegeData.value.ovz_programs = sanitizeLines(v)
})
const opportunitiesText = computed({
  get: () => (collegeData.value.opportunities || []).join('\n'),
  set: (v) => collegeData.value.opportunities = sanitizeLines(v)
})
const employersText = computed({
  get: () => (collegeData.value.employers || []).join('\n'),
  set: (v) => collegeData.value.employers = sanitizeLines(v)
})
const masterClassesText = computed({
  get: () => (collegeData.value.workshops || []).join('\n'),
  set: (v) => collegeData.value.workshops = sanitizeLines(v)
})
const professionsText = computed({
  get: () => (collegeData.value.professions || []).join('\n'),
  set: (v) => collegeData.value.professions = sanitizeLines(v)
})
const socialOtherText = computed({
  get: () => (collegeData.value.social_other || []).join('\n'),
  set: (v) => collegeData.value.social_other = sanitizeUrlLines(v)
})

const filteredSpecialities = computed(() => specialities.value)

const formatTeachingAddressLabel = (address) => {
  const name = address.name?.trim()
  const value = address.address?.trim()
  return name && value ? `${name} — ${value}` : (value || name || '')
}

const teachingAddressOptions = computed(() => {
  const options = addresses.value
    .filter((address) => address.address?.trim())
    .map((address) => ({
      value: address.address.trim(),
      label: formatTeachingAddressLabel(address)
    }))

  const current = specialityForm.value.teaching_address?.trim()
  if (current && !options.some((item) => item.value === current)) {
    options.push({ value: current, label: current })
  }

  return options
})

const getToken = () => localStorage.getItem('authToken')

const showAlert = (msg, type = 'info') => {
  alertMessage.value = msg
  alertType.value = type
  setTimeout(() => { alertMessage.value = '' }, 5000)
}

// Загрузка данных колледжа из БД
const parseJson = (val) => {
  if (!val) return []
  if (typeof val === 'string') { try { return JSON.parse(val) } catch { return [] } }
  return val
}

const loadDirectorySectors = async () => {
  const response = await fetch(`${API_URL}/sectors`)
  const result = await response.json()
  if (result.success) directorySectors.value = result.data
}

const loadDirectorySpecialties = async (sectorId) => {
  if (!sectorId) {
    directorySpecialties.value = []
    return
  }
  const response = await fetch(`${API_URL}/specialties/directory?sector_id=${sectorId}`)
  const result = await response.json()
  directorySpecialties.value = result.success ? result.data : []
}

const syncDirectorySpecialtyDetails = () => {
  const selected = directorySpecialties.value.find((item) => String(item.id) === String(specialityForm.value.specialty_id))
  if (!selected) return
  specialityForm.value.name = selected.name || ''
  specialityForm.value.code = selected.code || ''
  specialityForm.value.qualification = selected.qualification || specialityForm.value.qualification || ''
}

const loadCollegeData = async () => {
  loading.value = true
  try {
    const token = getToken()
    if (!token) { router.push('/login'); return }

    const res = await fetch(`${API_URL}/colleges/my`, {
      headers: { 'Authorization': `Bearer ${token}` }
    })

    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    if (!res.headers.get('content-type')?.includes('application/json')) {
      throw new Error('Сервер вернул не JSON ответ')
    }

    const result = await res.json()
    if (!result.success) {
      collegeErrors.value = result.errors || {}
      throw new Error(result.error)
    }

    const c = result.data
    collegeData.value = {
      id: c.id, name: c.name, status: c.status || 'active',
      description: c.description || '',
      budget_places: c.budget_places || 0,
      commercial_places: c.commercial_places || 0,
      avg_score: c.avg_score || 0,
      min_score: c.min_score || 0,
      phone: c.phone || '', email: c.email || '',
      website: c.website || '',
      social_vk: c.social_vk || '', social_max: c.social_max || '',
      social_other: parseJson(c.social_other),
      admission_method: c.admission_method || '',
      admission_link: c.admission_link || '',
      admission_instructions: c.admission_instructions || '',
      logo_image_url: c.logo_image_url || '',
      is_professionalitet: c.is_professionalitet || false,
      professionalitet_cluster: c.professionalitet_cluster || '',
      opportunities: parseJson(c.opportunities),
      employers: parseJson(c.employers),
      workshops: parseJson(c.workshops),
      professions: parseJson(c.professions),
      ovz_programs: parseJson(c.ovz_programs)
    }

    // Загрузка специальностей
    try {
      console.log('🎓 Загрузка специальностей...')
      const specRes = await fetch(`${API_URL}/colleges/specialties`, {
        headers: { 'Authorization': `Bearer ${token}` }
      })
      console.log('🎓 Ответ специальностей:', specRes.status, specRes.statusText)
      if (specRes.ok && specRes.headers.get('content-type')?.includes('application/json')) {
        const specResult = await specRes.json()
        console.log('🎓 Специальности результат:', specResult)
        if (specResult.success) specialities.value = specResult.data
      } else {
        const text = await specRes.text()
        console.warn('⚠️ Специальности не JSON:', text.substring(0, 200))
      }
    } catch (e) { console.warn('⚠️ Специальности не загружены:', e) }

    // Загрузка адресов
    try {
      const addrRes = await fetch(`${API_URL}/colleges/addresses`, {
        headers: { 'Authorization': `Bearer ${token}` }
      })
      if (addrRes.ok && addrRes.headers.get('content-type')?.includes('application/json')) {
        const addrResult = await addrRes.json()
        if (addrResult.success) addresses.value = addrResult.data
      }
    } catch (e) { console.warn('Адреса не загружены:', e) }

  } catch (error) {
    console.error('Ошибка загрузки:', error)
    showAlert('Ошибка загрузки данных колледжа', 'error')
  } finally {
    loading.value = false
  }
}

// Сохранение данных колледжа
const saveCollegeData = async () => {
  collegeErrors.value = validateCollege(collegeData.value)
  if (Object.keys(collegeErrors.value).length) return showAlert(firstError(collegeErrors.value), 'error')
  collegeData.value = normalizeCollege(collegeData.value)
  if (!collegeData.value.name?.trim()) return showAlert('Название колледжа обязательно', 'error')
  if (!collegeData.value.description?.trim()) return showAlert('Описание обязательно', 'error')

  saving.value = true
  try {
    const token = getToken()
    const body = {
      name: collegeData.value.name,
      description: collegeData.value.description,
      phone: collegeData.value.phone,
      email: collegeData.value.email,
      website: collegeData.value.website,
      status: collegeData.value.status,
      social_vk: collegeData.value.social_vk,
      social_max: collegeData.value.social_max,
      social_other: collegeData.value.social_other,
      admission_method: collegeData.value.admission_method,
      admission_link: collegeData.value.admission_link,
      admission_instructions: collegeData.value.admission_instructions,
      avg_score: collegeData.value.avg_score,
      min_score: collegeData.value.min_score,
      is_professionalitet: collegeData.value.is_professionalitet,
      professionalitet_cluster: collegeData.value.professionalitet_cluster,
      logo_image_url: collegeData.value.logo_image_url,
      opportunities: collegeData.value.opportunities,
      employers: collegeData.value.employers,
      workshops: collegeData.value.workshops,
      professions: collegeData.value.professions,
      ovz_programs: collegeData.value.ovz_programs
    }

    const res = await fetch(`${API_URL}/colleges/my`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify(body)
    })
    const result = await res.json()
    if (!result.success) {
      collegeErrors.value = result.errors || {}
      throw new Error(result.error)
    }

    showAlert('Данные колледжа успешно сохранены', 'success')
    await loadCollegeData()
  } catch (error) {
    console.error('Ошибка сохранения:', error)
    showAlert('Ошибка сохранения: ' + error.message, 'error')
  } finally {
    saving.value = false
  }
}

// Загрузка изображений колледжа
const triggerImageUpload = (type) => {
  const input = logoInputRef.value
  if (input) {
    input.click()
  }
}

const handleImageUpload = async (event, type) => {
  const file = event.target.files?.[0]
  if (!file) return

  // Проверка размера файла (5MB)
  if (file.size > 5 * 1024 * 1024) {
    showAlert('Файл слишком большой. Максимальный размер: 5MB', 'error')
    return
  }

  // Проверка типа файла
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
  if (!allowedTypes.includes(file.type)) {
    showAlert('Неподдерживаемый формат файла. Разрешены только изображения (JPEG, PNG, GIF, WebP)', 'error')
    return
  }

  imageUploading.value = true
  try {
    const token = getToken()
    const formData = new FormData()
    formData.append('image', file)
    formData.append('imageType', type)

    const res = await fetch(`${API_URL}/upload/college-image`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData
    })

    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const result = await res.json()
    if (!result.success) {
      specialityErrors.value = result.errors || {}
      throw new Error(result.error)
    }

    // Обновляем URL изображения в данных колледжа
    collegeData.value.logo_image_url = result.data.imageUrl

    showAlert('Изображение успешно загружено', 'success')
  } catch (error) {
    console.error('Ошибка загрузки изображения:', error)
    showAlert('Ошибка загрузки изображения: ' + error.message, 'error')
  } finally {
    imageUploading.value = false
    // Очищаем input для возможности повторной загрузки того же файла
    event.target.value = ''
  }
}

// Специальности CRUD
const openSpecialityModal = (spec = null) => {
  specialityErrors.value = {}
  editingSpeciality.value = spec
  if (spec) {
    specialityForm.value = {
      ...spec,
      sector_id: spec.sectors?.[0]?.id ? String(spec.sectors[0].id) : '',
      specialty_id: String(spec.id),
      teaching_address: spec.teaching_address || '',
      admission_method: spec.admission_method || '',
      admission_link: spec.admission_link || '',
      admission_instructions: spec.admission_instructions || ''
    }
    loadDirectorySpecialties(specialityForm.value.sector_id)
  } else {
    specialityForm.value = {
      id: '', sector_id: '', specialty_id: '', name: '', code: '', duration: '', base_education: '9', form: 'full-time',
      budget_places: 0, commercial_places: 0, price_per_year: 0, exams: '', avg_score: 0,
      description: '', qualification: '', status: 'active', teaching_address: '',
      admission_method: '', admission_link: '', admission_instructions: ''
    }
    directorySpecialties.value = []
  }
  if (directorySectors.value.length === 0) loadDirectorySectors()
  showSpecialityModal.value = true
}
const closeSpecialityModal = () => { showSpecialityModal.value = false; specialityErrors.value = {} }

const saveSpeciality = async () => {
  specialityErrors.value = validateSpecialty(specialityForm.value)
  if (Object.keys(specialityErrors.value).length) return showAlert(firstError(specialityErrors.value), 'error')
  specialityForm.value = normalizeSpecialty(specialityForm.value)
  if (!specialityForm.value.specialty_id) return showAlert('Выберите специальность из справочника', 'error')
  if (!specialityForm.value.teaching_address?.trim()) return showAlert('Адрес преподавания обязателен', 'error')

  saving.value = true
  try {
    const token = getToken()
    const url = editingSpeciality.value
      ? `${API_URL}/colleges/specialties/${specialityForm.value.id}`
      : `${API_URL}/colleges/specialties`
    const method = editingSpeciality.value ? 'PUT' : 'POST'

    const res = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify(specialityForm.value)
    })

    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const ct = res.headers.get('content-type')
    if (!ct?.includes('application/json')) throw new Error('Некорректный ответ сервера')

    const result = await res.json()
    if (!result.success) throw new Error(result.error)

    closeSpecialityModal()
    await loadCollegeData()
    showAlert(editingSpeciality.value ? 'Специальность обновлена' : 'Специальность добавлена', 'success')
  } catch (error) {
    showAlert('Ошибка: ' + error.message, 'error')
  } finally {
    saving.value = false
  }
}

const editSpeciality = (spec) => { openSpecialityModal(spec) }

const deleteSpeciality = async (id) => {
  if (!confirm('Удалить специальность?')) return
  try {
    const token = getToken()
    const res = await fetch(`${API_URL}/colleges/specialties/${id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${token}` }
    })
    const result = await res.json()
    if (!result.success) throw new Error(result.error)
    specialities.value = specialities.value.filter(s => s.id !== id)
    showAlert('Специальность удалена', 'success')
  } catch (error) {
    showAlert('Ошибка удаления: ' + error.message, 'error')
  }
}

// Адреса CRUD
const openAddressModal = (addr = null) => {
  console.log('📍 openAddressModal вызван', addr)
  editingAddress.value = addr
  if (addr) {
    addressForm.value = {
      id: addr.id || '',
      name: addr.name || '',
      address: addr.address || '',
      phone: addr.phone || '',
      email: addr.email || '',
      coordinates: addr.coordinates || '',
      address_type: addr.address_type || 'educational',
      working_hours: addr.working_hours || '',
      contact_person: addr.contact_person || '',
      is_main: addr.is_main || false
    }
  } else {
    addressForm.value = {
      id: '', name: '', address: '', phone: '', email: '', coordinates: '',
      address_type: 'educational', working_hours: '', contact_person: '', is_main: false
    }
  }
  showAddressModal.value = true
}
const closeAddressModal = () => { showAddressModal.value = false }

const saveAddress = async () => {
  const addressErrors = validateAddress(addressForm.value)
  if (Object.keys(addressErrors).length) return showAlert(firstError(addressErrors), 'error')
  addressForm.value = normalizeAddress(addressForm.value)

  saving.value = true
  try {
    const token = getToken()
    const url = editingAddress.value
      ? `${API_URL}/colleges/addresses/${addressForm.value.id}`
      : `${API_URL}/colleges/addresses`
    const method = editingAddress.value ? 'PUT' : 'POST'

    const res = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ ...addressForm.value, college_id: collegeData.value.id })
    })

    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const ct = res.headers.get('content-type')
    if (!ct?.includes('application/json')) throw new Error('Некорректный ответ сервера')

    const result = await res.json()
    if (!result.success) throw new Error(result.error)

    closeAddressModal()
    await loadCollegeData()
    showAlert(editingAddress.value ? 'Адрес обновлён' : 'Адрес добавлен', 'success')
  } catch (error) {
    showAlert('Ошибка: ' + error.message, 'error')
  } finally {
    saving.value = false
  }
}

const editAddress = (addr) => { openAddressModal(addr) }

const deleteAddress = async (id) => {
  if (!confirm('Удалить адрес?')) return
  try {
    const token = getToken()
    const res = await fetch(`${API_URL}/colleges/addresses/${id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${token}` }
    })
    const result = await res.json()
    if (!result.success) throw new Error(result.error)
    addresses.value = addresses.value.filter(a => a.id !== id)
    showAlert('Адрес удалён', 'success')
  } catch (error) {
    showAlert('Ошибка удаления: ' + error.message, 'error')
  }
}

const getStatusName = (s) => ({ active: 'Активна', inactive: 'Неактивна', draft: 'Черновик' }[s] || s)
const getStatusClass = (s) => s === 'active' ? 'status-active' : s === 'inactive' ? 'status-inactive' : 'status-draft'

const getAddressTypeName = (type) => ({
  legal: 'Юридический',
  actual: 'Фактический',
  educational: 'Учебный корпус',
  branch: 'Филиал',
  other: 'Другое'
}[type] || 'Учебный корпус')

const logout = () => {
  if (confirm('Выйти из системы?')) {
    localStorage.removeItem('authToken')
    localStorage.removeItem('user')
    router.push('/login')
  }
}

onMounted(() => {
  loadDirectorySectors().catch((error) => console.warn('Не удалось загрузить отрасли:', error))
  loadCollegeData()
})
</script>

<style scoped>
.loading-state {
  text-align: center;
  padding: 100px 20px;
  color: #64748b;
  font-size: 1.1rem;
}
.loading-state i {
  font-size: 2.5rem;
  color: #667eea;
  margin-bottom: 15px;
  display: block;
  animation: spin 1s linear infinite;
}
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* Адреса */
.addresses-table-wrapper {
  margin-bottom: 20px;
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.address-type-badge {
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 600;
  display: inline-block;
}
.address-type-badge.legal { background: #fee2e2; color: #dc2626; }
.address-type-badge.actual { background: #dbeafe; color: #2563eb; }
.address-type-badge.educational { background: #d1fae5; color: #059669; }
.address-type-badge.branch { background: #fef3c7; color: #d97706; }
.address-type-badge.other { background: #f3e8ff; color: #7c3aed; }

.main-badge {
  background: #0054A6;
  color: white;
  padding: 3px 10px;
  border-radius: 10px;
  font-size: 0.75rem;
  font-weight: 600;
}

.empty-addresses {
  text-align: center;
  padding: 40px 20px;
  color: #94a3b8;
}
.empty-addresses i {
  font-size: 2.5rem;
  margin-bottom: 10px;
  display: block;
}

.add-address-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 24px;
  background: #0054A6;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  margin-top: 15px;
  transition: all 0.3s;
}
.add-address-btn:hover { background: #003d7a; }

/* Modal */
.modal-lg { max-width: 700px; }
.form-hint { color: #94a3b8; font-size: 0.8rem; margin-top: 4px; display: block; }
.form-control.invalid { border-color: #dc2626; box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.08); }
.field-error { color: #dc2626; font-size: 0.8rem; margin-top: 4px; display: block; }
.auto-calculated-note {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin: -4px 0 18px;
  padding: 10px 14px;
  border-radius: 8px;
  background: rgba(0, 84, 166, 0.08);
  color: #0054A6;
  font-size: 0.92rem;
  font-weight: 600;
}
.checkbox-label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-weight: normal;
}
.checkbox-label input[type="checkbox"] {
  width: 18px;
  height: 18px;
  cursor: pointer;
}

/* Стили для превью изображений и кнопки удаления */
.image-preview {
  position: relative;
  margin-top: 15px;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  display: inline-block;
}

.image-preview img {
  max-width: 300px;
  max-height: 300px;
  display: block;
}

.remove-image-btn {
  position: absolute;
  top: 8px;
  right: 8px;
  background: rgba(220, 38, 38, 0.9);
  color: white;
  border: none;
  border-radius: 50%;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 14px;
}

.remove-image-btn:hover {
  background: rgba(185, 28, 28, 1);
  transform: scale(1.1);
}

.image-upload {
  border: 2px dashed #cbd5e1;
  border-radius: 8px;
  padding: 30px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  background: #f8fafc;
}

.image-upload:hover {
  border-color: #667eea;
  background: #f0f4ff;
}

.image-upload i {
  font-size: 2.5rem;
  color: #667eea;
  margin-bottom: 10px;
  display: block;
}

.text-small {
  font-size: 0.75rem;
  color: #94a3b8;
  margin-top: 5px;
}

@media (max-width: 768px) {
  .college-rep-panel .container {
    width: 100%;
    padding: 0 12px;
  }

  .panel-header {
    padding: 14px 0;
    margin-bottom: 16px;
  }

  .panel-header .header-content {
    flex-direction: column;
    align-items: stretch;
    text-align: left;
  }

  .panel-header .logo {
    align-items: flex-start;
  }

  .logo-text h1 {
    font-size: 1.15rem;
    line-height: 1.25;
  }

  .panel-header .logout-btn {
    width: 100%;
    justify-content: center;
  }

  .tabs {
    overflow-x: auto;
    gap: 6px;
    padding: 8px;
    margin-bottom: 16px;
  }

  .tab-btn {
    flex: 0 0 auto;
    min-width: 150px;
    min-height: 44px;
    padding: 10px 14px;
    justify-content: center;
    white-space: nowrap;
  }

  .tab-content {
    padding: 16px;
    border-radius: 8px;
  }

  .section {
    margin-bottom: 16px;
    padding-bottom: 12px;
  }

  .section-title {
    font-size: 1.15rem;
    line-height: 1.25;
  }

  .settings-grid,
  .stats-grid,
  .form-row {
    grid-template-columns: 1fr;
    gap: 14px;
  }

  .specialities-header,
  .filters-bar,
  .form-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .search-box,
  .btn-add,
  .btn,
  .filter-select {
    width: 100%;
    max-width: none;
  }

  .btn-add,
  .btn {
    justify-content: center;
    min-height: 44px;
  }

  .addresses-table-wrapper,
  .table-container {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }

  .data-table {
    min-width: 780px;
    font-size: 0.88rem;
  }

  .data-table th,
  .data-table td {
    padding: 10px;
  }

  .action-buttons {
    flex-direction: row;
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

  .image-upload {
    padding: 22px 12px;
  }

  .image-preview {
    display: block;
  }

  .image-preview img {
    width: 100%;
    max-width: none;
    max-height: 240px;
    object-fit: contain;
  }
}
</style>
