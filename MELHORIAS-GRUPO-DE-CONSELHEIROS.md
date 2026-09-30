# Melhorias no agente "Grupo de Conselheiros"

> **Para a sessão que vai implementar:** este documento é uma especificação de
> mudanças no repositório `jeyssonleandro-tech/grupo-de-conselheiros`. Leia
> tudo antes de começar, implemente na ordem das fases e respeite as
> decisões marcadas como **[DECISÃO DO USUÁRIO]**: pergunte antes de
> executá-las. Ao final de cada fase, rode os casos de teste da Fase 7
> que se aplicarem.
>
> Origem: avaliação feita em 30/09/2026 (horário de São Paulo) sobre o estado
> do repositório no commit `d09061d`.

---

## Contexto rápido

O repositório implementa um conselho consultivo no Claude Code:

- `.claude/skills/conselho/SKILL.md` — orquestrador (`/conselho`), atua como
  secretário neutro.
- `.claude/agents/grupo-*.md` — 6 grupos (estratégia, pessoas, financeiro,
  operações, liderança, tecnologia) + `conselho-filosofico.md`.
- `conselho/contexto/` — `perfil.md` (preenchido), `empresa.md` e
  `empreendedorismo.md` (quase vazios).
- `conselho/conselheiros/<grupo>/` — **todos vazios** (só README).
- `conselho/modelos/` — modelos de entregáveis, ata, decisão e perfil.
- Registros vão para `conselho/pareceres/`, `atas/`, `decisoes/`, com push
  direto na `main`.

**Objetivo declarado do usuário** (e critério de sucesso das mudanças):
1. **Avaliar o desempenho dele como gestor** ao longo do tempo.
2. **Apoiar a fundação do primeiro negócio** (franquia em estudo).

Hoje o sistema atende bem só a parte "aconselhar sob demanda". O objetivo 1
não tem mecanismo, e isso é a prioridade.

## O que NÃO mudar (pontos fortes a preservar)

- Rodada 1 independente: nenhum grupo vê o outro antes de formar posição.
- "Quem decide é o presidente", com o **motivo** registrado em cada decisão.
- Regras contra invenção: sem citação literal, paráfrase com obra de
  referência, sinalizar "a verificar", campo *Limites* nos perfis.
- Freio de mão com dados, ligado ao perfil do usuário.
- Filósofos sem veto, com questionamento apontado a um trecho específico.
- Modelos por tipo de entregável e extensão proporcional à demanda.
- Idioma pt-BR e fuso America/Sao_Paulo.

---

## Fase 1 — Privacidade (fazer primeiro)

**Problema:** o histórico vai direto para a `main` com dados pessoais
(fé, família, rotina) e, em breve, atas sobre **colaboradores reais**
(desempenho, advertências). Isso envolve LGPD e política da empresa.

**Tarefas:**
1. Verificar se o repositório é privado. Se for público, **avisar o usuário
   e parar** até ele tornar privado. **[DECISÃO DO USUÁRIO]**
2. Acrescentar ao `CLAUDE.md`, em "Regras que valem para toda interação",
   uma regra 7:
   > **Privacidade.** Colaboradores são identificados por função + letra
   > (ex.: "Técnico químico A", "Operador B"), nunca pelo nome. Se o
   > presidente citar um nome, o secretário substitui pelo código nos
   > registros e mantém a correspondência apenas na conversa. Não registrar
   > dados internos da empresa (custos, metas numéricas confidenciais,
   > nomes de clientes/fornecedores) além do necessário para o parecer.
3. Replicar essa regra nas "Regras do secretário" da `SKILL.md`.
4. Criar `conselho/contexto/equipe-codigos.md`? **Não.** A correspondência
   nome↔código não deve ficar no repositório.

**Critério de aceite:** um teste com "o João errou a análise de DQO" gera
ata e parecer sem o nome "João".

---

## Fase 2 — Avaliação de desempenho do presidente (prioridade máxima)

**Problema:** o conselho só reage a demandas. Ninguém acompanha o usuário
ao longo do tempo. O campo "Resultado observado" (`modelos/decisao.md`) e a
coluna "Revisar em" (`decisoes/INDICE.md`) existem, mas nenhum modo os
aciona.

### 2.1 Nova estrutura de arquivos

```
conselho/presidente/
  scorecard.md            indicadores vivos do presidente como gestor
  avaliacoes/             uma avaliação por ciclo: AV-2026-10.md, AV-2026-T4.md
  divergencias.md         vezes em que o presidente decidiu contra o conselho
conselho/modelos/avaliacao.md   modelo da avaliação periódica
```

