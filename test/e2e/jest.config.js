module.exports = {
  testEnvironment: 'node',
  verbose: true,
  // Thiết lập đường dẫn trỏ thẳng vào server NestJS đang chạy local
  globals: {
    BASE_URL: 'http://localhost:3000/api', 
  },
};