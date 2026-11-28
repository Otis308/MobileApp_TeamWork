const request = require('supertest');

const API_URL = 'http://localhost:3000';

if (!process.env.TEST_USER_EMAIL || !process.env.TEST_USER_PASSWORD) {
  console.warn('⚠ Thiếu TEST_USER_EMAIL/TEST_USER_PASSWORD trong biến môi trường — test cần tài khoản thật để lấy token.');
}

describe('Feature: Quản lý Task (API /tasks)', () => {
  let validToken = ''; // Biến để lưu token thật

  // Bước 1: Hook chạy trước khi test để lấy Token
  beforeAll(async () => {
    const loginResponse = await request(API_URL)
      .post('/auth/login')
      .send({
        email: process.env.TEST_USER_EMAIL,
        password: process.env.TEST_USER_PASSWORD,
      });

    // --- CÁC DÒNG DEBUG QUAN TRỌNG ---
    console.log('--- DEBUG LOGIN ---');
    console.log('HTTP Status:', loginResponse.status);
    console.log('Response Body:', loginResponse.body);
    console.log('-------------------');

    // Lấy token (tạm thời giữ nguyên)
    validToken = `Bearer ${loginResponse.body.access_token}`;  });

  // Bước 2: Bắt đầu chạy Test Case 1
  it('TC_TASK_001: Tạo task thành công khi điền đủ thông tin', async () => {
    const payload = {
      title: 'Fix bug màn hình đăng nhập',
      projectId: '6af18482c5087427bb4db0c6'
    };

    const response = await request(API_URL)
      .post('/tasks')
      .set('Authorization', validToken) 
      .send(payload);

    if (response.status !== 201) {
      console.log('--- NESTJS VALIDATION ERROR ---');
      console.log(response.body);
    }
    expect(response.status).toBe(201); 
    expect(response.body.title).toBe(payload.title);
  });

  // Bước 3: Chạy Test Case 2
  it('TC_TASK_002: Báo lỗi 400 khi để trống tiêu đề task', async () => {
    const invalidPayload = {
      title: '',
      assignee: 'Nguyen Vu'
    };

    const response = await request(API_URL)
      .post('/tasks')
      .set('Authorization', validToken) // Vẫn dùng token thật đó
      .send(invalidPayload);

    expect(response.status).toBe(400);
  });
});