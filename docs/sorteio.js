// Utilidades compartilhadas: codificação de estado na URL e lógica de sorteio.

function embaralhar(arr) {
  var a = arr.slice();
  for (var i = a.length - 1; i > 0; i--) {
    var j = Math.floor(Math.random() * (i + 1));
    var t = a[i]; a[i] = a[j]; a[j] = t;
  }
  return a;
}

// Codifica um objeto em uma string segura para usar como parâmetro de URL.
function codificarEstado(obj) {
  var json = JSON.stringify(obj);
  var b64 = btoa(unescape(encodeURIComponent(json)));
  return encodeURIComponent(b64);
}

// Decodifica de volta; retorna null se a string estiver corrompida/ausente.
function decodificarEstado(str) {
  try {
    var b64 = decodeURIComponent(str);
    var json = decodeURIComponent(escape(atob(b64)));
    return JSON.parse(json);
  } catch (e) {
    return null;
  }
}

var LOCAL_HIST_PREFIX = 'f14_historico_lider_';

function lerHistoricoLider(temaId) {
  try {
    var raw = localStorage.getItem(LOCAL_HIST_PREFIX + temaId);
    return raw ? JSON.parse(raw) : { ultimosLideres: [] };
  } catch (e) {
    return { ultimosLideres: [] };
  }
}

function salvarHistoricoLider(temaId, data) {
  try {
    localStorage.setItem(LOCAL_HIST_PREFIX + temaId, JSON.stringify(data));
  } catch (e) {}
}

// Sorteia os papéis para uma lista de nomes presentes, aplicando:
// - mesa única se < 10 pessoas, múltiplas mesas de 5 se >= 10
// - regra de não repetir líder do encontro anterior (por tema)
function sortearRodada(temaId, papeisLiderados, nomes) {
  var numMesas = nomes.length < 10 ? 1 : Math.floor(nomes.length / 5);
  var embaralhados = embaralhar(nomes);
  var emJogo = embaralhados.slice(0, numMesas * 5);
  var foraDaRodada = embaralhados.slice(numMesas * 5);

  var hist = lerHistoricoLider(temaId);
  var ultimosLideres = hist.ultimosLideres || [];
  var mesas = [];
  var novosLideres = [];

  for (var m = 0; m < numMesas; m++) {
    var grupo = emJogo.slice(m * 5, m * 5 + 5);
    var candidatosLider = grupo.filter(function (p) { return ultimosLideres.indexOf(p) === -1; });
    if (candidatosLider.length === 0) candidatosLider = grupo;
    var lider = candidatosLider[Math.floor(Math.random() * candidatosLider.length)];
    var restantes = embaralhar(grupo.filter(function (p) { return p !== lider; }));
    var papeis = { lider: lider };
    papeisLiderados.forEach(function (chave, idx) { papeis[chave] = restantes[idx]; });
    mesas.push({ numero: m + 1, papeis: papeis });
    novosLideres.push(lider);
  }

  salvarHistoricoLider(temaId, { ultimosLideres: novosLideres });

  return {
    tema: temaId,
    participantes: nomes,
    mesas: mesas,
    foraDaRodada: foraDaRodada,
    sorteadoEm: new Date().toISOString()
  };
}
