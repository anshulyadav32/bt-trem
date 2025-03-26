import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

// Events
abstract class AuthEvent {}

class CheckAuthEvent extends AuthEvent {}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  SignInEvent(this.email, this.password);
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String username;

  SignUpEvent(this.email, this.password, this.username);
}

class SignOutEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final Map<String, dynamic> userData;

  UpdateProfileEvent(this.userData);
}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final UserModel userProfile;

  Authenticated(this.user, this.userProfile);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<SignInEvent>(_onSignIn);
    on<SignUpEvent>(_onSignUp);
    on<SignOutEvent>(_onSignOut);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profileData = await _authService.getUserProfile(user.uid);
        final userProfile = UserModel.fromJson(profileData, user.uid);
        emit(Authenticated(user, userProfile));
            } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('Authentication check failed: $e'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
      
      final user = credential.user;
      if (user != null) {
        final profileData = await _authService.getUserProfile(user.uid);
        final userProfile = UserModel.fromJson(profileData, user.uid);
        emit(Authenticated(user, userProfile));
            } else {
        emit(AuthError('Authentication failed'));
      }
    } catch (e) {
      emit(AuthError('Sign in failed: $e'));
    }
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Check if username exists
      final usernameExists = await _authService.usernameExists(event.username);
      if (usernameExists) {
        emit(AuthError('Username already exists. Please choose another.'));
        return;
      }
      
      final credential = await _authService.registerWithEmailAndPassword(
        event.email,
        event.password,
        event.username,
      );
      
      final user = credential.user;
      if (user != null) {
        final profileData = await _authService.getUserProfile(user.uid);
        final userProfile = UserModel.fromJson(profileData, user.uid);
        emit(Authenticated(user, userProfile));
            } else {
        emit(AuthError('Registration failed'));
      }
    } catch (e) {
      emit(AuthError('Registration failed: $e'));
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Sign out failed: $e'));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateProfileEvent event, Emitter<AuthState> emit) async {
    try {
      final currentState = state;
      if (currentState is Authenticated) {
        await _authService.updateUserProfile(
          currentState.user.uid,
          event.userData,
        );
        
        final updatedProfile = await _authService.getUserProfile(currentState.user.uid);
        final userProfile = UserModel.fromJson(updatedProfile, currentState.user.uid);
        emit(Authenticated(currentState.user, userProfile));
            }
    } catch (e) {
      emit(AuthError('Failed to update profile: $e'));
    }
  }
}
