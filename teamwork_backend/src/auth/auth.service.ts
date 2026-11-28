import { Injectable, BadRequestException, Logger, UnauthorizedException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config'; 
import * as nodemailer from 'nodemailer';
import { User } from './schemas/user.schema';
import { Otp } from './schemas/otp.schema';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private transporter;
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(Otp.name) private otpModel: Model<Otp>,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: this.configService.get<string>('EMAIL_USER'), 
        pass: this.configService.get<string>('EMAIL_PASS'),
      },
    });
  }

  async register(body: any) {
    const { email, password, fullName } = body;
    const existingUser = await this.userModel.findOne({ email });
    if (existingUser) throw new BadRequestException('Email đã được sử dụng');

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const newUser = new this.userModel({ email, passwordHash, fullName });
    await newUser.save();

    // Register → account is immediately usable: issue a JWT right away.
    const payload = {
      sub:      newUser._id,
      email:    newUser.email,
      fullName: newUser.fullName,
    };
    return {
      message:      'Đăng ký thành công',
      access_token: await this.jwtService.signAsync(payload),
      user:         payload,
    };
  }

  async login(body: any) {
    const user = await this.userModel.findOne({ email: body.email });
    if (!user) throw new UnauthorizedException('Tài khoản không tồn tại');

    const isMatch = await bcrypt.compare(body.password, user.passwordHash);
    if (!isMatch) throw new UnauthorizedException('Sai mật khẩu');

    const payload = { sub: user._id, email: user.email, fullName: user.fullName };
    return {
      access_token: await this.jwtService.signAsync(payload),
      user: payload,
    };
  }

  async requestPasswordReset(email: string) {
    const user = await this.userModel.findOne({ email });
    if (!user) throw new BadRequestException('Email không tồn tại trong hệ thống');

    const recentOtp = await this.otpModel.findOne({ email }).sort({ createdAt: -1 });
    if (recentOtp) {
      const timeDiff = (new Date().getTime() - recentOtp['createdAt'].getTime()) / 1000;
      if (timeDiff < 60) {
        throw new BadRequestException(`Vui lòng đợi ${Math.ceil(60 - timeDiff)} giây để gửi lại mã`);
      }
    }
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 60 * 1000); // Mã có hiệu lực đúng 60 giây

    await this.otpModel.create({ email, otpCode, expiresAt });

    // Gửi Email
    await this.transporter.sendMail({
      from: '"WorkFlow App" <no-reply@workflow.com>',
      to: email,
      subject: 'Mã xác nhận khôi phục mật khẩu',
      html: `<b>Mã OTP của bạn là: ${otpCode}</b><br>Mã này sẽ hết hạn sau 60 giây.`,
    }).catch(err => this.logger.warn('Lỗi gửi email', err)); // Bỏ qua lỗi email để test API nếu chưa có mật khẩu thật

    // Only expose the OTP in the response for local development.
    const isDev = (process.env.NODE_ENV ?? 'development') !== 'production';
    return {
      message: 'Mã OTP đã được gửi đến email của bạn',
      ...(isDev ? { otp_demo: otpCode } : {}),
    };
  }

  async resetPassword(body: any) {
    const { email, otp, newPassword } = body;

    // 1. Xác thực OTP — lấy mã mới nhất của email này để có thể đếm số lần nhập sai.
    const record = await this.otpModel.findOne({ email }).sort({ createdAt: -1 });
    if (!record) throw new BadRequestException('Mã OTP không hợp lệ');
    if (new Date() > record.expiresAt) throw new BadRequestException('Mã OTP đã hết hạn (quá 60 giây)');
    if (record.failedAttempts >= 5) {
      throw new BadRequestException('Bạn đã nhập sai mã OTP quá 5 lần, vui lòng yêu cầu gửi mã mới');
    }
    if (record.otpCode !== otp) {
      record.failedAttempts += 1;
      await record.save();
      throw new BadRequestException('Mã OTP không hợp lệ');
    }

    // 2. Hash mật khẩu mới và cập nhật
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    await this.userModel.updateOne({ email }, { passwordHash });

    // 3. Xóa các OTP cũ của user này để dọn dẹp Database
    await this.otpModel.deleteMany({ email });

    return { message: 'Đổi mật khẩu thành công' };
  }
}
