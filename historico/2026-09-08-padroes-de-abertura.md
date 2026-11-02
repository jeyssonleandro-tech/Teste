# Registro — como o painel abre

Sessão de 8 de setembro de 2026, à tarde. Três ajustes de exibição,
nenhuma mudança de dado ou de banco.

---

## 1. Tema claro fixo

O painel seguia o ajuste do aparelho: celular no modo escuro abria o
painel escuro. Agora o claro é o padrão, independentemente do aparelho —
o material é apresentado em reunião e impresso, e o escuro seria uma
surpresa em cima da hora.

O botão **Tema** continua trocando para o escuro quando alguém quiser.

Efeito colateral corrigido junto: o botão decidia a direção da troca
consultando o `prefers-color-scheme`. Com o padrão agora fixo, quem usa o
celular no escuro daria o primeiro clique sem ver nada mudar. A direção
passa a sair do estado real da página.

O formulário de lançamento recebeu o mesmo tratamento — duas telas do
mesmo produto abrindo em temas diferentes seria estranho.

---

## 2. Diário como abertura

Era **Semanal · 12 semanas**; passa a ser **Diário · 30 dias**. A semana e
o mês continuam a um clique.

---

## 3. Produção fora do painel

A unidade **Produção** existe no banco só para alimentar os índices de
água. O painel é das estações de tratamento, e agora mostra apenas
`ETE Industrial`, `ETE Sanitária`, `ETA` e `Represa`.

O filtro é por **tipo de unidade**, num só lugar do código:

```js
const TIPOS_FORA_DO_PAINEL = new Set(["Produção"]);
```

Esconder ali derruba a aba e tudo o que vem depois dela, nos três modos.
**O formulário de lançamento continua enxergando a Produção** — é lá que
ela é lançada, e sem ela os índices não existem.

---

## 4. Validação

Playwright com o navegador declarado no **modo escuro**:

- o painel e o formulário abrem claros assim mesmo;
- um clique em "Tema" escurece, o segundo volta ao claro;
- abre em Diário, com a janela de 30 dias;
- as abas trazem ETA, ETE Industrial e Represa — sem Produção, no diário
  e no semanal;
- a Produção continua na lista de unidades do formulário.
