#!/usr/bin/env python3
"""Gera o consolidado mensal de atrasos na entrada a partir dos espelhos de ponto.

Entrada: arquivo .md com os espelhos de ponto de todos os colaboradores
aglutinados (PDF convertido para Markdown).
Saída: planilha .xlsx com as abas Resumo, Detalhe diário, Pontos de atenção e
Escalas, além de um resumo em JSON no stdout para conferência.

Uso:
    python3 gerar_consolidado.py ENTRADA.md [--saida ARQUIVO.xlsx] [--tolerancia MIN]
"""
import argparse
import calendar
import datetime as dt
import json
import re
import sys
from collections import Counter, OrderedDict

try:
    from openpyxl import Workbook
    from openpyxl.formatting.rule import CellIsRule, DataBarRule
    from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
    from openpyxl.utils import get_column_letter
    from openpyxl.workbook.properties import CalcProperties
except ImportError:
    sys.exit("openpyxl não está instalado. Rode: pip install openpyxl")

MESES = ["", "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho",
         "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
DIAS = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
# Usado só quando o código não aparece no quadro "Códigos de Horários (CH)".
ESCALAS_PADRAO = {"0026": ("08:00", "17:48"), "0030": ("06:00", "18:00"), "0032": ("18:00", "06:00")}

RE_DATA = re.compile(r"(\d{2})\.?(\d{2})\.?(\d{4})")
RE_HORA = re.compile(r"\b(\d{1,2}):?(\d{2})\b")
RE_CH = re.compile(r"^\d{4}$")


def limpa(s):
    return s.replace("**", "").replace("<br>", " ").strip()


def celulas(linha):
    return [c for c in linha.strip().strip("|").split("|")]


def junta_fragmentos(variantes):
    """Reconstrói um texto quebrado em células de tamanhos diferentes.

    A conversão do PDF corta as palavras em pontos aleatórios ("MAR|IANA") e
    perde o espaço quando o corte cai entre palavras ("JOAO|PEDRO"). As letras
    são as mesmas em todas as variantes do cabeçalho, então para cada intervalo
    entre letras: há espaço se alguma variante mostra o espaço, ou se nenhuma
    variante mostra as letras coladas e alguma mostra uma divisão de célula.
    """
    norm = []
    for v in variantes:
        v = re.sub(r"\s*\|\s*", "|", re.sub(r"[ \t]+", " ", v)).strip(" |")
        if v:
            norm.append(v)
    if not norm:
        return ""
    letras = Counter(re.sub(r"[ |]", "", v) for v in norm).most_common(1)[0][0]
    estado = {}  # índice da letra -> conjunto de {"espaco", "corte", "colado"}
    for v in norm:
        if re.sub(r"[ |]", "", v) != letras:
            continue
        i, sep = 0, None
        for ch in v:
            if ch in " |":
                sep = "espaco" if ch == " " or sep == "espaco" else "corte"
            else:
                if i > 0:
                    estado.setdefault(i, set()).add(sep or "colado")
                i, sep = i + 1, None
    out = []
    for i, ch in enumerate(letras):
        e = estado.get(i, set())
        if "espaco" in e or ("corte" in e and "colado" not in e):
            out.append(" ")
        out.append(ch)
    return "".join(out).strip()


def separa_matricula(texto):
    """'01|234567 FUL|ANO ...' -> ('01234567', 'FUL|ANO ...')."""
    m = re.match(r"[\d\s|]+", texto)
    if not m:
        return "", texto
    return re.sub(r"\D", "", m.group()), texto[m.end():]


def campo_cabecalho(linha, rotulo, proximo):
    """Texto entre **rotulo** e **proximo** numa linha de cabeçalho, sem as divisões de célula."""
    m = re.search(r"\*\*" + rotulo + r"\*\*(.*?)\*\*" + proximo, linha)
    if not m:
        return None
    return limpa_cab(m.group(1))


def limpa_cab(s):
    s = s.replace("<br>", "|").replace("**", "")
    s = re.sub(r"\d{2}\.\d{2}\.\d{4}", "|", s)          # datas (admissão) coladas no campo
    s = re.sub(r"(?<=[A-Za-zÀ-ÿ|\s])\d{9,}", "|", s)       # PIS colado no nome
    return s.strip(" |")


def hora(s):
    h, m = int(s[:-3]), int(s[-2:])
    return dt.time(h, m)


def le_espelhos(texto):
    """Separa o texto por colaborador e devolve cabeçalhos, escalas e linhas diárias."""
    colabs = OrderedDict()
    atual = None
    bloco_ch = False
    for n, linha in enumerate(texto.split("\n"), 1):
        if "**Empregado**" in linha and "Cargo" in linha:
            nome = campo_cabecalho(linha, "Empregado", "Cargo")
            if nome:
                mat, nome = separa_matricula(nome)
                if len(mat) >= 7:
                    chave = mat[-7:]
                    atual = colabs.setdefault(chave, dict(nomes=[], cargos=[], gestores=[], escalas={}, linhas=[]))
                    atual["nomes"].append(nome)
                    cargo = re.split(r"\*\*Cargo\*\*", linha, 1)[1]
                    atual["cargos"].append(limpa_cab(re.split(r"\*\*", cargo)[0]))
        if atual is None:
            continue
        if "Gestor" in linha:
            g = re.search(r"\*\*G?estor\*\*(.*?)(\*\*|$)", linha)
            if g:
                atual["gestores"].append(separa_matricula(limpa_cab(g.group(1)))[1])
        if "Códigos de Hor" in linha:
            bloco_ch = True
        if bloco_ch:
            plano = linha.replace("|", "").replace("<br>", " ")
            for cod, ent in re.findall(r"(?<!\d)(\d{4})\s+(\d{2}:\d{2})", plano):
                atual["escalas"].setdefault(cod, ent)
            if "**Data**" in linha:
                bloco_ch = False
        if re.match(r"^\|\s*(\.\.\s*(<br>)?\s*)?\d{2}\.?\d{2}\.?\d{4}", linha):
            atual["linhas"].append((n, celulas(linha)))
    return colabs


def dia_semana_ok(data, dia):
    dia = limpa(dia)
    return bool(dia) and DIAS[data.weekday()].startswith(dia[:3]) or (len(dia) < 3 and DIAS[data.weekday()].startswith(dia))


def interpreta_linhas(linhas, ano, mes):
    """Transforma as linhas da tabela em um registro por dia: CH, entrada, justificativa."""
    dias, reconstruidos = {}, []
    for n, c in linhas:
        c = c + [""] * (8 - len(c))
        datas = []
        for d, m, a in RE_DATA.findall(c[0]):
            try:
                datas.append(dt.date(int(a), int(m), int(d)))
            except ValueError:
                pass
        partes_dia = [p.strip() for p in c[1].split("<br>") if p.strip()]
        partes_ch = [limpa(p) for p in c[2].split("<br>") if limpa(p)]
        if not partes_dia or not partes_ch:
            continue  # linha só com a saída do turno da noite anterior
        jornada = limpa(c[4])
        just = limpa(c[5])
        inclusao = "Inclusão manual" in "|".join(c)
        garbled = len(set(datas)) > 1 or ".." in c[0] or bool(re.match(r"\s*\d{8}", c[0]))
        if len(partes_ch) >= 2 and len(datas) >= 2:
            # Duas linhas do PDF fundidas numa só: separa por posição.
            regs = list(zip(datas, partes_ch))
            com_trabalho = [i for i, (_, ch) in enumerate(regs) if RE_CH.match(ch)]
            for i, (data, ch) in enumerate(regs):
                tem_jornada = len(com_trabalho) == 1 and i == com_trabalho[0]
                dias.setdefault(data, dict(ch=ch, jornada=jornada if tem_jornada else "",
                                           just="" if tem_jornada else just, inclusao=inclusao and tem_jornada,
                                           reconstruido=True, linha=n))
            reconstruidos.append(n)
            continue
        cand = [d for d in datas if dia_semana_ok(d, partes_dia[0])] or datas
        if not cand:
            continue
        data = cand[0]
        if data in dias:
            continue
        dias[data] = dict(ch=partes_ch[0], jornada=jornada, just=just, inclusao=inclusao,
                          reconstruido=garbled, linha=n)
        if garbled:
            reconstruidos.append(n)
    return {d: v for d, v in dias.items() if d.year == ano and d.month == mes}


def entrada(jornada):
    m = RE_HORA.search(jornada)
    if not m or int(m.group(1)) > 23:
        return None
    return f"{int(m.group(1)):02d}:{m.group(2)}"


def minutos_atraso(prevista, registrada, tolerancia):
    p = int(prevista[:2]) * 60 + int(prevista[3:])
    r = int(registrada[:2]) * 60 + int(registrada[3:])
    if p >= 720 and r < p - 720:  # turno noturno com entrada depois da meia-noite
        r += 1440
    bruto = max(0, r - p)
    return 0 if bruto <= tolerancia else bruto


def processa(caminho, tolerancia):
    texto = open(caminho, encoding="utf-8").read()
    colabs = le_espelhos(texto)
    todas_datas = Counter()
    for c in colabs.values():
        for _, cel in c["linhas"]:
            for d, m, a in RE_DATA.findall(cel[0]):
                todas_datas[(int(a), int(m))] += 1
    if not todas_datas:
        sys.exit("Nenhuma linha diária encontrada. Confira se o arquivo é o espelho de ponto convertido.")
    ano, mes = todas_datas.most_common(1)[0][0]
    ndias = calendar.monthrange(ano, mes)[1]

    escalas = {}
    for c in colabs.values():
        for cod, ent in c["escalas"].items():
            escalas.setdefault(cod, ent)
    usados = set()
    resultado, atencao = [], []
    for mat, c in colabs.items():
        nome = junta_fragmentos(c["nomes"]).title()
        cargo = junta_fragmentos(c["cargos"])
        dias = interpreta_linhas(c["linhas"], ano, mes)
        registros = []
        for d in range(1, ndias + 1):
            data = dt.date(ano, mes, d)
            x = dias.get(data)
            if x is None:
                registros.append(dict(data=data, ch="?", entrada=None, obs="Dia não identificado no espelho – conferir"))
                atencao.append((nome, data, "Dia não encontrado no arquivo. Conferir no espelho original."))
                continue
            ch = x["ch"]
            ent = entrada(x["jornada"])
            trabalho = bool(RE_CH.match(ch))
            if trabalho:
                usados.add(ch)
            obs = []
            if x["just"] and x["just"] != "Sem marcação" or (x["just"] == "Sem marcação" and not trabalho):
                obs.append(x["just"])
            if x["inclusao"]:
                obs.append("Marcação incluída manualmente")
            if trabalho and not ent and not x["just"]:
                obs.append("Sem marcação")
                atencao.append((nome, data, f"Dia de escala {ch} sem marcação e sem justificativa (feriado?)."))
            if not trabalho and ent:
                obs.append("Trabalhou em dia de folga – sem escala de referência")
                atencao.append((nome, data, f"Trabalhou em dia de {ch} (entrada {ent}). Não gera atraso."))
            if x["reconstruido"]:
                atencao.append((nome, data, "Linha embaralhada na conversão do PDF, reconstruída. Conferir no espelho original."))
            atraso = 0
            if trabalho and ent:
                prev = escalas.get(ch) or ESCALAS_PADRAO.get(ch, (None,))[0]
                if prev:
                    atraso = minutos_atraso(prev, ent, tolerancia)
                    if x["inclusao"] and atraso:
                        atencao.append((nome, data, f"Atraso de {atraso} min vem de marcação incluída manualmente."))
            registros.append(dict(data=data, ch=ch, entrada=ent if trabalho or ent else None,
                                  obs="; ".join(obs), atraso=atraso, trabalhou=trabalho and bool(ent)))
        resultado.append(dict(matricula=mat.zfill(8), nome=nome, cargo=cargo, registros=registros))
    gestor = junta_fragmentos([g for c in colabs.values() for g in c["gestores"]])
    gestor = gestor.title()
    for cod in usados:
        if cod not in escalas:
            escalas[cod] = ESCALAS_PADRAO.get(cod, ("", ""))[0]
            atencao.append(("—", None, f"Código {cod} não encontrado no quadro de horários; usada entrada padrão {escalas[cod] or '(desconhecida)'}."))
    return dict(ano=ano, mes=mes, gestor=gestor, escalas=escalas, colaboradores=resultado,
                atencao=atencao, tolerancia=tolerancia)


def gera_planilha(r, saida):
    F = "Arial"
    hdr_font = Font(name=F, bold=True, color="FFFFFF")
    hdr_fill = PatternFill("solid", fgColor="1F4E78")
    base = Font(name=F, size=10)
    thin = Side(style="thin", color="BFBFBF")
    brd = Border(left=thin, right=thin, top=thin, bottom=thin)
    ctr = Alignment(horizontal="center", vertical="center")
    cinza = PatternFill("solid", fgColor="F2F2F2")

    def header(ws, row, cols, widths):
        for i, (c, w) in enumerate(zip(cols, widths), 1):
            x = ws.cell(row=row, column=i, value=c)
            x.font, x.fill, x.border = hdr_font, hdr_fill, brd
            x.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
            ws.column_dimensions[get_column_letter(i)].width = w
        ws.row_dimensions[row].height = 32

    wb = Workbook()
    res = wb.active
    res.title = "Resumo"
    det = wb.create_sheet("Detalhe diário")
    pa = wb.create_sheet("Pontos de atenção")
    esc = wb.create_sheet("Escalas")

    # Escalas e tolerância
    header(esc, 1, ["CH", "Entrada prevista"], [10, 16])
    codigos = sorted(r["escalas"])
    for i, cod in enumerate(codigos, 2):
        esc.cell(row=i, column=1, value=cod).font = base
        x = esc.cell(row=i, column=2, value=hora(r["escalas"][cod]) if r["escalas"][cod] else None)
        x.font, x.number_format, x.alignment = Font(name=F, size=10, color="0000FF"), "hh:mm", ctr
        esc.cell(row=i, column=1).border = x.border = brd
    ult_esc = 1 + len(codigos)
    tol_row = ult_esc + 2
    esc.cell(row=tol_row, column=1, value="Tolerância (min)").font = Font(name=F, size=10, bold=True)
    x = esc.cell(row=tol_row, column=2, value=r["tolerancia"])
    x.font, x.fill, x.alignment, x.border = Font(name=F, size=10, color="0000FF"), PatternFill("solid", fgColor="FFFF00"), ctr, brd
    esc.cell(row=tol_row + 2, column=1, value=(
        "Entradas em azul vêm do quadro 'Códigos de Horários (CH)' dos espelhos. A tolerância (amarelo) "
        "zera atrasos menores ou iguais a ela; 0 = conta todo minuto. Alterar aqui recalcula a planilha.")
    ).font = Font(name=F, size=9, italic=True)
    esc.column_dimensions["A"].width = 18
    TOL = f"Escalas!$B${tol_row}"
    ESC_A, ESC_B = f"Escalas!$A$2:$A${ult_esc}", f"Escalas!$B$2:$B${ult_esc}"

    # Detalhe diário
    header(det, 1, ["Matrícula", "Colaborador", "Cargo", "Data", "Dia", "CH (escala do dia)", "Entrada prevista",
                    "Entrada registrada (Jornada)", "Observação", "Atraso (min)"],
           [11, 36, 22, 11, 6, 10, 10, 13, 44, 10])
    row = 2
    faixas = {}
    for c in r["colaboradores"]:
        ini = row
        for g in c["registros"]:
            vals = [c["matricula"], c["nome"], c["cargo"], g["data"], DIAS[g["data"].weekday()], g["ch"],
                    f'=IFERROR(INDEX({ESC_B},MATCH(F{row},{ESC_A},0)),"")',
                    hora(g["entrada"]) if g.get("entrada") else None, g["obs"],
                    f'=IF(OR(G{row}="",H{row}=""),0,IF(MAX(0,ROUND((H{row}-G{row}+IF(AND(G{row}>=0.5,H{row}<G{row}-0.5),1,0))*1440,0))<={TOL},0,'
                    f'MAX(0,ROUND((H{row}-G{row}+IF(AND(G{row}>=0.5,H{row}<G{row}-0.5),1,0))*1440,0))))']
            for col, v in enumerate(vals, 1):
                x = det.cell(row=row, column=col, value=v)
                x.font, x.border = base, brd
                if col in (1, 4, 5, 6, 7, 8, 10):
                    x.alignment = ctr
                if not RE_CH.match(g["ch"]):
                    x.fill = cinza
            det.cell(row=row, column=4).number_format = "dd/mm/yyyy"
            det.cell(row=row, column=7).number_format = "hh:mm"
            det.cell(row=row, column=8).number_format = "hh:mm"
            det.cell(row=row, column=10).number_format = '0;-0;"-"'
            row += 1
        faixas[c["matricula"]] = (ini, row - 1)
    N = row - 1
    det.freeze_panes = "C2"
    det.auto_filter.ref = f"A1:J{N}"
    det.conditional_formatting.add(f"J2:J{N}", CellIsRule(operator="greaterThanOrEqual", formula=["30"],
                                   fill=PatternFill("solid", fgColor="F8CBAD"), font=Font(name=F, bold=True, color="9C0006")))
    det.conditional_formatting.add(f"J2:J{N}", CellIsRule(operator="between", formula=["1", "29"],
                                   fill=PatternFill("solid", fgColor="FFF2CC")))

    # Resumo, do maior para o menor atraso
    periodo = f"{MESES[r['mes']]}/{r['ano']}"
    ultimo = calendar.monthrange(r["ano"], r["mes"])[1]
    res["A1"] = f"Consolidado de atrasos na entrada – {periodo} (01/{r['mes']:02d} a {ultimo}/{r['mes']:02d})"
    res["A1"].font = Font(name=F, size=14, bold=True, color="1F4E78")
    if r["gestor"]:
        res["A2"] = f"Gestor: {r['gestor']}"
        res["A2"].font = Font(name=F, size=10, italic=True)
    header(res, 4, ["Matrícula", "Colaborador", "Cargo", "Escala(s) no mês", "Dias trabalhados", "Dias com atraso",
                    "% dias com atraso", "Total de atraso (min)", "Total de atraso (h:mm)", "Maior atraso (min)",
                    "Média por atraso (min)"], [11, 36, 22, 24, 11, 11, 11, 12, 12, 11, 12])
    D = "'Detalhe diário'!"
    ordem = sorted(r["colaboradores"], key=lambda c: -sum(g.get("atraso", 0) for g in c["registros"]))
    for i, c in enumerate(ordem):
        rr = 5 + i
        a, b = faixas[c["matricula"]]
        J, G, H = (f"{D}${k}${a}:${k}${b}" for k in "JGH")
        chs = sorted({g["ch"] for g in c["registros"] if RE_CH.match(g["ch"])})
        vals = [c["matricula"], c["nome"], c["cargo"],
                " / ".join(f"{k} ({r['escalas'].get(k, '?')})" for k in chs),
                f'=SUMPRODUCT(({G}<>"")*({H}<>""))', f'=COUNTIF({J},">0")', f"=IF(E{rr}=0,0,F{rr}/E{rr})",
                f"=SUM({J})", f"=H{rr}/1440", f"=MAX({J})", f"=IF(F{rr}=0,0,H{rr}/F{rr})"]
        for col, v in enumerate(vals, 1):
            x = res.cell(row=rr, column=col, value=v)
            x.font, x.border = base, brd
            if col >= 4:
                x.alignment = ctr
        res.cell(row=rr, column=8).font = Font(name=F, size=10, bold=True)
        res.cell(row=rr, column=7).number_format = "0%"
        res.cell(row=rr, column=9).number_format = "[h]:mm"
        res.cell(row=rr, column=11).number_format = "0.0"
    L = 4 + len(ordem)
    T = L + 1
    res.cell(row=T, column=2, value="TOTAL DA EQUIPE")
    for col, f in [(5, f"=SUM(E5:E{L})"), (6, f"=SUM(F5:F{L})"), (7, f"=IF(E{T}=0,0,F{T}/E{T})"),
                   (8, f"=SUM(H5:H{L})"), (9, f"=H{T}/1440"), (10, f"=MAX(J5:J{L})"), (11, f"=IF(F{T}=0,0,H{T}/F{T})")]:
        res.cell(row=T, column=col, value=f)
    for col in range(1, 12):
        x = res.cell(row=T, column=col)
        x.font, x.fill, x.border = Font(name=F, size=10, bold=True), PatternFill("solid", fgColor="DDEBF7"), brd
        if col >= 4:
            x.alignment = ctr
    res.cell(row=T, column=7).number_format = "0%"
    res.cell(row=T, column=9).number_format = "[h]:mm"
    res.cell(row=T, column=11).number_format = "0.0"
    res.conditional_formatting.add(f"H5:H{L}", DataBarRule(start_type="num", start_value=0, end_type="max", color="E06666"))
    notas = [
        "Critérios do cálculo",
        "• Atraso = 1º horário da coluna 'Jornada' − entrada prevista no código de horário (CH) do dia, menos a "
        "tolerância definida na aba Escalas (0 = conta todo minuto).",
        "• Considera apenas o atraso na entrada. Saídas antecipadas não entram no cálculo.",
        "• O CH é lido dia a dia, então trocas de escala no meio do mês são respeitadas.",
        "• Marcações incluídas manualmente e aprovadas são usadas como estão na coluna 'Jornada'.",
        "• Folga, DSR, compensado, feriado, licenças, acidente de trabalho, treinamento e trabalho externo não geram atraso.",
        "• Casos que merecem conferência estão na aba 'Pontos de atenção'.",
    ]
    for i, t in enumerate(notas):
        res.cell(row=T + 2 + i, column=1, value=t).font = Font(name=F, size=9, bold=(i == 0), italic=(i > 0))
    res.freeze_panes = "C5"

    # Pontos de atenção
    header(pa, 1, ["Colaborador", "Data", "Ponto de atenção"], [36, 12, 90])
    for i, (nome, data, txt) in enumerate(sorted(r["atencao"], key=lambda t: (t[0], t[1] or dt.date.min)), 2):
        for col, v in enumerate([nome, data, txt], 1):
            x = pa.cell(row=i, column=col, value=v)
            x.font, x.border = base, brd
        pa.cell(row=i, column=2).number_format = "dd/mm/yyyy"
        pa.cell(row=i, column=2).alignment = ctr
    if not r["atencao"]:
        pa.cell(row=2, column=1, value="Nenhum ponto de atenção encontrado.").font = base

    wb.calculation = CalcProperties(fullCalcOnLoad=True)
    wb.save(saida)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("entrada")
    ap.add_argument("--saida")
    ap.add_argument("--tolerancia", type=int, default=0, help="minutos de tolerância (padrão 0)")
    a = ap.parse_args()
    r = processa(a.entrada, a.tolerancia)
    saida = a.saida or f"Consolidado_Atrasos_{MESES[r['mes']]}_{r['ano']}.xlsx"
    gera_planilha(r, saida)
    resumo = []
    for c in r["colaboradores"]:
        regs = c["registros"]
        atrasos = [g["atraso"] for g in regs if g.get("atraso")]
        resumo.append(dict(nome=c["nome"], matricula=c["matricula"],
                           escalas=sorted({g["ch"] for g in regs if RE_CH.match(g["ch"])}),
                           dias_trabalhados=sum(1 for g in regs if g.get("trabalhou")),
                           dias_com_atraso=len(atrasos), total_min=sum(atrasos), maior_min=max(atrasos, default=0)))
    resumo.sort(key=lambda x: -x["total_min"])
    print(json.dumps(dict(
        arquivo=saida, periodo=f"{MESES[r['mes']]}/{r['ano']}", gestor=r["gestor"], escalas=r["escalas"],
        tolerancia_min=r["tolerancia"], total_equipe_min=sum(x["total_min"] for x in resumo), colaboradores=resumo,
        pontos_de_atencao=[f"{n} {d.strftime('%d/%m') if d else ''}: {t}" for n, d, t in r["atencao"]],
    ), ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
