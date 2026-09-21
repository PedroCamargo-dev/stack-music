import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Tela de Login Premium — Reconstrução Visual Completa
/// - Background imersivo com gradiente + blur
/// - Glassmorphism nos campos
/// - Credenciais padrão do usuário pré-preenchidas
/// - Sem menu flutuante fantasma
/// - Validação real com feedback visual claro
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController(text: 'http://localhost:4533/');
  final _userController = TextEditingController(text: 'pedrocamargo');
  final _passController = TextEditingController(text: 'Pedro3008@');
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
    setState(() {
      _connecting = true;
      _error = null;
    });
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
            'Não foi possível conectar ao servidor.\nVerifique a URL e sua conexão.',
          _ => 'Falha na autenticação.\nVerifique usuário e senha.',
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND IMERSIVO — Gradiente + Blur decorativo
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.playerGradientStart,
                  AppColors.surface(b),
                  AppColors.playerGradientEnd,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Círculos decorativos desfocados (efeito premium)
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryAccent.withValues(alpha: 0.1),
              ),
            ),
          ),

          // CONTEÚDO PRINCIPAL
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LOGO + TÍTULO
                      const Icon(Icons.graphic_eq,
                          size: 72, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text('Stack Music',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: textP,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text('Conecte ao seu servidor Navidrome',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: textS)),
                      const SizedBox(height: 48),

                      // CAMPOS COM GLASSMORPHISM
                      _GlassField(
                        controller: _urlController,
                        label: 'URL do servidor',
                        hint: 'http://localhost:4533/',
                        icon: Icons.dns_outlined,
                        keyboard: TextInputType.url,
                        validator: (v) => (v == null || !v.startsWith('http'))
                            ? 'Informe uma URL válida (http://...)'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _GlassField(
                        controller: _userController,
                        label: 'Usuário',
                        hint: 'pedrocamargo',
                        icon: Icons.person_outline,
                        autofill: AutofillHints.username,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe o usuário'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _GlassField(
                        controller: _passController,
                        label: 'Senha',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscure: _obscure,
                        autofill: AutofillHints.password,
                        suffix: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textS,
                              size: 20),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? 'Informe a senha'
                                : null,
                      ),

                      // ERRO
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                      height: 1.4)),
                            ),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // BOTÃO CONECTAR
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _connecting ? null : _connect,
                        icon: _connecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.black))
                            : const Icon(Icons.login, size: 22),
                        label: Text(
                            _connecting ? 'Conectando...' : 'Conectar',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de texto com efeito glassmorphism premium
class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final bool obscure;
  final Widget? suffix;
  final String? autofill;

  const _GlassField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.validator,
    this.obscure = false,
    this.suffix,
    this.autofill,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      autofillHints: autofill != null ? [autofill!] : null,
      style: TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary(b),
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.textSecondary(b).withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: AppColors.primary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface2(b).withValues(alpha: 0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: AppColors.surface2(b).withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: AppColors.primary.withValues(alpha: 0.6), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.danger)),
      ),
      validator: validator,
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