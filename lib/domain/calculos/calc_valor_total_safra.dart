/// Calcula o valor total da safra em reais.
///
/// [manejoRS] Custo de manejo por hectare (R$/ha).
/// [areaHa]   Área da operação em hectares.
///
/// Retorna 0.0 se qualquer entrada for nula, zero ou negativa.
double calcularValorTotalSafra({
  required double manejoRS,
  required double areaHa,
}) {
  if (manejoRS <= 0 || areaHa <= 0) return 0;
  return manejoRS * areaHa;
}
