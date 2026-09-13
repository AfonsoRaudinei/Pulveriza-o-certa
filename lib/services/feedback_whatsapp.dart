import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';

/// Abre o WhatsApp com mensagem pré-preenchida para feedback de bug/erro.
///
/// [launchUrlFn] permite injetar fake em testes.
Future<bool> abrirFeedbackWhatsApp({
  Future<bool> Function(Uri url, {LaunchMode mode})? launchUrlFn,
}) async {
  final uri = Uri.parse(AppConstants.feedbackWhatsAppUrl).replace(
    queryParameters: {
      'text': AppConstants.feedbackWhatsAppMessage,
    },
  );
  final launch = launchUrlFn ?? launchUrl;
  return launch(uri, mode: LaunchMode.externalApplication);
}

void mostrarFeedbackFalhouSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível abrir o WhatsApp. Envie para ${AppConstants.feedbackWhatsAppDisplay}.',
        ),
      ),
    );
}
