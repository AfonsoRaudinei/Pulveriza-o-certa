import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../theme.dart';
import '../../widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    try {
      if (_email.text.isEmpty || _senha.text.isEmpty) return;
      setState(() => _loading = true);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.home);
    } catch (error) {
      debugPrint('Erro no login mock: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(Icons.calculate,
                    color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('AgroCalc', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Calculadora de regulagem para grandes culturas',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-mail')),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _senha,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: _loading ? 'Entrando...' : 'Entrar',
                onPressed: _loading ? null : _entrar,
              ),
              const Spacer(),
              Center(
                child: Text(
                  'Tela congelada na v1.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
