import { expect, test } from '@playwright/test'

const apiBase = 'http://127.0.0.1:3000/api'
const runId = `${Date.now()}-${Math.random().toString(16).slice(2)}`

async function loginAs(request, username, password) {
  const response = await request.post(`${apiBase}/auth/login`, {
    data: { username, password }
  })
  expect(response.ok(), await response.text()).toBeTruthy()
  const body = await response.json()
  expect(body.success).toBeTruthy()
  return {
    token: body.data.token,
    user: body.data.user
  }
}

const authHeaders = (token) => ({ Authorization: `Bearer ${token}` })

async function expectValidationError(response) {
  expect(response.status()).toBe(400)
  const body = await response.json()
  expect(body.success).toBeFalsy()
  expect(body.error || body.errors).toBeTruthy()
  return body
}

async function createCollege(request, adminToken, suffix = runId) {
  const response = await request.post(`${apiBase}/colleges`, {
    headers: authHeaders(adminToken),
    data: {
      name: `E2E College ${suffix}`,
      shortName: `E2E-${suffix.slice(-6)}`,
      city: 'Ufa',
      description: 'Created by Playwright e2e tests',
      phone: '+7 (347) 200-00-00',
      email: `college-${suffix}@example.com`,
      website: 'https://example.com'
    }
  })
  expect(response.ok(), await response.text()).toBeTruthy()
  const body = await response.json()
  expect(body.success).toBeTruthy()
  expect(body.data.id).toBeTruthy()
  return body.data
}

async function createRepresentative(request, adminToken, overrides = {}) {
  const suffix = overrides.suffix || `${runId}-${Math.random().toString(16).slice(2, 8)}`
  const response = await request.post(`${apiBase}/users`, {
    headers: authHeaders(adminToken),
    data: {
      name: `E2E Representative ${suffix}`,
      login: `e2e_rep_${suffix.replace(/[^A-Za-z0-9_]/g, '_')}`.slice(0, 50),
      email: `rep-${suffix}@example.com`,
      phone: '+7 (999) 111-22-33',
      password: 'rep12345',
      role: 'college_rep',
      status: 'active',
      college_id: null,
      ...overrides
    }
  })
  expect(response.ok(), await response.text()).toBeTruthy()
  const body = await response.json()
  expect(body.success).toBeTruthy()
  expect(body.data.id).toBeTruthy()
  return { response, body }
}

