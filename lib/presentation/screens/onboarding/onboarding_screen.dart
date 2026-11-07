import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/business_config_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../providers/business_config_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/max_width.dart';

// Paleta de cores que o usuário pode escolher para sua marca
const _colorPresets = [
  '#B47FD4', // lavanda (padrão)
  '#E8527A', // rose
  '#4ECBA0', // verde
  '#F0C060', // dourado
  '#98CFFF', // azul
  '#FF9898', // salmão
];

class OnboardingScreen extends ConsumerStatefulWidget {
  /// true = primeira configuração (não pode "cancelar" sem salvar);
  /// false = editando depois, pelo menu de configurações.
  final bool isFirstSetup;
  const OnboardingScreen({super.key, this.isFirstSetup = true});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl    = TextEditingController();
  String _logo = ''; // data URL (galeria) ou link
  final _location1Ctrl    = TextEditingController();
  final _location2Ctrl    = TextEditingController();

  bool _hasSecondLocation = false;
  String _primaryColor = _colorPresets.first;
  final List<BusinessService> _services = [];

  final _newServiceNameCtrl  = TextEditingController();
  final _newServicePriceCtrl = TextEditingController();

  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _meInfo;

  @override
  void initState() {
    super.initState();
    final config = ref.read(businessConfigProvider).config;
    _businessNameCtrl.text = config.businessName;
    _ownerNameCtrl.text    = config.ownerName;
    _logo                  = config.logoUrl;
    _primaryColor          = config.primaryColor.isNotEmpty ? config.primaryColor : _colorPresets.first;
    _services.addAll(config.services);
    if (config.locations.isNotEmpty) _location1Ctrl.text = config.locations[0];
    if (config.locations.length > 1) {
      _hasSecondLocation = true;
      _location2Ctrl.text = config.locations[1];
    }
    if (!widget.isFirstSetup) _loadMeInfo();
  }

