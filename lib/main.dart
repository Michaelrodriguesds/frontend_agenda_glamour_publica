import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/brand_color.dart';
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
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // `runApp` é chamado IMEDIATAMENTE — nada é esperado (`await`) antes
  // disso. A primeira tela (splash) aparece assim que possível; a
  // inicialização (datas + cache + conectividade + estilo salvo) roda
  // depois, dentro do próprio widget, em PARALELO (Future.wait) em vez de
  // uma depois da outra. Nenhuma tela que depende desses serviços é
  // construída antes de `_ready` terminar (ver build abaixo).
  runApp(const ProviderScope(child: BelaAgendaApp()));
}

class BelaAgendaApp extends ConsumerStatefulWidget {
  const BelaAgendaApp({super.key});
  @override
  ConsumerState<BelaAgendaApp> createState() => _BelaAgendaAppState();
}

class _BelaAgendaAppState extends ConsumerState<BelaAgendaApp> {
  late final Future<void> _ready = _init();

  Future<void> _init() => Future.wait([
    initializeDateFormatting('pt_BR'),
    CacheService.init(),                     // cache local
    ConnectivityService().init(),            // monitoramento de internet
    ref.read(themeProvider.notifier).load(), // estilo salvo no aparelho
  ]);

  @override
  Widget build(BuildContext context) {
    // Cores = ESTILO escolhido no aparelho + COR DA MARCA do negócio
    // (se a chave "Usar a cor da minha marca" estiver ligada). Antes do
    // login ainda não há negócio, então vale a cor do estilo.
    final theme = ref.watch(themeProvider);
    final cfg = ref.watch(businessConfigProvider);
    final brand = (theme.useBrandColor && cfg.status == BusinessConfigStatus.loaded)
        ? BrandColor.parse(cfg.config.primaryColor)
        : null;
    AppColors.apply(theme.palette, brand: brand);

    // Quando o estilo ou a cor mudam, a `key` muda junto e o Flutter monta
    // o app de novo do zero: todas as telas releem AppColors e já aparecem
    // com as cores novas. (Efeito colateral aceitável: volta para o Início;
    // login e dados não se perdem, pois ficam nos providers, fora daqui.)
    return MaterialApp(
      key: ValueKey('${theme.palette.id}|${AppColors.rose.toARGB32()}'),
      title: 'BelaAgenda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.current,
      // Em telas grandes (PC/notebook) o app não estica pela tela inteira:
      // fica centralizado com largura máxima de 1100 px. No celular a
      // largura é menor que isso e nada muda.
      builder: (context, child) => ColoredBox(
        color: AppColors.background,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _SplashScreen();
          }
          return const _AuthGate();
        },
      ),
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
      // Se a config já está carregada (o app foi redesenhado por troca de
      // estilo/cor), não busca de novo — evita piscar a tela de carregando.
      // No login a config começa "carregando" (reset no logout), então busca.
      if (ref.read(businessConfigProvider).status != BusinessConfigStatus.loaded) {
        ref.read(businessConfigProvider.notifier).load();
      }
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

  // Construtores (não instâncias prontas) — cada tela só é efetivamente
  // criada (e, portanto, só dispara suas próprias requisições) na
  // primeira vez que o usuário abre aquela aba. Antes, `IndexedStack`
  // recebia as 5 telas já instanciadas de uma vez (_screens const),
  // então Home + Calendário + Estatísticas + Notas + Clientes disparavam
  // suas chamadas de API TODAS ao mesmo tempo, assim que o app abria —
  // mesmo que o usuário só fosse olhar a tela inicial.
  static const List<Widget Function()> _builders = [
    HomeScreen.new,
    CalendarScreen.new,
    StatsScreen.new,
    NotesScreen.new,
    ClientsScreen.new,
  ];

  // Quais abas já foram abertas pelo menos uma vez. Home (índice 0) já
  // começa "visitada" pois é a tela inicial. Uma vez visitada, a tela
  // continua viva dentro do IndexedStack (mesmo comportamento de antes:
  // o estado de rolagem/filtros da aba é preservado ao trocar de aba).
  final Set<int> _visited = {0};

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
    setState(() {
      _index = screenIndex;
      _visited.add(screenIndex);
    });
  }

  // Mantém o estado das abas (rolagem, filtros) quando a janela muda
  // entre "celular" e "tela larga": o conteúdo troca de lugar na árvore,
  // mas com esta chave o Flutter o move em vez de recriá-lo.
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Tela larga = PC/notebook (largura >= 800 e altura >= 500).
      // Celular, mesmo deitado, continua com a barra de baixo.
      final wide = constraints.maxWidth >= 800 && constraints.maxHeight >= 500;

      final content = KeyedSubtree(
        key: _contentKey,
        child: Column(
          children: [
            // ── Banner offline (aparece/some com animação) ────────────
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: List.generate(
                  _builders.length,
                  // Abas ainda não visitadas renderizam um espaço vazio
                  // (sem custo, sem requisição) até o usuário realmente
                  // tocar nelas pela primeira vez.
                  (i) => _visited.contains(i) ? _builders[i]() : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );

      if (!wide) {
        return Scaffold(
          body: content,
          bottomNavigationBar: AppBottomNav(
            currentIndex: _screenToNav(_index),
            onTap: _onNavTap,
          ),
        );
      }

      return Scaffold(
        body: Row(
          children: [
            AppSideNav(
              currentIndex: _screenToNav(_index),
              onTap: _onNavTap,
            ),
            Expanded(child: content),
          ],
        ),
      );
    },
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🌸', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 16),
        Text('BelaAgenda',
            style: TextStyle(
                color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        CircularProgressIndicator(color: AppColors.rose, strokeWidth: 2.5),
      ]),
    ),
  );
}
