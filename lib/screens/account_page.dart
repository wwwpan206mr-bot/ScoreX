import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/scorex_auth.dart';

class ScoreXAuthGate extends StatefulWidget {
  const ScoreXAuthGate({super.key, required this.child});
  final Widget child;
  @override
  State<ScoreXAuthGate> createState() => _ScoreXAuthGateState();
}

class _ScoreXAuthGateState extends State<ScoreXAuthGate> {
  final auth = ScoreXAuth.instance;
  @override
  void initState() { super.initState(); auth.initialize(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: auth, builder: (_, __) {
    if (!auth.ready) return const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('ScoreX'), SizedBox(height: 16), CircularProgressIndicator()])));
    return auth.signedIn ? widget.child : const ScoreXAccountPage();
  });
}

class ScoreXAccountPage extends StatefulWidget {
  const ScoreXAccountPage({super.key});
  @override
  State<ScoreXAccountPage> createState() => _ScoreXAccountPageState();
}

class _ScoreXAccountPageState extends State<ScoreXAccountPage> {
  final auth = ScoreXAuth.instance;
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _showPassword = false;
  String? _notice;
  @override
  void dispose() { _email.dispose(); _password.dispose(); _name.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await auth.email(_email.text, _password.text, register: _register, name: _name.text);
    if (mounted) setState(() => _notice = _register && auth.user != null ? 'Account created. Check your email for verification.' : null);
  }

  Future<void> _reset() async {
    if (!_email.text.trim().contains('@')) {
      setState(() => _notice = 'Enter your email address first.');
      return;
    }
    await auth.reset(_email.text);
    if (mounted) setState(() => _notice = auth.error == null ? 'If an account exists, a reset email will be sent.' : null);
  }

  Future<void> _delete() async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete your account?'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('This permanently deletes your ScoreX sign-in account. You can still watch scores as a guest.'),
        if (auth.user?.providerData.any((p) => p.providerId == 'password') == true)
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (confirmed == true) await auth.delete(password.text);
    password.dispose();
  }

  Widget _avatar() {
    final photo = auth.user?.photoURL;
    return CircleAvatar(radius: 42, backgroundColor: const Color(0xFF1B6049),
      child: photo == null ? const Icon(Icons.person_rounded, size: 48, color: Color(0xFFFFC857))
        : ClipOval(child: Image.network(photo, width: 84, height: 84, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 48, color: Color(0xFFFFC857)))));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: auth, builder: (_, __) {
    final member = auth.user != null && !auth.guest;
    return Scaffold(
      appBar: AppBar(title: const Text('ScoreX • My profile')),
      body: Align(alignment: Alignment.topCenter, child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ListView(padding: const EdgeInsets.all(24), children: [
        Center(child: _avatar()),
        const SizedBox(height: 14),
        Text(auth.signedIn ? auth.name : 'Welcome to ScoreX',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (auth.signedIn) ...[
          Center(child: Text(auth.guest ? 'Guest account' : auth.user?.email ?? 'Member')),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('YOUR USER UID', style: TextStyle(fontSize: 11, letterSpacing: 1.4)),
              const SizedBox(height: 8),
              SelectableText(auth.uid!, style: const TextStyle(fontWeight: FontWeight.w700)),
              TextButton.icon(onPressed: () {
                Clipboard.setData(ClipboardData(text: auth.uid!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UID copied')));
              }, icon: const Icon(Icons.copy, size: 16), label: const Text('Copy UID')),
              if (auth.deviceGuest) const Text('Device-only guest ID. It is not a cloud account and can be lost if app data is cleared.',
                style: TextStyle(fontSize: 12)),
            ]))),
        ],
        if (auth.busy) const LinearProgressIndicator(),
        if (auth.error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(auth.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (_notice != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_notice!)),
        if (member) ...[
          ListTile(leading: Icon(auth.user!.emailVerified ? Icons.verified : Icons.mark_email_unread_outlined),
            title: Text(auth.user!.emailVerified ? 'Email verified' : 'Email verification pending')),
          if (!auth.user!.emailVerified)
            TextButton(onPressed: auth.busy ? null : auth.verify, child: const Text('Resend verification email')),
          TextButton(onPressed: auth.busy ? null : auth.reload, child: const Text('Refresh profile')),
          const Text('Your Google account photo appears when you sign in with Google. Email/password accounts use the default avatar.'),
        ] else ...[
          const SizedBox(height: 16),
          Text(_register ? 'Create your account' : 'Sign in with email',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          if (!auth.configured) const Padding(padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Online accounts are not available in this build yet. Continue as a guest to watch scores.')),
          AutofillGroup(child: Form(key: _form, child: Column(spacing: 14, children: [
            if (_register) TextFormField(controller: _name, autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.person_outline)),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter your name' : null),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email_rounded)),
              validator: (value) => value == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim()) ? 'Enter a valid email' : null),
            TextFormField(controller: _password, obscureText: !_showPassword,
              autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
              decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility))),
              validator: (value) => value == null || value.length < 6 ? 'Use at least 6 characters' : null),
          ]))),
          const SizedBox(height: 20),
          FilledButton(onPressed: !auth.configured || auth.busy ? null : _submit,
            child: Text(_register ? 'Create account' : 'Sign in')),
          TextButton(onPressed: auth.busy ? null : () => setState(() { _register = !_register; _notice = null; }),
            child: Text(_register ? 'Already registered? Sign in' : 'New here? Create account')),
          TextButton(onPressed: !auth.configured || auth.busy ? null : _reset, child: const Text('Forgot password?')),
          OutlinedButton.icon(onPressed: !auth.googleAvailable || auth.busy ? null : () => auth.google(upgrade: _register),
            icon: const Icon(Icons.account_circle_outlined), label: Text(_register && auth.guest ? 'Upgrade guest with Google' : 'Continue with Google')),
          if (auth.configured && !auth.googleAvailable) const Text('Google sign-in is not available yet. Use email or continue as a guest.'),
          if (auth.guest && !auth.deviceGuest) const Text('Creating a new account upgrades a cloud guest with the same UID. Signing into an existing account uses that account’s UID.'),
          const SizedBox(height: 8),
          if (!auth.signedIn) TextButton.icon(onPressed: auth.busy ? null : auth.enterGuest,
            icon: const Icon(Icons.person_outline), label: const Text('Continue as guest')),
        ],
        if (auth.signedIn) ...[
          const SizedBox(height: 24),
          OutlinedButton(onPressed: auth.busy ? null : auth.logout, child: const Text('Sign out')),
          TextButton(onPressed: auth.busy ? null : _delete,
            child: Text(auth.guest ? 'Delete guest account' : 'Delete account')),
        ],
      ]))),
    );
  });
}
