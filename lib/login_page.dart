import 'package:firebase_crudnote/auth_service.dart';
import 'package:firebase_crudnote/home_page.dart';
import 'package:firebase_crudnote/register_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService auth = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter an email address and password.');
      return;
    }

    setState(() => loading = true);
    final user = await auth.signInWithEmail(email, password);
    if (!mounted) return;
    setState(() => loading = false);

    if (user == null) {
      _showMessage('Invalid email or password.');
      return;
    }

    if (!user.emailVerified) {
      _showMessage('Please verify your email before logging in.');
      await auth.signOut();
      return;
    }

    _openHomePage();
  }

  Future<void> _loginWithGoogle() async {
    setState(() => loading = true);
    final user = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => loading = false);

    if (user == null) {
      _showMessage('Google sign-in was cancelled or failed.');
      return;
    }
    _openHomePage();
  }

  void _openHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login | Felecilda Auth/Google Sign')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loading ? null : _login,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login with Email'),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loading ? null : _loginWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: loading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        ),
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
