# Modo TV e comparação mês a mês

## Comparar meses

No painel, ao lado de Diário / Semanal / Mensal há o botão **Comparar**.

- Abre com o mês em tela contra o anterior. No seletor de mês dá para
  marcar de **2 a 4 meses** (o menu fica aberto enquanto se marca).
- Cada mês tem uma cor: o mais recente em azul, o anterior em cinza, e
  laranja e roxo para o terceiro e o quarto.
- Em cima: um cartão por mês com o número do mês (a mesma regra do modo
  Mensal: soma, média ou razão conforme o parâmetro), a variação contra o
  mês anterior da lista e o selo de dentro/fora do limite.
- No meio: o gráfico dia a dia com os meses **sobrepostos pelo dia** — o
  dia 12 de um mês cai em cima do dia 12 do outro.
- Embaixo: a tabela com todos os parâmetros da unidade, um mês por coluna
  e a variação do último contra o penúltimo.
- O mês em andamento aparece marcado. Em parâmetros de **total**
  (pluviometria, volumes) ele ainda não fechou e não deve ser comparado
  com um mês completo; o painel avisa.
- Os níveis de tanque não entram: são o retrato do fim do turno, não um
  número do mês.

## Modo TV

Botão **Modo TV** no topo. Os gráficos passam sozinhos, um depois do
outro, em tela cheia.

1. Escolha a unidade (ou "todas, em sequência") e o tempo de cada
   gráfico (10 s a 1 min; o padrão é 30 s).
2. **Iniciar**.

Durante a exibição:

| Tecla / ação | O que faz |
|---|---|
| Esc | sai do modo TV |
| Seta → / ← | próximo / anterior |
| Barra de espaço | pausa e continua |
| Mexer o mouse ou tocar na tela | mostra os comandos por 3 s |

Cada "gráfico" é um parâmetro da unidade. Parâmetros sem nenhum valor no
período ficam de fora, e os níveis de tanque aparecem como tanque ao lado,
não como gráfico.

Ele se mantém sozinho: mostra sempre o **mês mais recente com lançamento**
(acompanha a virada do mês), refaz a consulta a cada 5 minutos, pede ao
navegador para não apagar a tela e, se a rede cair, continua mostrando o
último dado e escreve no canto "sem conexão — dados de HH:MM".

### Deixar fixo na tela do laboratório

O diálogo mostra um endereço pronto, com botão Copiar:

```
https://…/index.html?tv=ETE%20Industrial&seg=30
```

- `tv=` é o nome da unidade, ou `todas`.
- `seg=` é o tempo por gráfico, de 5 a 300 segundos.

Abrir esse endereço já entra no modo TV, sem clicar. Para tela cheia sem
barra do navegador, abra o Chrome ou Edge com `--kiosk` (ou F11).

Recomendações para a TV:

1. **Crie um usuário só para a TV, com perfil leitor.** Ele não consegue
   lançar nem mexer em nada, e se a senha ficar salva num computador do
   laboratório o risco é mínimo. Depois de criar o usuário em
   Authentication → Users:

   ```sql
   insert into public.perfis (usuario_id, nome, papel)
   select id, 'TV do laboratório', 'leitor' from auth.users where email = 'tv@…'
   on conflict (usuario_id) do update set papel = excluded.papel;
   ```

2. Entre uma vez com esse usuário nesse navegador. O login fica salvo e é
   renovado sozinho. Se um dia a sessão cair, a TV volta para a tela de
   login — é preciso entrar de novo.
3. A tela é desenhada para 1280 × 760 e cresce até 2,4× em TVs maiores.
