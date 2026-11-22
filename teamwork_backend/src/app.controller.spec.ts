import { AppController } from './app.controller';

describe('AppController', () => {
  it('getHealth trả về status ok', () => {
    const res = new AppController().getHealth();
    expect(res.status).toBe('ok');
    expect(typeof res.uptime).toBe('number');
  });
});
