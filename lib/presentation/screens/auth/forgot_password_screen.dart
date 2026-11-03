import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _service = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _codeCtrl  = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _codeSent = false;
  bool _loading  = false;
  bool _done     = false;
  String? _error;

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _service.forgotPassword(_emailCtrl.text.trim());
      setState(() { _codeSent = true; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _service.resetPassword(
        email: _emailCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        newPassword: _newPassCtrl.text,
      );
      setState(() { _done = true; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recuperar senha'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_done) ...[
                  const Icon(Icons.check_circle_outline, color: AppColors.green, size: 48),
                  const SizedBox(height: 16),
                  const Text('Senha redefinida!',
                      style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Volte e faça login com sua nova senha.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('VOLTAR PARA O LOGIN'),
                  ),
                ] else ...[
                  Text(
                    _codeSent ? 'Digite o código recebido' : 'Informe seu e-mail',
                    style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _codeSent
                        ? 'Enviamos um código de 6 dígitos para ${_emailCtrl.text.trim()}. Ele expira em 15 minutos.'
                        : 'Vamos enviar um código de verificação para redefinir sua senha.',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  const Text('E-mail', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: !_codeSent,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(
                      hintText: 'seuemail@exemplo.com',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
                  ),

                  if (_codeSent) ...[
                    const SizedBox(height: 16),
                    const Text('Código recebido por e-mail', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        hintText: '000000',
                        prefixIcon: Icon(Icons.pin_outlined, color: AppColors.textMuted),
                      ),
                      validator: (v) => (v == null || v.trim().length != 6) ? 'Código de 6 dígitos' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Nova senha', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _newPassCtrl,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(
                        hintText: 'mínimo 6 caracteres',
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
                    ),
                  ],

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
                    onPressed: _loading ? null : (_codeSent ? _resetPassword : _sendCode),
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_codeSent ? 'REDEFINIR SENHA' : 'ENVIAR CÓDIGO'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