### 2.2 `conselho/presidente/scorecard.md` (criar)

Indicadores derivados do `perfil.md`. Estrutura sugerida:

```markdown
# Scorecard do presidente

> Atualizado a cada `/conselho avaliar` e a cada `/conselho decidir`.

## Indicadores de decisão
| Indicador | Por que importa (do perfil) | Como medir | Linha de base | Atual | Meta |
|---|---|---|---|---|---|
| % de decisões com dados antes | Tende a decidir por instinto | Decisões cujo parecer não teve "dados críticos faltantes" ou em que os dados foram trazidos antes de decidir ÷ total | | | ≥ 80% |
| Tempo até decidir | Trava na largada | Dias entre o parecer e o `decidir` | | | ≤ prazo definido no parecer |
| Decisões revisadas no prazo | Aprender com o resultado | Revisões feitas ÷ revisões devidas | | | 100% |
| Acerto das decisões revisadas | Calibração | Resultado observado bom/parcial/ruim | | | tendência crescente |
| Acerto quando divergiu do conselho | Calibração dos dois lados | Ver `divergencias.md` | | | — |

## Indicadores da equipe (frente Empresa)
| Indicador | Linha de base | Atual | Meta |
|---|---|---|---|
| Turnover (12 meses) | | | |
| Ações de desenvolvimento concluídas | | | |
| Clima / percepção da equipe (se houver coleta) | | | |
| Indicadores da área (ETE/ETA) sob responsabilidade dele | | | |

## Indicadores da jornada empreendedora
| Marco | Previsto | Realizado |
|---|---|---|
| Critérios de escolha do setor definidos | | |
| Reserva/capital-alvo atingido | | |
| Franquias avaliadas (COF lida, franqueados entrevistados) | | |
| Decisão go/no-go | | |

## Competências de gestão (autoavaliação + leitura do conselho, 1–5)
| Competência | Presidente | Conselho | Evidência |
|---|---|---|---|
| Decisão baseada em dados | | | |
| Feedback e desenvolvimento da equipe | | | |
| Comunicação | | | |
| Gestão do tempo e prioridades | | | |
| Visão financeira | | | |
```

### 2.3 Novo modo `/conselho avaliar [mensal|trimestral]` (na `SKILL.md`)

Acrescentar à tabela de roteamento e criar a seção:

1. Ler `scorecard.md`, as decisões do período, as avaliações anteriores e
   `divergencias.md`.
2. Listar decisões com "Revisar em" vencido e **pedir ao presidente o
   resultado observado** de cada uma (uma pergunta curta por decisão).
   Atualizar o campo "Resultado observado" nos arquivos de decisão.
3. Pedir a autoavaliação das competências (1–5, uma linha de evidência cada).
4. Acionar em paralelo o `grupo-lideranca` (com instrução `AVALIAÇÃO DO
   PRESIDENTE`) e o `conselho-filosofico`. Os demais grupos só se o período
   tiver tido decisões relevantes na área deles.
5. Gerar `conselho/presidente/avaliacoes/AV-<período>.md` pelo modelo
   `conselho/modelos/avaliacao.md` e atualizar o `scorecard.md`.
6. Terminar com **no máximo 3 focos de desenvolvimento** para o próximo
   ciclo, cada um com uma ação concreta e como medir.

### 2.4 `conselho/modelos/avaliacao.md` (criar)

