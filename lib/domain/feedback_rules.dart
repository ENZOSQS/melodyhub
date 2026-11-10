/// Nível de detalhe e apoio pedagógico exibido após uma resposta.
enum NivelApoio { iniciante, intermediario, avancado }

/// Define o apoio pela etapa atual e pela sequência correta desta sessão.
NivelApoio nivelDeApoio({
  required int nivelEtapa,
  required int sequenciaAcertos,
}) {
  if (sequenciaAcertos >= 5) return NivelApoio.avancado;
  if (nivelEtapa <= 2) return NivelApoio.iniciante;
  if (nivelEtapa == 3) return NivelApoio.intermediario;
  return NivelApoio.avancado;
}

String nomeNivelApoio(NivelApoio nivel) => switch (nivel) {
  NivelApoio.iniciante => 'Iniciante',
  NivelApoio.intermediario => 'Intermediário',
  NivelApoio.avancado => 'Avançado',
};
