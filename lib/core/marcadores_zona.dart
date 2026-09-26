import 'package:flutter/material.dart';

import '../models/regulagem.dart';
import '../theme.dart';

/// Tokens únicos de cor dos marcadores de zona (tela + PDF).
abstract final class MarcadoresZona {
  static const Color pendente = Color(0xFF86868B);

  static Color cor(StatusPonta status) {
    return switch (status) {
      StatusPonta.ideal => AppColors.zonaIdeal,
      StatusPonta.atencao => AppColors.zonaAtencao,
      StatusPonta.desgaste => AppColors.zonaDesgaste,
      StatusPonta.irregular => AppColors.zonaEntupida,
      StatusPonta.pendente => pendente,
    };
  }

  /// Rótulo curto para legenda e status.
  static String rotulo(StatusPonta status) {
    return switch (status) {
      StatusPonta.irregular => 'Entupida',
      StatusPonta.ideal => 'Ideal',
      StatusPonta.atencao => 'Atenção',
      StatusPonta.desgaste => 'Desgaste',
      StatusPonta.pendente => 'Pendente',
    };
  }

  /// Ordem fixa da legenda compacta (página 1 do PDF).
  static const ordemLegenda = <StatusPonta>[
    StatusPonta.irregular,
    StatusPonta.ideal,
    StatusPonta.atencao,
    StatusPonta.desgaste,
    StatusPonta.pendente,
  ];
}
