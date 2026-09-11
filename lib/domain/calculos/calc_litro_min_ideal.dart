double calcularLitroMinIdeal({
  required double vazaoLha,
  required double velocidade,
  required double espacamentoCm,
}) {
  if (vazaoLha <= 0 || velocidade <= 0 || espacamentoCm <= 0) return 0;
  return (vazaoLha * velocidade * (espacamentoCm / 100)) / 600;
}
