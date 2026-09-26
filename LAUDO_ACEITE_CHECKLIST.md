# Laudo PDF — critérios de aceite

Use este checklist após cada release que altere Configurações ou o gerador de PDF.

## Configurações

- [ ] Barra de pré-visualização das 4 zonas reage aos limites (etapa Vazão / ha).
- [ ] Cores Azul / Verde / Grafite / Vinho / **Personalizada** com seletor HSV+hex.
- [ ] Pré-visualização do cabeçalho com contraste legível (C4).
- [ ] Texto da marca: consultor/empresa no cabeçalho; SoloForte no rodapé.
- [ ] CREA no perfil e na assinatura do PDF (se preenchido).
- [ ] Ortografia/capitalização em campos de texto livre.

## Laudo (10 pontas, 30 ha, sem fotos)

- [ ] Arquivo: `Laudo_Regulagem_<produtor_ou_fazenda>_<AAAA-MM-DD>.pdf`.
- [ ] Página 2: veredito, O que fazer, comparativo 2 linhas, motivo, Dados usados.
- [ ] Total exibido = soma das parcelas (ex.: R$ 446,63).
- [ ] “Como calculamos” com cm ÷ 100 e regra da troca completa.
- [ ] Sem payback / apl. no corpo; “perda” só na linha metodológica.
- [ ] **2 páginas** quando possível (10 pontas, sem fotos).
- [ ] Rodapé: logo + SoloForte + página + data; Author do PDF = SoloForte.

## Cenários de recomendação

- [ ] Bico R$ 30 → troca completa (R$ 300 < desperdício).
- [ ] Bico R$ 50 → troca unitária 5D e 6D (R$ 100).

## Escala

- [ ] Export 30 pontas (gráficos em blocos).
- [ ] Export 60 pontas.
- [ ] Laudo com até 12 fotos; dropdown de ponta na foto.

## Gate técnico

- [ ] `flutter analyze` sem issues.
- [ ] `flutter test` passando.
- [ ] PDF aberto no celular (WhatsApp): texto legível sem zoom exagerado.

_Registro: preencher data e build em `AGENTIPA.md` após QA._
