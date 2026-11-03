import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/trial_gate.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/refresh_provider.dart';

// Seu WhatsApp (DDI+DDD, só dígitos). Defina no build:
//   --dart-define=SUPPORT_WHATSAPP=5521999999999
const _supportWhatsapp =
    String.fromEnvironment('SUPPORT_WHATSAPP', defaultValue: '5521999999999');

class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessId = TrialGate.instance.businessId ?? '—';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⏳', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 20),
                const Text(
                  'Seu período grátis acabou',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Entre em contato informando o ID abaixo para liberar mais 30 dias de acesso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Text('SEU ID', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      SelectableText(
                        businessId,
                        style: const TextStyle(color: AppColors.rose, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                ElevatedButton.icon(
                  onPressed: () async {
                    final msg = Uri.encodeComponent('Olá! Meu ID é $businessId e quero liberar mais 30 dias de acesso.');
                    final uri = Uri.parse('https://wa.me/$_supportWhatsapp?text=$msg');
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Não consegui abrir o WhatsApp. Envie mensagem informando seu ID.'),
                        ));
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('FALAR NO WHATSAPP'),
                ),
                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: () {
                    TrialGate.instance.clear();
                    ref.read(refreshProvider.notifier).state++;
                  },
                  child: const Text('JÁ FUI LIBERADO — TENTAR NOVAMENTE'),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  child: const Text('Sair', style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