  /// Abre a galeria, reduz a imagem (256px) e guarda como data URL.
  Future<void> _pickLogo() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final lower = file.path.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'png'
          : lower.endsWith('.webp') ? 'webp' : 'jpeg';
      if (!mounted) return;
      setState(() => _logo = 'data:image/$mime;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não consegui abrir a galeria.')),
      );
    }
  }

  Future<void> _loadMeInfo() async {
    try {
      final me = await AuthService().getMe();
      if (mounted) setState(() => _meInfo = me);
    } catch (_) {
      // Não é crítico — a tela funciona normalmente sem esse card
    }
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _location1Ctrl.dispose();
    _location2Ctrl.dispose();
    _ownerNameCtrl.dispose();
    _newServiceNameCtrl.dispose();
    _newServicePriceCtrl.dispose();
    super.dispose();
  }

  void _addService() {
    final name = _newServiceNameCtrl.text.trim();
    if (name.isEmpty) return;
    final price = double.tryParse(_newServicePriceCtrl.text.replaceAll(',', '.')) ?? 0;
    setState(() {
      _services.add(BusinessService(name: name, price: price));
      _newServiceNameCtrl.clear();
      _newServicePriceCtrl.clear();
    });
  }

  // Pergunta em quantos dias a cliente deve refazer o serviço [i].
  // Vazio ou 0 = não lembra. Aceita de 0 a 365 (o servidor confere de novo).
  Future<void> _editReturnDays(int i) async {
    final s = _services[i];
    final ctrl = TextEditingController(text: s.returnDays > 0 ? '${s.returnDays}' : '');
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Retorno: ${s.name}', style: TextStyle(color: AppColors.text, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Depois de quantos dias a cliente deve voltar? Deixe vazio para não lembrar.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Ex.: 15', suffixText: 'dias'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.pop(ctx, v < 0 ? 0 : (v > 365 ? 365 : v));
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    // (o controller não é descartado aqui: o diálogo ainda está fechando
    // com animação e usaria um controller já descartado.)
    if (days == null || !mounted) return;
    setState(() => _services[i] = s.copyWith(returnDays: days));
  }

  Future<void> _save() async {
    final locations = <String>[
      if (_location1Ctrl.text.trim().isNotEmpty) _location1Ctrl.text.trim(),
      if (_hasSecondLocation && _location2Ctrl.text.trim().isNotEmpty) _location2Ctrl.text.trim(),
    ];

    if (locations.isEmpty) {
      setState(() => _error = 'Informe pelo menos 1 local de atendimento');
      return;
    }
    if (_services.isEmpty) {
      setState(() => _error = 'Adicione pelo menos 1 serviço que você oferece');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      final config = BusinessConfig(
        businessName: _businessNameCtrl.text.trim(),
        ownerName:    _ownerNameCtrl.text.trim(),
        logoUrl:      _logo,
        primaryColor: _primaryColor,
        services:     _services,
        locations:    locations,
      );
      await ref.read(businessConfigProvider.notifier).save(config);
      if (!mounted) return;
      if (widget.isFirstSetup) {
        // _AuthGate detecta config.needsOnboarding == false e navega sozinho
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaxWidth(
      // PC/notebook: largura de cartão; no celular nada muda.
      maxWidth: 720,
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isFirstSetup,
        title: Text(widget.isFirstSetup ? 'Configure seu negócio' : 'Configurações do negócio'),
        actions: [
          if (widget.isFirstSetup)
            TextButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: Text('Sair', style: TextStyle(color: AppColors.textMuted)),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFirstSetup) ...[
                Text(
                  'Falta pouco! Personalize sua agenda antes de começar.',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
              ],

              if (!widget.isFirstSetup && _meInfo != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SEU ID', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.5)),
                          Text(
                            _meInfo!['planStatus'] == 'blocked' ? 'BLOQUEADO' : 'ATIVO',
                            style: TextStyle(
                              color: _meInfo!['planStatus'] == 'blocked' ? AppColors.rose : AppColors.green,
                              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _meInfo!['businessId']?.toString() ?? '—',
                        style: TextStyle(color: AppColors.rose, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Envie este ID caso precise pedir a liberação de mais 30 dias.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Nome do negócio ──────────────────────────
              _SectionTitle('Nome do negócio'),
              TextField(
                controller: _businessNameCtrl,
                style: TextStyle(color: AppColors.text),
                decoration: const InputDecoration(hintText: 'Ex: Studio da Ana'),
              ),
              const SizedBox(height: 20),

              // ── Seu nome (saudação do Início) ───────────────
              _SectionTitle('Seu nome (opcional)'),
              TextField(
                controller: _ownerNameCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: AppColors.text),
                decoration: const InputDecoration(hintText: 'Ex: Ana — aparece em "Bom dia, Ana!"'),
              ),
              const SizedBox(height: 20),

              // ── Logo ──────────────────────────────────────
              _SectionTitle('Logo do seu negócio'),
              Row(children: [
                BrandLogo(logo: _logo, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(_logo.isEmpty ? 'ESCOLHER DA GALERIA' : 'TROCAR LOGO'),
                    ),
                    if (_logo.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _logo = ''),
                        child: const Text('Remover'),
                      ),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Cor da marca ──────────────────────────────
              _SectionTitle('Cor da sua marca'),
              Wrap(
                spacing: 10,
                children: _colorPresets.map((hex) {
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  final selected = hex == _primaryColor;
                  return GestureDetector(
                    onTap: () => setState(() => _primaryColor = hex),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: AppColors.text, width: 2) : null,
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Locais de atendimento ──────────────────────
              _SectionTitle('Locais de atendimento (1 ou 2)'),
              TextField(
                controller: _location1Ctrl,
                style: TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Ex: Studio Centro',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Tenho um segundo local', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                value: _hasSecondLocation,
                activeThumbColor: AppColors.rose,
                onChanged: (v) => setState(() => _hasSecondLocation = v),
              ),
              if (_hasSecondLocation)
                TextField(
                  controller: _location2Ctrl,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Ex: Studio Bairro X',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Serviços oferecidos ────────────────────────
              _SectionTitle('Serviços que você oferece'),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Toque em 🔁 para dizer em quantos dias a cliente deve voltar para refazer o serviço. '
                  'A aba Marketing usa isso para avisar quem está na hora de voltar.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                ),
              ),
              ..._services.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                final details = [
                  if (s.price > 0) 'R\$ ${s.price.toStringAsFixed(2)}',
                  s.returnDays > 0 ? 'retorno em ${s.returnDays} dias' : 'sem lembrete de retorno',
                ].join(' · ');
                return Card(
                  color: AppColors.card,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(s.name, style: TextStyle(color: AppColors.text)),
                    subtitle: Text(details, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        tooltip: 'Dias para retorno',
                        icon: Icon(Icons.autorenew_rounded,
                            color: s.returnDays > 0 ? AppColors.green : AppColors.textMuted),
                        onPressed: () => _editReturnDays(i),
                      ),
                      IconButton(
                        tooltip: 'Remover serviço',
                        icon: Icon(Icons.delete_outline, color: AppColors.rose),
                        onPressed: () => setState(() => _services.removeAt(i)),
                      ),
                    ]),
                  ),
                );
              }),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _newServiceNameCtrl,
                      style: TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(hintText: 'Nome do serviço'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _newServicePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: AppColors.text),
                      decoration: const InputDecoration(hintText: 'R\$ (opcional)'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: AppColors.rose),
                    onPressed: _addService,
                  ),
                ],
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
                  child: Text(_error!, style: TextStyle(color: AppColors.rose, fontSize: 12)),
                ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.isFirstSetup ? 'COMEÇAR A USAR' : 'SALVAR'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ));
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
