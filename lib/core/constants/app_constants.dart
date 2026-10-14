class AppConstants {
  static const appName = 'Ponta Verde';

  /// Logo do rodapé do laudo PDF (SoloForte).
  static const logoSoloForteAsset = 'assets/logo.jpeg';
  static const nomeMarcaRodapePdf = 'SoloForte';

  /// Metadado `Author` do PDF (rodapé visual usa [nomeMarcaRodapePdf]).
  static const pdfDocumentAuthor = 'SoloForte';
  static const appVersion = '1.0.0';
  static const regulagensKey = 'agro_regulagens';
  static const configuracoesKey = 'agro_configuracoes';
  static const custosManejoKey = 'agro_custos_manejo';

  /// WhatsApp feedback — E.164 sem + (55 63 98437-6572).
  static const feedbackWhatsAppE164 = '5563984376572';
  static const feedbackWhatsAppUrl = 'https://wa.me/$feedbackWhatsAppE164';
  static const feedbackWhatsAppDisplay = '(63) 98437-6572';
  static const feedbackWhatsAppMessage =
      'Olá, encontrei um problema no Ponta Verde:\n';
}
