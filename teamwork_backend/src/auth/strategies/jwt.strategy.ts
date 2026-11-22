import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { User } from '../schemas/user.schema';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private config: ConfigService,
    @InjectModel(User.name) private userModel: Model<User>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_SECRET'), // đọc từ .env
    });
  }

  async validate(payload: any) {
    // Token còn hạn nhưng user đã bị xóa thì không được phép dùng nữa.
    const exists = await this.userModel.exists({ _id: payload.sub });
    if (!exists) throw new UnauthorizedException('Tài khoản không còn tồn tại');

    return {
      userId:   payload.sub,
      email:    payload.email,
      fullName: payload.fullName,
    };
  }
}
