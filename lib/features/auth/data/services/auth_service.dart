import 'package:ocupa2/features/auth/data/models/auth_response.dart';
import 'package:ocupa2/features/auth/data/models/change_password_request.dart';
import 'package:ocupa2/features/auth/data/models/complete_profile_request.dart';
import 'package:ocupa2/features/auth/data/models/forgot_password_request.dart';
import 'package:ocupa2/features/auth/data/models/login_request.dart';
import 'package:ocupa2/features/auth/data/models/message_response.dart';
import 'package:ocupa2/features/auth/data/models/register_request.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';

abstract interface class AuthService {
  Future<AuthResponse> register(RegisterRequest request);

  Future<AuthResponse> login(LoginRequest request);

  Future<MessageResponse> forgotPassword(ForgotPasswordRequest request);

  Future<User> getCurrentUser();

  Future<void> completeProfile(CompleteProfileRequest request);

  Future<MessageResponse> changePassword(ChangePasswordRequest request);
}
