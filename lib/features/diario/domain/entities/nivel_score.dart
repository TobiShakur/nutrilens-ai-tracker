/// Nivel cualitativo del health score diario. La vista lo traduce a texto y color.
enum NivelScore {
  sinRegistros,
  excelente,
  bueno,
  moderado,
  bajo;

  static NivelScore desdeScore({required int score, required bool hayComidas}) {
    if (!hayComidas) return NivelScore.sinRegistros;
    if (score >= 85) return NivelScore.excelente;
    if (score >= 70) return NivelScore.bueno;
    if (score >= 50) return NivelScore.moderado;
    return NivelScore.bajo;
  }
}
