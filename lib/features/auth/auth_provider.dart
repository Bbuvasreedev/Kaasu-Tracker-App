import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for Supabase Auth client (`GoTrueClient`)
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return Supabase.instance.client.auth;
});

/// Stream provider for auth state changes
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseAuthProvider).onAuthStateChange;
});

/// Provider for AuthNotifier wrapping Supabase auth functions
final authProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier(ref.watch(supabaseAuthProvider));
});

/// AuthNotifier wraps Supabase auth client to handle user sign up, sign in, and sign out.
class AuthNotifier {
  final GoTrueClient _auth;

  AuthNotifier(this._auth);

  /// Signs up a user using email and password.
  Future<AuthResponse> signUp(String email, String password) async {
    return await _auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Signs in a user using email and password.
  Future<AuthResponse> signIn(String email, String password) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user session.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Gets the current active session.
  Session? get currentSession => _auth.currentSession;

  /// Gets the currently authenticated user.
  User? get currentUser => _auth.currentUser;
}
