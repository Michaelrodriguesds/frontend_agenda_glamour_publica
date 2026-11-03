import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/trial_gate.dart';
import 'data/services/cache_service.dart';
import 'data/services/connectivity_service.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/calendar/calendar_screen.dart';
import 'presentation/screens/appointments/appointment_form_screen.dart';
import 'presentation/screens/stats/stats_screen.dart';
import 'presentation/screens/notes/notes_screen.dart';
import 'presentation/screens/clients/clients_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/blocked/blocked_screen.dart';
import 'presentation/widgets/bottom_nav.dart';
import 'presentation/widgets/offline_banner.dart';
import 'providers/auth_provider.dart';
import 'providers/business_config_provider.dart';
import 'providers/refresh_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  // ── Inicializa serviços globais ─────────────────────────────────
  await CacheService.init();               // cache local
  await ConnectivityService().init();      // monitoramento de internet

  runApp(const ProviderScope(child: BelaAgendaApp()));
}

class BelaAgendaApp extends ConsumerWidget {
  const BelaAgendaApp({super.key});

  // "#RRGGBB" → Color; qualquer valor inválido cai no rose padrão.
  static Color _parse(String hex) {
    final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return (hex.length == 7 && v != null) ? Color(0xFF000000 | v) : const Color(0xFFE8527A);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(businessConfigProvider);
    final accent = cfg.status == BusinessConfigStatus.loaded
        ? _parse(cfg.config.primaryColor)
        : const Color(0xFFE8527A);
    return MaterialApp(
      title: 'BelaAgenda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(accent),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();
  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Ao deslogar, limpa a config de negócio guardada em memória —
    // evita vazar a config de um usuário pro próximo que logar no aparelho.
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated &&
          previous?.status != AuthStatus.unauthenticated) {
        ref.read(businessConfigProvider.notifier).reset();
        TrialGate.instance.clear();
      }
    });

    switch (authState.status) {
      case AuthStatus.checking:
        return const _SplashScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return const _BusinessConfigGate();
    }
  }
}

// ── Depois de autenticado, garante que a config do negócio (logo,
// serviços, locais) está carregada antes de mostrar qualquer tela ──
class _BusinessConfigGate extends ConsumerStatefulWidget {
  const _BusinessConfigGate();
  @override
  ConsumerState<_BusinessConfigGate> createState() => _BusinessConfigGateState();
}

class _BusinessConfigGateState extends ConsumerState<_BusinessConfigGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(businessConfigProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessConfigProvider);

    switch (state.status) {
      case BusinessConfigStatus.loading:
        return const _SplashScreen();

      case BusinessConfigStatus.error:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não foi possível carregar seus dados.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(state.error ?? '', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.read(businessConfigProvider.notifier).load(),
                    child: const Text('TENTAR NOVAMENTE'),
                  ),
                  TextButton(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    child: const Text('Sair'),
                  ),
                ],
              ),
            ),
          ),
        );

      case BusinessConfigStatus.loaded:
        if (state.config.needsOnboarding) {
          return const OnboardingScreen(isFirstSetup: true);
        }
        return const _TrialGate();
    }
  }
}

// ── Escuta o sinal global de trial expirado em qualquer chamada de API ──
class _TrialGate extends StatefulWidget {
  const _TrialGate();
  @override
  State<_TrialGate> createState() => _TrialGateState();
}

class _TrialGateState extends State<_TrialGate> {
  @override
  void initState() {
    super.initState();
    TrialGate.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    TrialGate.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (TrialGate.instance.blocked) return const BlockedScreen();
    return const _MainShell();
  }
}

// ── Shell principal ───────────────────────────────────────────────
class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();
  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _index = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(),
    StatsScreen(),
    NotesScreen(),
    ClientsScreen(),
  ];

  int _navToScreen(int navIndex) => navIndex > 2 ? navIndex - 1 : navIndex;
  int _screenToNav(int screenIndex) => screenIndex >= 2 ? screenIndex + 1 : screenIndex;

  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AppointmentFormScreen(),
        ),
      ).then((_) => ref.read(refreshProvider.notifier).state++);
      return;
    }
    final screenIndex = _navToScreen(navIndex);
    if (screenIndex != _index) ref.read(refreshProvider.notifier).state++;
    setState(() => _index = screenIndex);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        // ── Banner offline (aparece/some com animação) ──────────────
        const OfflineBanner(),
        Expanded(
          child: IndexedStack(index: _index, children: _screens),
        ),
      ],
    ),
    bottomNavigationBar: AppBottomNav(
      currentIndex: _screenToNav(_index),
      onTap: _onNavTap,
    ),
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🌸', style: TextStyle(fontSize: 60)),
        SizedBox(height: 16),
        Text('BelaAgenda',
            style: TextStyle(
                color: Color(0xFFF5EEF8), fontSize: 24, fontWeight: FontWeight.w700)),
        SizedBox(height: 24),
        CircularProgressIndicator(color: Color(0xFFE8527A), strokeWidth: 2.5),
      ]),
    ),
  );
}
