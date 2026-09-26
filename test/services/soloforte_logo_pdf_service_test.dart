import 'package:agrocalc/services/soloforte_logo_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SoloForteLogoPdfService.limparCache();
  });

  test('carrega e comprime logo do asset', () async {
    final bytes = await SoloForteLogoPdfService.carregarParaPdf();
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(100));
    expect(bytes!.length, lessThan(80 * 1024));

    final cached = await SoloForteLogoPdfService.carregarParaPdf();
    expect(identical(bytes, cached), isTrue);
  });
}
