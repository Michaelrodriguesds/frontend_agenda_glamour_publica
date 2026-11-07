/// URLs de todos os endpoints da API
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base URL ────────────────────────────────────────────────────
  // Configure no build: --dart-define=API_URL=https://SEU-SERVICO.onrender.com
  static const _base = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://belaagenda-api.onrender.com',
  );

  // ── Auth ────────────────────────────────────────────────────────
  static String get register      => '$_base/api/auth/register';
  static String get login         => '$_base/api/auth/login';
  static String get verify        => '$_base/api/auth/verify';
  static String get me            => '$_base/api/auth/me';
  static String get refreshToken  => '$_base/api/auth/refresh';
  static String get forgotPassword => '$_base/api/auth/forgot-password';
  static String get resetPassword  => '$_base/api/auth/reset-password';

  // ── Configuração do negócio (logo, serviços, locais) ──────────────
  static String get businessConfig => '$_base/api/business/config';

  // ── Agendamentos ─────────────────────────────────────────────────
  static String get appointments => '$_base/api/appointments';
  static String appointmentById(String id)     => '$_base/api/appointments/$id';
  static String payAppointment(String id)      => '$_base/api/appointments/$id/pay';
  static String confirmAppointment(String id)  => '$_base/api/appointments/$id/confirm';

  // ── Disponibilidade ───────────────────────────────────────────────
  static String get availability      => '$_base/api/availability';
  static String get monthAvailability => '$_base/api/availability/month';

  // ── Estatísticas ──────────────────────────────────────────────────
  static String get monthlyStats => '$_base/api/stats/monthly';
  static String get trendStats   => '$_base/api/stats/trend';

  // ── Anotações Gerais ──────────────────────────────────────────────
  static String get notes           => '$_base/api/notes';
  static String noteById(String id) => '$_base/api/notes/$id';
  static String pinNote(String id)  => '$_base/api/notes/$id/pin';

  // ── Clientes (agregado, não depende de GET /appointments sem filtro) ──
  static String get clients => '$_base/api/clients';

  // ── Clientes & Marketing (aba em Estatísticas) ──────────────────────
  static String get marketingReminders => '$_base/api/marketing/reminders';
  static String get marketingSent      => '$_base/api/marketing/reminders/sent';
  static String get marketingMovement  => '$_base/api/marketing/movement';
  static String get marketingSegments  => '$_base/api/marketing/segments';
  static String marketingPrefs(String clientName) =>
      '$_base/api/marketing/prefs/${Uri.encodeComponent(clientName)}';
}
