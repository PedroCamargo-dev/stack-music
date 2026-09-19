import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Tela de login manual (conexão Navidrome: URL, usuário, senha),
/// construída por último conforme o pedido. Valida com ping Subsonic.
class LoginScreen extends StatefulWidget {
 const LoginScreen({super.key});

 @override
 State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
 final _formKey = GlobalKey<FormState>();
 final _urlController = TextEditingController(text: 'https://');
 final _userController = TextEditingController();
 final _passController = TextEditingController();
 bool _obscure = true;
 bool _connecting = false;
 String? _error;

 @override
 void dispose() {
 _urlController.dispose();
 _userController.dispose();
 _passController.dispose();
 super.dispose();
 }

 Future<void> _connect() async {
 if (!_formKey.currentState!.validate()) return;
 setState(() { _connecting = true; _error = null; });
 final app = context.read<AppState>();
 try {
 await app.connect(
 _urlController.text.trim(),
 _userController.text.trim(),
 _passController.text,
 );
 if (mounted) {
 Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
 }
 } catch (e) {
 setState(() {
 _connecting = false;
 _error = switch (e.toString()) {
 String s when s.contains('Connection') || s.contains('timeout') =>
 'Não foi possível conectar ao servidor. Verifique a URL e sua conexão.',
 _ => 'Falha na autenticação. Verifique usuário e senha.',
 };
 });
 }
 }

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 final textP = AppColors.textPrimary(b);
 final textS = AppColors.textSecondary(b);

 return Scaffold(
 body: SafeArea(
 child: Center(
 child: SingleChildScrollView(
 padding: const EdgeInsets.all(24),
 child: Form(
 key: _formKey,
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // Logo
 const Icon(Icons.graphic_eq, size: 64, color: AppColors.primary),
 const SizedBox(height: 8),
 Text('Stack Music',
 textAlign: TextAlign.center,
 style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textP)),
 Text('Conecte ao seu servidor Navidrome',
 textAlign: TextAlign.center,
 style: TextStyle(fontSize: 13, color: textS)),
 const SizedBox(height: 32),
 TextFormField(
 controller: _urlController,
 keyboardType: TextInputType.url,
 autofillHints: const [AutofillHints.url],
 decoration: InputDecoration(
 labelText: 'URL do servidor',
 hintText: 'https://music.exemplo.com',
 prefixIcon: const Icon(Icons.dns_outlined),
 filled: true,
 fillColor: AppColors.surface2(b),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
 ),
 validator: (v) =>
 (v == null || !v.startsWith('http')) ? 'Informe uma URL válida (https://...)' : null,
 ),
 const SizedBox(height: 12),
 TextFormField(
 controller: _userController,
 autofillHints: const [AutofillHints.username],
 decoration: InputDecoration(
 labelText: 'Usuário',
 prefixIcon: const Icon(Icons.person_outline),
 filled: true,
 fillColor: AppColors.surface2(b),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
 ),
 validator: (v) =>
 (v == null || v.trim().isEmpty) ? 'Informe o usuário' : null,
 ),
 const SizedBox(height: 12),
 TextFormField(
 controller: _passController,
 obscureText: _obscure,
 autofillHints: const [AutofillHints.password],
 decoration: InputDecoration(
 labelText: 'Senha',
 prefixIcon: const Icon(Icons.lock_outline),
 suffixIcon: IconButton(
 icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
 onPressed: () => setState(() => _obscure = !_obscure),
 ),
 filled: true,
 fillColor: AppColors.surface2(b),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
 ),
 validator: (v) =>
 (v == null || v.isEmpty) ? 'Informe a senha' : null,
 ),
 if (_error != null) ...[
 const SizedBox(height: 16),
 Text(_error!,
 textAlign: TextAlign.center,
 style: const TextStyle(color: AppColors.danger, fontSize: 13)),
 ],
 const SizedBox(height: 24),
 FilledButton.icon(
 style: FilledButton.styleFrom(
 backgroundColor: AppColors.primary,
 foregroundColor: Colors.black,
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 ),
 onPressed: _connecting ? null : _connect,
 icon: _connecting
 ? const SizedBox(
 width: 18, height: 18,
 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
 : const Icon(Icons.login),
 label: Text(_connecting ? 'Conectando...' : 'Conectar'),
 ),
 ],
 ),
 ),
 ),
 ),
 ),
 );
 }
}

/// Host usado pelo LoginGate no main.dart.
class LoginScreenHost extends StatelessWidget {
 const LoginScreenHost({super.key});

 @override
 Widget build(BuildContext context) {
 final configured = context.watch<AppState>().isConfigured;
 return configured ? const SizedBox.shrink() : const LoginScreen();
 }
}