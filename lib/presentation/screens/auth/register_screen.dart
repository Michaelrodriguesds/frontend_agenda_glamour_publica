import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _businessCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool  _obscure  = true;
  bool  _loading  = false;
  String? _error;

  @override
  void dispose() {
    _businessCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    await ref.read(authProvider.notifier).register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      businessName: _businessCtrl.text.trim(),
    );

    final state = ref.read(authProvider);
    if (!mounted) return;
    setState(() { _loading = false; _error = state.error; });
    // Se deu certo, o _AuthGate (main.dart) detecta authenticated e navega
    // sozinho pro onboarding — não precisa navegar manualmente aqui.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Criar conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comece seu teste grátis de 30 dias',
                  style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sem cartão de crédito. Ao final do período, entre em contato para continuar usando.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 32),

                const Text('Nome do negócio', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _businessCtrl,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: 'Ex: Studio da Ana',
                    prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.textMuted),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome do negócio' : null,
                ),
                const SizedBox(height: 16),

                const Text('E-mail', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: 'seuemail@exemplo.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                    if (!v.contains('@') || !v.contains('.')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('Senha', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
                ),
                const SizedBox(height: 16),

                const Text('Confirmar senha', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passConfirmCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
                  ),
                  validator: (v) => v != _passCtrl.text ? 'As senhas não coincidem' : null,
                ),
                const SizedBox(height: 12),

                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.rose, fontSize: 12)),
                  ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CRIAR CONTA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
