import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/regulagem.dart';
import '../../providers/configuracoes_provider.dart';
import '../../providers/regulagens_provider.dart';
import '../../routes.dart';
import '../../theme.dart';
import '../../widgets/app_button.dart';
import '../configuracoes/configuracoes_screen.dart';
import '../historico/historico_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardTab(),
          HistoricoScreen(),
          ConfiguracoesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Início',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.list_alt),
            icon: Icon(Icons.list_alt_outlined),
            label: 'Regulagens',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Future<void> _refresh() async {
    try {
      final regulagensProvider = context.read<RegulagensProvider>();
      final configuracoesProvider = context.read<ConfiguracoesProvider>();
      await regulagensProvider.load();
      await configuracoesProvider.load();
    } catch (error) {
      debugPrint('Erro ao atualizar dashboard: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat(
      "EEEE, d MMM yyyy",
      'pt_BR',
    ).format(DateTime.now());
    final configuracoes = context.watch<ConfiguracoesProvider>().configuracoes;
    final regulagens = context.watch<RegulagensProvider>().regulagens;
    final nome = configuracoes.nomeConsultor.trim();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppConstants.appName),
            Text(today, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _WelcomeCard(nome: nome),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Nova Regulagem',
              icon: Icons.add,
              onPressed: () => Navigator.pushNamed(context, Routes.regulagem),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SummaryCard(total: regulagens.length),
            const SizedBox(height: AppSpacing.xl),
            _LastRegulagemCard(
              regulagem: regulagens.isEmpty ? null : regulagens.first,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppShadows.homeCard(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: child,
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.nome});

  final String nome;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nome.isEmpty
                ? 'Bem-vindo ao ${AppConstants.appName}'
                : 'Olá, $nome',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Regule pulverizadores direto no campo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Row(
        children: [
          const Icon(
            Icons.assignment_turned_in_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$total regulagens realizadas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

class _LastRegulagemCard extends StatelessWidget {
  const _LastRegulagemCard({required this.regulagem});

  final Regulagem? regulagem;

  @override
  Widget build(BuildContext context) {
    final item = regulagem;
    return _HomeCard(
      child: item == null
          ? Text(
              'Nenhuma regulagem salva ainda.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última regulagem',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('${item.produtor} • ${item.fazenda}'),
                Text(
                  DateFormat(
                    "dd MMM yyyy 'às' HH:mm",
                    'pt_BR',
                  ).format(item.dataRegulagem),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
