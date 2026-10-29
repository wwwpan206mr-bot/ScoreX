import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreXAuth extends ChangeNotifier {
  ScoreXAuth._();
  static final instance = ScoreXAuth._();
  bool ready = false;
  bool configured = false;
  bool busy = false;
  String? error;
  String? _localUid;
  String? _webClientId;
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _subscription;
  User? get user => _auth?.currentUser;
  String? get uid => user?.uid ?? _localUid;
  bool get guest => user?.isAnonymous ?? (_localUid != null);
  bool get signedIn => uid != null;
  bool get deviceGuest => user == null && _localUid != null;
  bool get googleAvailable => configured && _webClientId?.isNotEmpty == true;
  String get name => guest ? 'Cricket fan' : user?.displayName ?? 'ScoreX member';

  Future<void> initialize() async {
    if (ready) return;
    final prefs = await SharedPreferences.getInstance();
    _localUid = prefs.getString('scorex_device_guest_uid');
    try {
      final config = jsonDecode(await rootBundle.loadString('assets/branding/firebase_config.json')) as Map<String, dynamic>;
      if (['apiKey', 'appId', 'messagingSenderId', 'projectId'].every((key) => config[key] is String && (config[key] as String).isNotEmpty)) {
        await Firebase.initializeApp(options: FirebaseOptions(
          apiKey: config['apiKey'] as String,
          appId: config['appId'] as String,
          messagingSenderId: config['messagingSenderId'] as String,
          projectId: config['projectId'] as String,
        ));
        _webClientId = config['googleWebClientId'] as String?;
        _auth = FirebaseAuth.instance;
        configured = true;
        if (user != null) await _clearLocal();
        _subscription = _auth!.userChanges().listen((_) => notifyListeners());
      }
    } catch (_) {
      // Scores and a clearly identified device guest remain accessible.
    }
    ready = true;
    notifyListeners();
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    busy = true; error = null; notifyListeners();
    try { await action(); }
    on FirebaseAuthException catch (e) {
      error = switch (e.code) {
        'operation-not-allowed' => 'This sign-in provider is disabled. Enable it in Firebase Authentication, or continue as a guest.',
        'admin-restricted-operation' => 'Firebase has restricted account creation. Enable this provider and check Authentication user actions, or continue as a guest.',
        'account-exists-with-different-credential' => 'Sign in with your existing account method first.',
        'invalid-credential' => 'Email or password is incorrect.',
        'email-already-in-use' => 'This email already has an account. Please sign in.',
        'weak-password' => 'Use a stronger password with at least 6 characters.',
        'invalid-email' => 'Enter a valid email address.',
        'network-request-failed' => 'Check your connection and try again.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'requires-recent-login' => 'Sign in again before deleting your account.',
        'credential-already-in-use' => 'This Google account is already registered. Use Sign in.',
        _ => 'Unable to complete this request (${e.code}).',
      };
    } on PlatformException catch (e) {
      final detail = '${e.message ?? ''} ${e.details ?? ''}';
      error = e.code == 'network_error'
          ? 'Google sign-in could not connect. Check your internet connection.'
          : detail.contains('10:') || detail.contains('DEVELOPER_ERROR')
              ? 'Google sign-in setup mismatch. Register this APK signing SHA-1 in Firebase and check its Android package and Web client ID.'
              : 'Google sign-in failed (${e.code}). Check the Google provider and this build’s signing SHA-1 in Firebase. You can continue as a guest.';
    } catch (_) { error = 'Unable to complete this request. Please try again.'; }
    finally { busy = false; notifyListeners(); }
  }

  Future<void> _enterDeviceGuest() async {
    final prefs = await SharedPreferences.getInstance();
    _localUid ??= 'device_guest_' + List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString('scorex_device_guest_uid', _localUid!);
  }

  Future<void> enterGuest() => run(() async {
    if (user != null || _localUid != null) return;
    if (configured) {
      try {
        await _auth!.signInAnonymously().timeout(const Duration(seconds: 12));
        await _clearLocal();
        return;
      } catch (_) {
        // Public scores remain accessible without a cloud account.
        // This local identity never grants authenticated Firebase permissions.
      }
    }
    await _enterDeviceGuest();
  });

  Future<void> email(String email, String password, {required bool register, String name = ''}) => run(() async {
    if (!configured) throw StateError('Authentication is not configured');
    if (register) {
      final current = user;
      final credential = EmailAuthProvider.credential(email: email.trim(), password: password);
      final result = current != null && current.isAnonymous
          ? await current.linkWithCredential(credential)
          : await _auth!.createUserWithEmailAndPassword(email: email.trim(), password: password);
      if (name.trim().isNotEmpty) await result.user!.updateDisplayName(name.trim());
      try { await result.user!.sendEmailVerification(); }
      catch (_) { error = 'Account created. Use Resend verification from your profile.'; }
    } else {
      await _auth!.signInWithEmailAndPassword(email: email.trim(), password: password);
    }
    await _clearLocal();
  });

  Future<AuthCredential?> _googleCredential() async {
    final signIn = GoogleSignIn(
      serverClientId: _webClientId,
      scopes: const ['email'],
    );
    final account = await signIn.signIn();
    if (account == null) return null; // User cancelled the account picker.
    final tokens = await account.authentication;
    if ((tokens.idToken == null || tokens.idToken!.isEmpty) &&
        (tokens.accessToken == null || tokens.accessToken!.isEmpty)) {
      throw StateError('Google returned no authentication token. Check the Web OAuth client ID.');
    }
    return GoogleAuthProvider.credential(
      accessToken: tokens.accessToken,
      idToken: tokens.idToken,
    );
  }

  Future<void> google({bool upgrade = false}) => run(() async {
    if (!googleAvailable) {
      error = 'Google sign-in is not configured in this build. Check firebase_config.json and the Web OAuth client ID.';
      return;
    }
    try {
      final credential = await _googleCredential();
      if (credential == null) return;
      if (upgrade && user?.isAnonymous == true) {
        await user!.linkWithCredential(credential);
      } else {
        await _auth!.signInWithCredential(credential);
      }
      await _clearLocal();
    } on FirebaseAuthException catch (e) {
      // Google errors need Google-specific guidance; do not show the email/password message.
      error = switch (e.code) {
        'account-exists-with-different-credential' =>
          'এই Gmail দিয়ে আগে অন্য পদ্ধতিতে অ্যাকাউন্ট খোলা হয়েছে। আগে সেই পদ্ধতিতে লগইন করুন।',
        'credential-already-in-use' =>
          'এই Google অ্যাকাউন্টটি আগে থেকেই ScoreX-এ যুক্ত আছে। Guest upgrade-এর বদলে Google দিয়ে Sign in করুন।',
        'invalid-credential' || 'user-token-expired' =>
          'Google credential গ্রহণ করা যায়নি। Google provider, Web OAuth client ID এবং এই APK-এর SHA-1/SHA-256 মিলিয়ে দেখুন।',
        'operation-not-allowed' =>
          'Firebase Authentication-এ Google provider চালু নেই।',
        'network-request-failed' =>
          'ইন্টারনেট সংযোগ পরীক্ষা করে আবার Google দিয়ে লগইন করুন।',
        'too-many-requests' =>
          'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।',
        _ => 'Google login ব্যর্থ হয়েছে (' + e.code + ')। Firebase Authentication-এর Google provider ও OAuth configuration পরীক্ষা করুন।',
      };
    }
  });

  Future<void> reset(String email) => run(() async {
    await _auth!.sendPasswordResetEmail(email: email.trim());
  });

  Future<void> verify() => run(() async {
    await user!.sendEmailVerification();
  });

  Future<void> reload() => run(() async { await user?.reload(); });

  Future<void> _clearLocal() async {
    _localUid = null;
    await (await SharedPreferences.getInstance()).remove('scorex_device_guest_uid');
  }

  Future<void> logout() => run(() async {
    await _auth?.signOut();
    try {
      if (configured && _webClientId?.isNotEmpty == true) await GoogleSignIn(serverClientId: _webClientId).signOut();
    } finally {
      await _clearLocal();
    }
  });

  Future<void> delete(String password) => run(() async {
    final current = user;
    if (current != null && !current.isAnonymous) {
      if (current.providerData.any((p) => p.providerId == 'google.com')) {
        final credential = await _googleCredential();
        if (credential == null) return;
        await current.reauthenticateWithCredential(credential);
      } else {
        await current.reauthenticateWithCredential(EmailAuthProvider.credential(email: current.email!, password: password));
      }
    }
    await current?.delete();
    await _clearLocal();
  });

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
