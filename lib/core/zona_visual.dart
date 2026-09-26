import 'package:flutter/material.dart';

import '../models/regulagem.dart';
import '../theme.dart';
import 'marcadores_zona.dart';

Color corZona(StatusPonta status) => MarcadoresZona.cor(status);

Color fundoZona(StatusPonta status, {bool dark = false}) {
  if (dark) {
    return corZona(status).withValues(alpha: 0.18);
  }
  return switch (status) {
    StatusPonta.ideal => AppColors.zonaIdealLight,
    StatusPonta.atencao => AppColors.zonaAtencaoLight,
    StatusPonta.desgaste => AppColors.zonaDesgasteLight,
    StatusPonta.irregular => AppColors.zonaEntupidaLight,
    StatusPonta.pendente => AppColors.surfaceAlt,
  };
}
