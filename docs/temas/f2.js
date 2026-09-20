// Dados do tema F2 - Comportamento Líder (Perfil DISC)
// Compartilhado entre intermediador.html e index.html
var TEMA_F2 = {
  id: "F2",
  titulo: "Comportamento Líder (Perfil DISC)",
  lider: {
    nome: "Líder",
    cargo: "Líder de turno na linha de produção",
    classe: "lider",
    texto: "Contexto: a gerência da fábrica decidiu implementar uma nova checagem de qualidade na linha, que adiciona cerca de 5 minutos a cada parada. A meta diária de produção não muda.\n\nSituação: você precisa comunicar essa mudança à sua equipe — Marcos, Bianca, Carlos e Débora — e conseguir adesão real, não só concordância forçada. Antes mesmo desta conversa, já rolou um comentário informal na linha de que \"isso vai atrasar tudo\".\n\nSua missão: decida como conduzir essa comunicação (reunião com todos? conversas individuais primeiro?) e preste atenção em como cada pessoa da equipe reage — adapte sua abordagem a cada uma.\n\nDébora, a técnica química responsável pela linha, tem autoridade técnica: pode recusar liberar a mudança até se sentir segura com o processo."
  },
  liderados: [
    {
      id: "marcos", nome: "Marcos", tag: "D", classe: "d",
      cargo: "Operador líder de turno, 8 anos de casa",
      texto: "Como você é: direto, impaciente, vai ao ponto. Não gosta de enrolação nem de reunião longa sem objetivo. Fala olhando no olho, tom firme.\n\nFrases suas: \"Vai direto ao assunto.\" / \"Isso já foi decidido ou ainda dá pra discutir?\" / \"Eu resolvo, só me diz o prazo.\"\n\nO que te irrita: sentir que estão escondendo informação ou enrolando.\nO que te motiva: autonomia, desafio, ser reconhecido por resolver rápido.\n\nComo jogar: questione o líder diretamente, peça lógica por trás da decisão. Se ele explicar bem o \"porquê\", você cede rápido — mas teste um pouco antes."
    },
    {
      id: "bianca", nome: "Bianca", tag: "I", classe: "i",
      cargo: "Operadora, 2 anos de casa, \"alma da linha\"",
      texto: "Como você é: animada, fala com as mãos, puxa assunto, faz piada mesmo em momento tenso. Se importa muito com o clima do grupo.\n\nFrases suas: \"Gente, calma, vamos conversar!\" / \"Também acho que a galera vai ficar puta se não explicarem direito\" / \"Ninguém me perguntou nada antes!\"\n\nO que te irrita: ser ignorada, decisão anunciada sem ninguém \"sentir\" que você participou.\nO que te motiva: ser ouvida na frente do grupo, sentir-se parte da solução, elogio público.\n\nComo jogar: reaja primeiro ao clima emocional, não ao conteúdo técnico. Se o líder te der espaço pra opinar na frente dos outros, você vira aliada na hora."
    },
    {
      id: "carlos", nome: "Carlos", tag: "S", classe: "s",
      cargo: "Operador, 15 anos de casa, o mais experiente",
      texto: "Como você é: calmo, fala pouco, demora pra responder, evita confronto direto. Prefere rotina a mudança.\n\nFrases suas: \"Sempre fizemos assim, mas... tá bom, se for pra melhorar.\" / \"Vai mudar muita coisa de uma vez?\" — ou só silêncio e um aceno de cabeça quando está desconfortável.\n\nO que te irrita: mudança anunciada de forma abrupta.\nO que te motiva: segurança, previsibilidade, sentir que o líder está no controle da transição.\n\nComo jogar: não discorde abertamente — mostre desconforto por gestos, silêncio, respostas evasivas. Só relaxa se o líder detalhar o passo a passo e o prazo de adaptação."
    },
    {
      id: "debora", nome: "Débora", tag: "C", classe: "c",
      cargo: "Técnica química, responsável pela linha de produção",
      texto: "Como você é: precisa, técnica, faz perguntas objetivas, anota tudo, questiona números. Você não decide sozinha uma validação formal de processo — precisa checar com seu coordenador de qualidade antes.\n\nFrases suas: \"Isso está documentado em algum procedimento?\" / \"Quem validou esse tempo de 5 minutos, foi medido ou é estimativa?\" / \"Preciso checar isso com meu coordenador antes de liberar a linha.\"\n\nO que te irrita: resposta vaga, decisão sem passar por você antes, \"confia em mim\" sem dado nenhum.\nO que te motiva: clareza, critério técnico, ser tratada como responsável.\n\nSeu poder na cena: você pode recusar liberar a mudança até ter critério técnico ou aval do seu coordenador. Não ceda só porque o líder \"pediu com jeito\"."
    }
  ],
  cola: {
    condicoes: [
      "Adversa — no início: \"A meta diária de produção continua a mesma, mesmo com a nova checagem.\"",
      "Adversa — no meio: \"Um operador já comentou pelos corredores que isso vai atrasar tudo, antes mesmo desta conversa.\"",
      "Favorável — alívio: \"A gerência da fábrica pode liberar um piloto de 2 semanas antes de tornar definitivo, se bem justificado.\"",
      "Favorável — alívio: \"O time de qualidade se oferece para dar um treinamento rápido de 15 min antes da mudança.\""
    ],
    encruzilhada: "Quando a conversa do líder com a Débora travar (ela insiste em documentação/validação), leia para o líder: escolha uma das três — A) Autoridade: reforça que a decisão veio da gerência da fábrica e pede que ela aplique. B) Parceria técnica: pede que ela acione o coordenador de qualidade para validar antes de comunicar aos demais. C) Escalar: pausa a implementação e leva a preocupação à gerência da fábrica antes de seguir. Reações: (A) ela aplica mas registra a falta de validação com o coordenador — vira bomba-relógio. (B) liga pro coordenador — aprova rápido se houver dados/prazo, senão pede mais tempo. (C) ganha respeito dela mas atrasa tudo e passa a imagem de líder que não decide sozinho.",
    perguntas: [
      "Qual perfil foi mais fácil/difícil de liderar e por quê?",
      "Em que momento você percebeu que precisava mudar de abordagem?",
      "Na conversa com a Débora, qual alternativa você escolheu e o que isso gerou?",
      "O que você faria diferente sabendo o perfil de cada um antes da reunião?"
    ]
  }
};

var TEMAS = window.TEMAS || {};
TEMAS[TEMA_F2.id] = TEMA_F2;
window.TEMAS = TEMAS;