test.describe.serial('admin and representative CRUD flows', () => {
  let flowId
  let adminToken
  let college
  let repLogin
  let repPassword
  let repId
  let repToken
  let specialtyId
  let addressId

  test.beforeAll(async ({ request }, testInfo) => {
    flowId = `${testInfo.project.name}-${runId}`.replace(/[^A-Za-z0-9_@.-]/g, '_')
    const admin = await loginAs(request, 'admin', 'admin123')
    adminToken = admin.token
  })

  test('rejects invalid representative, college and specialty payloads', async ({ request }) => {
    const badRep = await request.post(`${apiBase}/users`, {
      headers: authHeaders(adminToken),
      data: {
        name: 'A',
        login: 'bad login',
        email: 'not-email',
        phone: '+7 999',
        password: '123',
        role: 'college_rep',
        status: 'active'
      }
    })
    await expectValidationError(badRep)

    const badCollege = await request.post(`${apiBase}/colleges`, {
      headers: authHeaders(adminToken),
      data: { city: 'Ufa' }
    })
    await expectValidationError(badCollege)

    const unauthSpecialty = await request.post(`${apiBase}/colleges/specialties`, {
      data: { code: 'bad', name: 'No auth' }
    })
    expect([401, 403]).toContain(unauthSpecialty.status())
  })

  test('creates and edits a representative without a college as inactive', async ({ request }) => {
    const suffix = `no_college_${flowId.replace(/[^A-Za-z0-9_]/g, '_').slice(-30)}`
    const { body } = await createRepresentative(request, adminToken, {
      suffix,
      login: `e2e_no_college_${suffix}`.slice(0, 50),
      email: `no-college-${flowId}@example.com`,
      college_id: null,
      status: 'active'
    })

    expect(body.data.status).toBe('inactive')
    if (!body.email_sent) {
      expect(body.credentials?.password).toBe('rep12345')
    }

    const edited = await request.put(`${apiBase}/users/${body.data.id}`, {
      headers: authHeaders(adminToken),
      data: {
        name: 'E2E Representative Without College Edited',
        login: body.data.login,
        email: body.data.email,
        phone: '+7 (999) 111-22-34',
        password: '',
        role: 'college_rep',
        status: 'active',
        college_id: null
      }
    })
    expect(edited.ok(), await edited.text()).toBeTruthy()
    const editedBody = await edited.json()
    expect(editedBody.success).toBeTruthy()
    expect(editedBody.data.status).toBe('inactive')
  })

  test('creates and edits a college through admin API', async ({ request }) => {
    college = await createCollege(request, adminToken, flowId)

    const update = await request.put(`${apiBase}/colleges/${college.id}`, {
      headers: authHeaders(adminToken),
      data: {
        name: `${college.name} Updated`,
        shortName: `${college.short_name || 'E2E'}U`.slice(0, 50),
        city: 'Sterlitamak',
        description: 'Updated by Playwright e2e tests',
        phone: '+7 (347) 200-00-01',
        email: `college-updated-${flowId}@example.com`,
        website: 'https://example.org',
        status: 'active'
      }
    })
    expect(update.ok(), await update.text()).toBeTruthy()
    const body = await update.json()
    expect(body.success).toBeTruthy()
    expect(body.data.name).toContain('Updated')

    const noChanges = await request.put(`${apiBase}/colleges/${college.id}`, {
      headers: authHeaders(adminToken),
      data: {}
    })
    await expectValidationError(noChanges)
  })

  test('creates an active college representative, rejects duplicate college assignment, and logs in', async ({ request }) => {
    repLogin = `e2e_college_rep_${flowId.replace(/[^A-Za-z0-9_]/g, '_')}`.slice(0, 50)
    repPassword = 'rep12345'

    const { body } = await createRepresentative(request, adminToken, {
      suffix: `with_college_${flowId}`,
      name: 'E2E Active College Representative',
      login: repLogin,
      email: `active-rep-${flowId}@example.com`,
      password: repPassword,
      college_id: college.id,
      status: 'active'
    })
    repId = body.data.id
    expect(body.data.status).toBe('active')

    const duplicate = await request.post(`${apiBase}/users`, {
      headers: authHeaders(adminToken),
      data: {
        name: 'E2E Duplicate Representative',
        login: `e2e_dup_${flowId.replace(/[^A-Za-z0-9_]/g, '_')}`.slice(0, 50),
        email: `duplicate-rep-${flowId}@example.com`,
        password: repPassword,
        role: 'college_rep',
        status: 'active',
        college_id: college.id
      }
    })
    await expectValidationError(duplicate)

    const edited = await request.put(`${apiBase}/users/${repId}`, {
      headers: authHeaders(adminToken),
      data: {
        name: 'E2E Active College Representative Edited',
        login: repLogin,
        email: `active-rep-edited-${flowId}@example.com`,
        phone: '+7 (999) 333-44-55',
        password: '',
        role: 'college_rep',
        status: 'active',
        college_id: college.id
      }
    })
    expect(edited.ok(), await edited.text()).toBeTruthy()
    const editedBody = await edited.json()
    expect(editedBody.success).toBeTruthy()

    const rep = await loginAs(request, repLogin, repPassword)
    repToken = rep.token
    expect(rep.user.collegeId).toBe(college.id)
  })

  test('representative edits own college profile and address list', async ({ request }) => {
    const myCollege = await request.get(`${apiBase}/colleges/my`, {
      headers: authHeaders(repToken)
    })
    expect(myCollege.ok(), await myCollege.text()).toBeTruthy()
    const myCollegeBody = await myCollege.json()
    expect(myCollegeBody.success).toBeTruthy()
    expect(myCollegeBody.data.id).toBe(college.id)

    const update = await request.put(`${apiBase}/colleges/my`, {
      headers: authHeaders(repToken),
      data: {
        name: `${college.name} Rep Updated`,
        short_name: `R-${flowId.slice(-8)}`,
        description: 'Representative profile update',
        phone: '+7 (347) 200-00-02',
        email: `rep-college-${flowId}@example.com`,
        website: 'https://college.example.com',
        social_vk: 'https://vk.com/example',
        social_max: 'https://max.ru/example',
        budget_places: 10,
        commercial_places: 5,
        avg_score: 4.1,
        min_score: 3.2,
        status: 'active'
      }
    })
    expect(update.ok(), await update.text()).toBeTruthy()
    const updateBody = await update.json()
    expect(updateBody.success).toBeTruthy()

    const createdAddress = await request.post(`${apiBase}/colleges/addresses`, {
      headers: authHeaders(repToken),
      data: {
        name: 'Main campus',
        address: 'Ufa, Test street, 1',
        phone: '+7 (347) 200-00-03',
        email: `address-${flowId}@example.com`,
        coordinates: '54.7351,55.9587',
        is_main: true,
        address_type: 'educational',
        working_hours: '09:00-18:00',
        contact_person: 'E2E Contact'
      }
    })
    expect(createdAddress.ok(), await createdAddress.text()).toBeTruthy()
    const addressBody = await createdAddress.json()
    expect(addressBody.success).toBeTruthy()
    addressId = addressBody.data.id

    const editedAddress = await request.put(`${apiBase}/colleges/addresses/${addressId}`, {
      headers: authHeaders(repToken),
      data: {
        name: 'Main campus edited',
        address: 'Ufa, Test street, 2',
        phone: '+7 (347) 200-00-04',
        email: `address-edited-${flowId}@example.com`,
        coordinates: '54.7352,55.9588',
        is_main: true,
        address_type: 'educational',
        working_hours: '10:00-17:00',
        contact_person: 'E2E Contact Edited'
      }
    })
    expect(editedAddress.ok(), await editedAddress.text()).toBeTruthy()
    const editedAddressBody = await editedAddress.json()
    expect(editedAddressBody.success).toBeTruthy()
    expect(editedAddressBody.data.name).toContain('edited')
  })

  test('creates, rejects invalid duplicate, edits, lists and deletes a representative specialty', async ({ request }) => {
    const invalid = await request.post(`${apiBase}/colleges/specialties`, {
      headers: authHeaders(repToken),
      data: {
        code: 'bad-code',
        name: 'No',
        form: 'invalid',
        base_education: '12',
        budget_places: -1
      }
    })
    await expectValidationError(invalid)

    const specialtyPayload = {
      code: `99.02.${String(Date.now()).slice(-2)}`,
      name: `E2E Specialty ${flowId}`,
      description: 'Created by Playwright e2e tests',
      qualification: 'Specialist',
      duration: '2 years',
      base_education: '9',
      form: 'full-time',
      exams: 'Math',
      budget_places: 12,
      commercial_places: 6,
      price_per_year: 50000,
      avg_score: 4.2,
      status: 'active'
    }

    const created = await request.post(`${apiBase}/colleges/specialties`, {
      headers: authHeaders(repToken),
      data: specialtyPayload
    })
    expect(created.ok(), await created.text()).toBeTruthy()
    const createdBody = await created.json()
    expect(createdBody.success).toBeTruthy()
    specialtyId = createdBody.data.id

    const duplicate = await request.post(`${apiBase}/colleges/specialties`, {
      headers: authHeaders(repToken),
      data: specialtyPayload
    })
    await expectValidationError(duplicate)

    const edited = await request.put(`${apiBase}/colleges/specialties/${specialtyId}`, {
      headers: authHeaders(repToken),
      data: {
        ...specialtyPayload,
        name: `${specialtyPayload.name} Edited`,
        commercial_places: 8,
        price_per_year: 55000,
        avg_score: 4.4
      }
    })
    expect(edited.ok(), await edited.text()).toBeTruthy()
    const editedBody = await edited.json()
    expect(editedBody.success).toBeTruthy()

    const list = await request.get(`${apiBase}/colleges/specialties`, {
      headers: authHeaders(repToken)
    })
    expect(list.ok(), await list.text()).toBeTruthy()
    const listBody = await list.json()
    expect(listBody.success).toBeTruthy()
    expect(listBody.data.some((item) => item.id === specialtyId)).toBeTruthy()

    const removed = await request.delete(`${apiBase}/colleges/specialties/${specialtyId}`, {
      headers: authHeaders(repToken)
    })
    expect(removed.ok(), await removed.text()).toBeTruthy()
    const removedBody = await removed.json()
    expect(removedBody.success).toBeTruthy()
  })

  test('public and auth endpoints keep working after CRUD changes', async ({ request }) => {
    const endpoints = [
      `${apiBase}/sectors`,
      `${apiBase}/specialties?limit=5&page=1`,
      `${apiBase}/colleges?limit=5&page=1`,
      `${apiBase}/colleges/stats`,
      `${apiBase}/colleges/${college.id}`
    ]

    for (const endpoint of endpoints) {
      const response = await request.get(endpoint)
      expect(response.ok(), endpoint).toBeTruthy()
      const body = await response.json()
      expect(body.success, endpoint).toBeTruthy()
    }

    const me = await request.get(`${apiBase}/auth/me`, {
      headers: authHeaders(repToken)
    })
    expect(me.ok(), await me.text()).toBeTruthy()
    const meBody = await me.json()
    expect(meBody.success).toBeTruthy()
    expect(meBody.data.user.login).toBe(repLogin)
  })
})
