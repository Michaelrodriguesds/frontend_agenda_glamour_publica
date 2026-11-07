import 'package:flutter/material.dart';
import '../../widgets/max_width.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../auth/register_screen.dart';
import '../auth/forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool  _obscure  = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final loading = state.status == AuthStatus.checking;

    return MaxWidth(
      // PC/notebook: largura de cartão; no celular nada muda.
      maxWidth: 460,
      child: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ────────────────────
                  const Center(
                    child: Text('🌸', style: TextStyle(fontSize: 56)),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'BelaAgenda',
                      style: TextStyle(
                        color:      AppColors.text,
                        fontSize:   26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Agenda para negócios de beleza',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── E-mail ─────────────────
                  Text('E-mail', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller:  _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppColors.text),
                    decoration:  InputDecoration(
                      hintText:    'seuemail@exemplo.com',
                      prefixIcon:  Icon(Icons.email_outlined, color: AppColors.textMuted),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o e-mail' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Senha ───────────────────
                  Text('Senha', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller:   _passCtrl,
                    obscureText:  _obscure,
                    style: TextStyle(color: AppColors.text),
                    decoration:   InputDecoration(
                      hintText:    '••••••••',
                      prefixIcon:  Icon(Icons.lock_outline, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: Text('Esqueci minha senha', style: TextStyle(color: AppColors.lavender, fontSize: 12)),
                    ),
                  ),

                  // ── Erro ────────────────────
                  if (state.error != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:        AppColors.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:       Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        state.error!,
                        style: TextStyle(color: AppColors.rose, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // ── Botão ───────────────────
                  ElevatedButton(
                    onPressed: loading ? null : _login,
                    child: loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('ENTRAR'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: 'Não tem conta? ',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Criar conta grátis',
                              style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
