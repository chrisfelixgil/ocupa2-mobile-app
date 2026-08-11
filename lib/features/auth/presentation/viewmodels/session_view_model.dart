import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/session/session_event.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/data/repositories/auth_repository.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_status.dart';

class SessionViewModel extends ChangeNotifier {
  SessionViewModel({
    required this._authRepository,
    required this._sessionEventBus,
  }) {
    _sessionSubscription = _sessionEventBus.events.listen(_onSessionEvent);
  }

  final AuthRepository _authRepository;
  final SessionEventBus _sessionEventBus;

  late final StreamSubscription<SessionEvent> _sessionSubscription;

  AuthStatus _status = AuthStatus.checking;
  User? _user;
  String? _errorMessage;
  String? _sessionActionErrorMessage;

  bool _isRestoring = false;
  bool _isLoggingOut = false;
  bool _isDisposed = false;
  bool _requiresPasswordChange = false;

  int _operationId = 0;

  AuthStatus get status => _status;

  User? get user => _user;

  String? get errorMessage => _errorMessage;

  String? get sessionActionErrorMessage {
    return _sessionActionErrorMessage;
  }

  bool get isAuthenticated {
    return _status == AuthStatus.authenticated && _user != null;
  }

  bool get isChecking {
    return _status == AuthStatus.checking;
  }

  bool get isLoggingOut => _isLoggingOut;

  bool get requiresPasswordChange => _requiresPasswordChange;

  Future<void> restoreSession() async {
    if (_isDisposed || _isRestoring || _isLoggingOut) {
      return;
    }

    _isRestoring = true;

    final int currentOperation = ++_operationId;

    _setChecking();

    try {
      final bool hasStoredSession = await _authRepository.hasStoredSession();

      if (!_canApplyResult(currentOperation)) {
        return;
      }

      if (!hasStoredSession) {
        _setUnauthenticated();
        return;
      }

      final User currentUser = await _authRepository.getCurrentUser();

      if (!_canApplyResult(currentOperation)) {
        return;
      }

      _setAuthenticated(currentUser);
    } on ApiException catch (error) {
      if (!_canApplyResult(currentOperation)) {
        return;
      }

      if (error.isUnauthorized) {
        await _clearUnauthorizedSession(operationId: currentOperation);
        return;
      }

      _setError(error.message);
    } catch (_) {
      if (!_canApplyResult(currentOperation)) {
        return;
      }

      _setError(
        'No fue posible verificar la sesión. '
        'Inténtalo nuevamente.',
      );
    } finally {
      if (currentOperation == _operationId) {
        _isRestoring = false;
      }
    }
  }

  void setAuthenticatedUser(User user, {bool requirePasswordChange = false}) {
    if (_isDisposed) {
      return;
    }

    ++_operationId;

    _isRestoring = false;
    _isLoggingOut = false;
    _requiresPasswordChange = requirePasswordChange;

    _setAuthenticated(user);
  }

  void clearPasswordChangeRequirement() {
    if (_isDisposed || !_requiresPasswordChange) {
      return;
    }

    _requiresPasswordChange = false;
    _notifySafely();
  }

  Future<bool> logout() async {
    if (_isDisposed || _isLoggingOut) {
      return false;
    }

    final AuthStatus previousStatus = _status;
    final User? previousUser = _user;

    final int currentOperation = ++_operationId;

    _isRestoring = false;
    _isLoggingOut = true;
    _sessionActionErrorMessage = null;

    _notifySafely();

    try {
      await _authRepository.clearSession();

      if (!_canApplyResult(currentOperation)) {
        return false;
      }

      _isLoggingOut = false;
      _setUnauthenticated();

      return true;
    } on ApiException catch (error) {
      if (!_canApplyResult(currentOperation)) {
        return false;
      }

      _isLoggingOut = false;
      _status = previousStatus;
      _user = previousUser;
      _errorMessage = null;
      _sessionActionErrorMessage = error.message;

      _notifySafely();

      return false;
    } catch (_) {
      if (!_canApplyResult(currentOperation)) {
        return false;
      }

      _isLoggingOut = false;
      _status = previousStatus;
      _user = previousUser;
      _errorMessage = null;
      _sessionActionErrorMessage =
          'No fue posible cerrar la sesión. Inténtalo nuevamente.';

      _notifySafely();

      return false;
    }
  }

  Future<void> _clearUnauthorizedSession({required int operationId}) async {
    try {
      await _authRepository.clearSession();
    } on ApiException catch (error) {
      if (_canApplyResult(operationId)) {
        _setError(error.message);
      }

      return;
    }

    if (_canApplyResult(operationId)) {
      _setUnauthenticated();
    }
  }

  void _onSessionEvent(SessionEvent event) {
    if (_isDisposed) {
      return;
    }

    switch (event) {
      case SessionEvent.expired:
        unawaited(_handleExpiredSession());
    }
  }

  Future<void> _handleExpiredSession() async {
    ++_operationId;

    _isRestoring = false;
    _isLoggingOut = false;

    _setUnauthenticated();

    try {
      await _authRepository.clearSession();
    } catch (_) {
      // El interceptor ya intentó eliminar el token.
      // La sesión se elimina de la memoria aunque falle un segundo intento.
    }
  }

  bool _canApplyResult(int operationId) {
    return !_isDisposed && operationId == _operationId;
  }

  void _setChecking() {
    _status = AuthStatus.checking;
    _user = null;
    _errorMessage = null;
    _sessionActionErrorMessage = null;
    _requiresPasswordChange = false;

    _notifySafely();
  }

  void _setAuthenticated(User user) {
    _status = AuthStatus.authenticated;
    _user = user;
    _errorMessage = null;
    _sessionActionErrorMessage = null;

    _notifySafely();
  }

  void _setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    _user = null;
    _errorMessage = null;
    _sessionActionErrorMessage = null;
    _requiresPasswordChange = false;

    _notifySafely();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _user = null;
    _errorMessage = message;
    _sessionActionErrorMessage = null;
    _requiresPasswordChange = false;

    _notifySafely();
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    ++_operationId;

    unawaited(_sessionSubscription.cancel());

    super.dispose();
  }
}
