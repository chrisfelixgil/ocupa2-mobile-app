import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/auth/data/models/auth_response.dart';
import 'package:ocupa2/features/auth/data/models/change_password_request.dart';
import 'package:ocupa2/features/auth/data/models/forgot_password_request.dart';
import 'package:ocupa2/features/auth/data/models/login_request.dart';
import 'package:ocupa2/features/auth/data/models/message_response.dart';
import 'package:ocupa2/features/auth/data/models/register_request.dart';
import 'package:ocupa2/features/auth/data/repositories/auth_repository.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_action_status.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this._authRepository,
    required this._sessionViewModel,
  });

  final AuthRepository _authRepository;
  final SessionViewModel _sessionViewModel;

  AuthActionStatus _status = AuthActionStatus.idle;
  String? _errorMessage;
  String? _successMessage;
  bool _isDisposed = false;

  AuthActionStatus get status => _status;

  String? get errorMessage => _errorMessage;

  String? get successMessage => _successMessage;

  bool get isLoading {
    return _status == AuthActionStatus.loading;
  }

  bool get hasFeedback {
    return _errorMessage != null || _successMessage != null;
  }

  Future<bool> login({required String email, required String password}) {
    return _execute<AuthResponse>(
      operation: () {
        return _authRepository.login(
          LoginRequest(email: email, password: password),
        );
      },
      successMessageBuilder: (_) {
        return 'Inicio de sesión correcto.';
      },
      onSuccess: (AuthResponse response) {
        _sessionViewModel.setAuthenticatedUser(response.user);
      },
    );
  }

  Future<bool> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String referralMatricula,
  }) {
    return _execute<AuthResponse>(
      operation: () {
        return _authRepository.register(
          RegisterRequest(
            email: email,
            firstName: firstName,
            lastName: lastName,
            password: password,
            referralMatricula: referralMatricula,
          ),
        );
      },
      successMessageBuilder: (_) {
        return 'La cuenta fue creada correctamente.';
      },
      onSuccess: (AuthResponse response) {
        _sessionViewModel.setAuthenticatedUser(response.user);
      },
    );
  }

  Future<bool> forgotPassword({
    required String email,
    required String referralMatricula,
  }) {
    return _execute<MessageResponse>(
      operation: () {
        return _authRepository.forgotPassword(
          ForgotPasswordRequest(
            email: email,
            referralMatricula: referralMatricula,
          ),
        );
      },
      successMessageBuilder: (MessageResponse response) {
        return response.message;
      },
    );
  }

  Future<bool> changePassword({required String password}) {
    return _execute<MessageResponse>(
      operation: () {
        return _authRepository.changePassword(
          ChangePasswordRequest(password: password),
        );
      },
      successMessageBuilder: (MessageResponse response) {
        return response.message;
      },
    );
  }

  void resetFeedback() {
    if (_isDisposed || isLoading) {
      return;
    }

    _status = AuthActionStatus.idle;
    _errorMessage = null;
    _successMessage = null;

    notifyListeners();
  }

  Future<bool> _execute<T>({
    required Future<T> Function() operation,
    required String Function(T result) successMessageBuilder,
    void Function(T result)? onSuccess,
  }) async {
    if (_isDisposed || isLoading) {
      return false;
    }

    _setLoading();

    try {
      final T result = await operation();

      if (_isDisposed) {
        return false;
      }

      onSuccess?.call(result);

      if (_isDisposed) {
        return false;
      }

      _status = AuthActionStatus.success;
      _errorMessage = null;
      _successMessage = successMessageBuilder(result);

      notifyListeners();

      return true;
    } on ApiException catch (error) {
      if (_isDisposed) {
        return false;
      }

      _status = AuthActionStatus.error;
      _errorMessage = error.message;
      _successMessage = null;

      notifyListeners();

      return false;
    } catch (_) {
      if (_isDisposed) {
        return false;
      }

      _status = AuthActionStatus.error;
      _errorMessage = 'Ocurrió un problema inesperado. Inténtalo nuevamente.';
      _successMessage = null;

      notifyListeners();

      return false;
    }
  }

  void _setLoading() {
    _status = AuthActionStatus.loading;
    _errorMessage = null;
    _successMessage = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
