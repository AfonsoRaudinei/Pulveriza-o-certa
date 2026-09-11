/// Quantidade física = dose por hectare × área a aplicar.
double calcularQuantidadeTotal({
  required double dose,
  required double areaAplicar,
}) {
  if (dose <= 0 || areaAplicar <= 0) return 0;
  return dose * areaAplicar;
}
