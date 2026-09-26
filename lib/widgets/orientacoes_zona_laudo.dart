import 'package:flutter/material.dart';

import '../core/formatters/laudo_numero_format.dart';
import '../core/iconografia/zona_icon.dart';
import '../core/marcadores_zona.dart';
import '../domain/calculos/calc_diagnostico_regulagem.dart';
import '../domain/calculos/calc_texto_veredito_laudo.dart';
import '../domain/calculos/texto_pontas.dart';
import '../models/regulagem.dart';
import '../theme.dart';
import 'secao_laudo_titulo.dart';

/// Cards de orientação por zona (fundo neutro; cor só no ícone).
class OrientacoesZonaLaudo extends StatelessWidget {
  const OrientacoesZonaLaudo({
    super.key,
    required this.orientacoes,
    this.atencao,
  });

  final List<OrientacaoDiagnostico> orientacoes;
  final ZonaDiagnostico? atencao;

  static const _fundo = Color(0xFFF5F5F7);
  static const _borda = Color(0xFFE5E5E7);
  static const _titulo = Color(0xFF1D1D1F);
  static const _descricao = Color(0xFF86868B);

  @override
  Widget build(BuildContext context) {
    if (orientacoes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SecaoLaudoTitulo(titulo: 'Orientações'),
        const SizedBox(height: AppSpacing.sm),
        for (final o in orientacoes) ...[
          _Card(
            status: o.status,
            titulo: textoQuantidadePontas(o.quantidade, o.status),
            descricao: _descricaoOrientacao(o, atencao),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  static String _descricaoOrientacao(
    OrientacaoDiagnostico o,
    ZonaDiagnostico? atencao,
  ) {
    final perda = o.perdaRs != null && o.perdaRs! > 0
        ? formatarMoedaLaudo(o.perdaRs!)
        : null;
    String? excesso;
    if (o.status == StatusPonta.atencao && atencao?.mediaPercentual != null) {
      final exc = atencao!.mediaPercentual! - 100;
      if (exc > 0) {
        excesso = LaudoNumeroFormat.decimal(exc, casas: 1);
      }
    }
    return mensagemOrientacaoLaudo(
      o.status,
      desperdicioDefensivo: perda,
      excessoMedioPercentual: excesso,
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.status,
    required this.titulo,
    required this.descricao,
  });

  final StatusPonta status;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    final accent = MarcadoresZona.cor(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: OrientacoesZonaLaudo._fundo,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: OrientacoesZonaLaudo._borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZonaIcon(status: status, size: 12, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OrientacoesZonaLaudo._titulo,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: OrientacoesZonaLaudo._descricao,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