Seções: período · decisões do período (tabela: parecer, decisão, seguiu o
conselho?, resultado) · leitura dos indicadores · autoavaliação vs. leitura
do conselho (onde divergem) · padrões observados (ex.: "decidiu rápido sem
dados em 2 de 5 casos") · olhar filosófico · 3 focos para o próximo ciclo ·
data da próxima avaliação.

### 2.5 Formato `AVALIAÇÃO DO PRESIDENTE` no `grupo-lideranca.md`

Acrescentar um formato de resposta:

```
## Grupo de Liderança — Avaliação do presidente
- **O que evoluiu:** (com evidência das decisões/atas)
- **Padrões que se repetem:** (com evidência)
- **Onde a autoavaliação diverge da evidência:**
- **Focos recomendados (máx. 3):** ação · como medir · prazo
```

Regra: **direto, mesmo que doa** (preferência do perfil), mas sempre com
evidência concreta. Proibido elogio genérico.

### 2.6 Ciclo de revisão das decisões

- No modo `decidir`: exigir "Revisar em" (sugerir data conforme a urgência:
  urgente 30 dias, importante 60, planejamento 90) e registrar se o
  presidente **seguiu ou não** a recomendação. Se não seguiu, acrescentar
  linha em `conselho/presidente/divergencias.md` (parecer, recomendação do
  conselho, decisão do presidente, motivo, resultado — a preencher).
- No início de **qualquer** modo: se houver decisões com "Revisar em"
  vencido, avisar em uma linha ("2 decisões aguardam revisão:
  `/conselho avaliar`"). Não bloquear a demanda atual.

### 2.7 Coleta de percepção da equipe (opcional) **[DECISÃO DO USUÁRIO]**

Propor ao usuário um questionário anônimo curto (5–8 perguntas, escala 1–5
+ 1 aberta) para aplicar à equipe a cada trimestre, cujo resumo entra na
avaliação trimestral. Só implementar o modelo
(`conselho/modelos/pesquisa-equipe.md`) se ele aceitar.

**Critérios de aceite da Fase 2:**
- `/conselho avaliar mensal` funciona com zero decisões (gera avaliação
  inicial com linha de base e autoavaliação).
- Após uma decisão com "Revisar em" vencido, qualquer comando avisa da
  revisão pendente.
- Decidir contra a recomendação gera linha em `divergencias.md`.

---

## Fase 3 — Combater a trava na largada

**Problema:** o perfil diz que o bloqueio do usuário é **começar** (medo de
escolher errado). O modo projeto é pesado e pode alimentar paralisia por
análise.

**Tarefas:**
1. Acrescentar a **todos** os modelos de entregável (`plano-de-acao.md`,
   `parecer.md`, `plano-estruturado.md`, `plano-de-negocio.md`), logo antes
   de "Decisão que precisa de você", a seção:
   ```markdown
   ## Para sair do papel
   - **Passo de 48h:** a menor ação concreta que dá para fazer em até 48h.
   - **Teste reversível:** como testar em pequena escala antes de apostar grande
     (o que medir, por quanto tempo, critério de sucesso).
   - **Prazo para decidir:** <data>. Depois dela, o custo de não decidir é: <...>.
   ```
2. Na `SKILL.md`, rodada 3: instruir a área líder (ou a mais aderente) a
   propor esses três itens. O secretário garante que não saiam vazios.
3. No modo `pendencias`: destacar pareceres com **prazo para decidir
   vencido**.

**Critério de aceite:** todo entregável gerado tem "Para sair do papel"
preenchido e com data.

---

## Fase 4 — Rodadas adaptativas e combate ao consenso artificial

**Problemas:**
- 3 rodadas fixas geram cerca de 10 chamadas de subagente por projeto; é
  caro e lento, sobretudo no celular.
- Todos os grupos são o **mesmo modelo**. Na rodada 2 tendem a concordar,
  e o consenso fica artificial.

**Tarefas na `SKILL.md`:**
1. **Rodadas adaptativas** (substituir as seções 3–5 do modo projeto):
   - Rodada 1: sempre.
   - Rodada 2: sempre que houver 2+ grupos.
   - **Após a rodada 2, verificar consenso.** Se houver consenso e o
     entregável for *plano de ação* ou *parecer de decisão*, **pular a
     rodada 3** e seguir para o parecer.
   - Rodada 3: obrigatória para *plano estruturado*, *plano de negócio* ou
     quando houver divergência.
   - Registrar na ata quais rodadas ocorreram e por quê.
2. **Contra o efeito manada**, acrescentar aos formatos dos subagentes:
   - Rodada 1: campo **"Argumento mais forte contra a nossa recomendação:"**
     (obrigatório, honesto, não espantalho).
   - Rodada 2: regra "**Só mude de posição com argumento novo** — cite qual.
     Mudar por pressão da maioria é proibido." E campo obrigatório
     "**Principal objeção a outro grupo:**" (se não houver, justificar por
     que nenhuma posição tem falha relevante).
   - Rodada final (2 ou 3): campo **"Pré-mortem:"** — "daqui a 12 meses
     isso deu errado; as 2 causas mais prováveis são...".
3. **Critério objetivo de consenso** (seção 6): consenso = mesma ação
   recomendada **e** nenhuma objeção classificada pelo próprio grupo como
   "impeditiva". Pedir aos grupos que classifiquem cada ressalva como
   *menor* ou *impeditiva*.

**Critério de aceite:** um plano de ação com consenso na rodada 2 termina
sem rodada 3; toda posição de rodada 1 traz o argumento contrário.

---

## Fase 5 — Composição dos grupos

### 5.1 Novos grupos para a frente Empreendedorismo **[DECISÃO DO USUÁRIO]**

Faltam as duas áreas que mais derrubam um primeiro negócio. Propor ao
usuário e criar se ele aprovar:

- **`grupo-comercial`** — Comercial e Marketing: proposta de valor na
  prática, captação e retenção de clientes, canais, precificação do ponto
  de vista do cliente, escolha de ponto comercial, marketing local, vendas.
  Pergunta-chave: *"Quem compra, por quê, quanto custa conquistá-lo e como
  ele volta?"*
- **`grupo-juridico-contabil`** — Jurídico, Contábil e Tributário:
  enquadramento (MEI/ME, Simples Nacional), contrato de franquia e Circular
  de Oferta de Franquia (Lei 13.966/2019), riscos trabalhistas, licenças.
  **Aviso obrigatório em toda resposta:** "orientação geral; valide com
  advogado/contador antes de assinar ou decidir". Pergunta-chave:
  *"O que pode dar errado no papel e quanto isso custa?"*

Para cada um: criar o agente (seguindo o protocolo comum da Fase 6),
`conselho/conselheiros/<grupo>/README.md`, e incluir nas tabelas da
`SKILL.md`, do `README.md` e do modelo `perfil-conselheiro.md`.

### 5.2 Sobreposição Pessoas × Liderança **[DECISÃO DO USUÁRIO]**

Opções a apresentar: (a) manter separados e explicitar a fronteira
(Pessoas = **sistemas**; Liderança = **o presidente como líder** e a
avaliação dele); (b) fundir. Recomendação: **(a)**, porque Liderança passa
a conduzir a avaliação do presidente (Fase 2). Atualizar as descrições nos
dois agentes para deixar a fronteira explícita.

### 5.3 Voz cristã no conselho filosófico **[DECISÃO DO USUÁRIO]**

O `perfil.md` diz que a fé católica é "parte real do raciocínio em decisões
difíceis, não periférica", mas o conselho filosófico é só estoico, Platão e
Galileu. Perguntar ao usuário se quer incluir, por exemplo:
- **Santo Tomás de Aquino** — prudência como virtude de quem governa, justiça
  distributiva e comutativa, lei e bem comum (*Suma Teológica*, II-II).
- **Santo Agostinho** — intenção, ordem dos amores, tempo (*Confissões*).
- **Doutrina Social da Igreja** — dignidade do trabalho, salário justo,
  bem comum, subsidiariedade (*Rerum Novarum*, *Laborem Exercens*,
  *Compêndio da DSI*).

Se aprovado: criar o perfil em `conselho/filosofos/`, atualizar
`filosofos/README.md` e o agente `conselho-filosofico.md` (base estoica,
com influência de Platão, Galileu **e da tradição cristã**).

### 5.4 Preencher os conselheiros (depende do usuário)

Os 6 grupos estão sem conselheiros; todo parecer sairia "sem composição
definida". Ao iniciar, **perguntar ao usuário** os nomes por grupo e usar
`/conselho incluir`. Sugestões de ponto de partida, a confirmar com ele:
Bernardinho (liderança), Flávio Augusto (estratégia/empreendedorismo),
Felipe Titto (comercial/visão), que já estão no perfil dele. Para pessoas
vivas, preencher bem o campo *Limites* (o modelo sabe menos sobre elas e
tende a inventar).

---

## Fase 6 — Ajustes técnicos

### 6.1 Protocolo comum dos grupos (remover duplicação)

Os 6 arquivos `grupo-*.md` são ~95% idênticos (~5,8 mil caracteres cada).

1. Criar `conselho/protocolo-grupos.md` com tudo o que é comum: seções
   "Composição", "Frente da demanda", "Princípios" e todos os "Formatos por
   tipo de acionamento" (com `<Nome do grupo>` como marcador), já incluindo
   as mudanças das Fases 2–4.
2. Reduzir cada `grupo-*.md` a: frontmatter, identidade, **escopo**,
   **pergunta-chave**, pasta de conselheiros e a instrução:
   > Antes de responder, leia `conselho/protocolo-grupos.md` e siga-o
   > integralmente, usando "<Nome do grupo>" nos títulos.
3. Instruções exclusivas de um grupo (ex.: `AVALIAÇÃO DO PRESIDENTE` em
   Liderança, aviso jurídico) ficam no arquivo do próprio grupo.

### 6.2 Filtro de contexto por frente

Os agentes leem `conselho/contexto/*.md` inteiro, contradizendo a skill
(perfil + contexto **da frente**). No protocolo comum, trocar por:
> Leia `conselho/contexto/perfil.md`, `conselho/contexto/estado.md` e
> **somente** os arquivos de contexto indicados no briefing.

E na `SKILL.md`, seção Briefing: incluir a linha "Arquivos de contexto a
ler: ...".

### 6.3 Painel vivo `conselho/contexto/estado.md`

Com dezenas de atas, reler o histórico fica caro. Criar um painel curto
(até ~1 página), **primeiro arquivo lido** em qualquer modo:
- metas atuais (empresa e empreendedorismo);
- decisões em andamento e próximas revisões;
- 5–10 aprendizados consolidados (ex.: "decisões de pessoas: sempre olhar
  dados do turno antes");
- focos de desenvolvimento do ciclo (vindos da Fase 2).

Atualizar ao final de `decidir` e `avaliar`.

### 6.4 Checagem do secretário antes de entregar

Acrescentar às "Regras do secretário" um checklist obrigatório antes de
mostrar o parecer:
- [ ] todo número tem premissa ou fonte;
- [ ] toda fonte da web tem link;
- [ ] afirmações duvidosas marcadas "a verificar";
- [ ] nenhuma citação literal inventada;
- [ ] nenhum nome de colaborador (Fase 1);
- [ ] "Para sair do papel" preenchido (Fase 3);
- [ ] decisões anteriores relacionadas foram consideradas.

### 6.5 Git

Manter o envio para a `main` (decisão do usuário), mas:
- fazer `git pull --rebase origin main` **antes** de gravar, não só depois;
- se o push falhar por conflito, resolver sem descartar registros e avisar.

### 6.6 Documentação

Atualizar `README.md` e `CLAUDE.md` com: novo modo `avaliar`, pasta
`conselho/presidente/`, `estado.md`, protocolo comum, novos grupos (se
aprovados), regra de privacidade, rodadas adaptativas.

---

## Fase 7 — Casos de teste do agente

Criar `conselho/testes/casos.md` com cenários fixos para rodar sempre que
os prompts mudarem. Registrar o resultado (passou/falhou + observação) em
`conselho/testes/resultados.md`. Não salvar os pareceres de teste no
histórico real (usar prefixo `T-` e apagar depois, ou marcar como teste).

| # | Entrada | Comportamento esperado |
|---|---|---|
| T1 | `/conselho rapida Empresa: vou advertir o técnico que errou a análise de ontem` | Pergunta pelos dados (erro individual ou coletivo? dados do turno?) **antes** de endossar. Não usa nome. |
| T2 | `/conselho Empreendedorismo: quero abrir uma franquia de açaí, vale a pena?` | Triagem com dados críticos faltantes (capital, praça, COF). Plano de negócio ou parecer. Inclui "Para sair do papel". Aciona jurídico-contábil se existir. |
| T3 | `/conselho Empresa: plano de ação para reduzir retrabalho nas análises` com consenso claro | Termina sem rodada 3. Rodada 1 traz "argumento contra". |
| T4 | `/conselho Empresa: devo demitir um operador com baixo desempenho?` | Aciona filósofos automaticamente (impacto sobre pessoas). Filósofos não vetam. |
| T5 | `/conselho decidir P-xxx Escolhi B porque...` quando o conselho recomendou A | Registra divergência em `divergencias.md`, exige "Revisar em". |
| T6 | `/conselho avaliar mensal` sem histórico | Gera linha de base e autoavaliação, sem inventar dados. |
| T7 | Demanda sem frente e ambígua | Deduz a frente e confirma na triagem. |

---

## Ordem sugerida e dependências

| Fase | Depende de | Esforço | Precisa do usuário? |
|---|---|---|---|
| 1 — Privacidade | — | Baixo | Sim (visibilidade do repo) |
| 6.1/6.2 — Protocolo comum e filtro | — | Médio | Não |
| 2 — Avaliação do presidente | 6.1 | Médio | Parcial (2.7) |
| 3 — Largada | 6.1 | Baixo | Não |
| 4 — Rodadas adaptativas | 6.1 | Baixo | Não |
| 6.3–6.6 — Estado, checklist, git, docs | 2, 3, 4 | Baixo | Não |
| 5 — Composição | 6.1 | Médio | **Sim** (5.1, 5.2, 5.3, 5.4) |
| 7 — Casos de teste | todas | Baixo | Não |

Sugestão: fazer o protocolo comum (6.1) **logo depois da Fase 1**, para que
as Fases 2–4 sejam escritas uma vez só, no protocolo, e não seis vezes.

## Commits

Um commit por fase, com mensagem descritiva em pt-BR (ex.: `Fase 2: modo
avaliar e scorecard do presidente`). Seguir a regra existente de envio para
a `main`.
