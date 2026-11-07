import '../../data/models/business_config_model.dart';

/// Textos e labels do app centralizados.
///
/// `appName`, `procedures`, `procedureIcons` e `locations` deixaram de ser
/// fixos: são preenchidos a partir da configuração de negócio de cada
/// usuário (ver [applyBusinessConfig]), chamado logo após login/onboarding.
/// Os valores abaixo são só o fallback antes de carregar a config.
class AppStrings {
  AppStrings._();

  // ── App (dinâmico por negócio) ──────────────
  static String appName     = 'BelaAgenda';
  /// Nome cadastrado pelo negócio ('' se ainda não cadastrou). Diferente de
  /// [appName], não cai para "BelaAgenda" (usado na assinatura das mensagens).
  static String businessName = '';
  static String appSubtitle = 'Agenda Online';
  static String logoUrl     = '';

  // ── Procedimentos/serviços (dinâmico por negócio) ──
  static List<String> procedures = [];

  // Ícone genérico — cada usuário tem serviços diferentes, não dá pra ter
  // um ícone específico por nome; usamos um conjunto que roda em sequência.
  static const List<String> _iconPool = ['✨', '🌿', '✏️', '💋', '🪵', '🧴', '💅', '💆', '🧖', '💇'];
  static Map<String, String> procedureIcons = {};

  // ── Locais de atendimento (dinâmico por negócio) ──
  static List<String> locations = [];

  /// Chamado após login/onboarding/edição de config: sincroniza os textos
  /// e listas do app inteiro com o que o usuário configurou.
  static void applyBusinessConfig(BusinessConfig config) {
    appName     = config.businessName.isNotEmpty ? config.businessName : 'BelaAgenda';
    businessName = config.businessName.trim();
    logoUrl     = config.logoUrl;
    locations   = config.locations.isNotEmpty ? config.locations : locations;

    final activeServices = config.services.where((s) => s.active).map((s) => s.name).toList();
    procedures = activeServices.isNotEmpty ? activeServices : procedures;

    procedureIcons = {
      for (var i = 0; i < procedures.length; i++)
        procedures[i]: _iconPool[i % _iconPool.length],
    };
  }

  // ── Formas de pagamento ────────────────────
  static const List<String> paymentMethods = [
    'PIX',
    'Cartão',
    'Dinheiro',
    'A combinar',
  ];

  // ── Tags de anotações ─────────────────────
  static const Map<String, String> noteTags = {
    'lembrete':   '🔔 Lembrete',
    'financeiro': '💰 Financeiro',
    'estoque':    '📦 Estoque',
    'geral':      '📝 Geral',
  };

  // ── Navegação ──────────────────────────────
  static const String navHome       = 'Início';
  static const String navCalendar   = 'Calendário';
  static const String navNew        = 'Novo';
  static const String navStats      = 'Stats';
  static const String navNotes      = 'Notas';
  static const String navClients    = 'Clientes';

  // ── Formulário ─────────────────────────────
  static const String labelClientName   = 'Nome da cliente';
  static const String labelProcedure    = 'Procedimento';
  static const String labelDate         = 'Data';
  static const String labelTime         = 'Horário';
  static const String labelLocation     = 'Local';
  static const String labelPrice        = 'Valor (R\$)';
  static const String labelPayMethod    = 'Forma de pagamento';
  static const String labelPaid         = 'Pagamento realizado';
  static const String labelConfirmed    = 'Cliente confirmada';
  static const String labelNotes        = 'Observações';

  // ── Status ─────────────────────────────────
  static const String statusPaid        = '✓ Pago';
  static const String statusPending     = 'Pendente';
  static const String statusConfirmed   = '✓ Confirmada';
  static const String statusWaiting     = 'Aguardando';
  static const String statusFree        = 'Livre';
  static const String statusFull        = 'Lotado';
  static const String statusPartial     = 'Parcial';
  static const String statusRest        = 'Folga';
}
