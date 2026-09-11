double calcularPercentualPonta({
  required double? valorMedido,
  required double litroMinIdeal,
}) {
  if (valorMedido == null || valorMedido <= 0 || litroMinIdeal <= 0) {
    return 0;
  }
  return (valorMedido / litroMinIdeal) * 100;
}
