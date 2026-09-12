# Ficha da loja — Ponta Verde

Texto de referência para preencher o App Store Connect. Copie e ajuste conforme necessário.

## Identidade

- **Nome do app:** Ponta Verde
- **Subtítulo** (30 caracteres): `Regulagem de pulverizador`
- **Categoria primária:** Produtividade
- **Categoria secundária (opcional):** Utilitários
- **Classificação etária:** 4+ (sem conteúdo sensível)
- **Idioma da ficha:** Português (Brasil) — único idioma do app

## Palavras-chave (100 caracteres, separadas por vírgula, sem espaço após a vírgula)

```
pulverizador,plantadeira,regulagem,agricultura,bico,agronomia,calibração,lavoura,RTV,agro
```

## Descrição

```
Ponta Verde é a calculadora de regulagem para quem trabalha em campo: consultores agronômicos,
RTVs e técnicos que precisam calibrar pulverizadores e plantadeiras com precisão, sem depender
de internet.

REGULAGEM DE PULVERIZADOR
Informe vazão, velocidade e espaçamento entre bicos e o app calcula o L/min ideal por ponta.
Meça cada bico individualmente e veja a classificação automática — Ideal, Irregular ou
Desgaste — com base nos limites que você configura.

ANÁLISE ECONÔMICA
O Ponta Verde estima a perda por vazamento e compara com o custo de troca dos bicos, indicando
se vale a pena trocar todas as pontas ou só as que estão fora da tolerância.

REGULAGEM DE PLANTADEIRA
Calcule largura útil e rendimento operacional a partir do número de linhas, espaçamento,
velocidade e eficiência de plantio.

HISTÓRICO E BACKUP
Toda regulagem fica salva no histórico do aparelho, com busca por produtor ou fazenda.
Exporte um backup em JSON quando quiser e importe de volta em outro momento ou aparelho.

100% OFFLINE
Todos os cálculos rodam no próprio iPhone. O app não exige conta, não tem anúncios e não
coleta nenhum dado.
```

## Texto promocional (170 caracteres, editável sem nova versão)

```
Regule pulverizadores e plantadeiras no campo, mesmo sem internet. Medição por ponta,
classificação automática e análise de troca de bicos.
```

## URLs obrigatórias

- **Política de Privacidade:** https://afonsoraudinei.github.io/Pulveriza-o-certa/docs/privacidade.html
- **URL de Suporte:** https://afonsoraudinei.github.io/Pulveriza-o-certa/docs/suporte.html
- **Página inicial (opcional):** https://afonsoraudinei.github.io/Pulveriza-o-certa/docs/
- **URL de marketing:** opcional — deixe em branco se não houver site.

> Fonte: pasta `docs/` publicada via GitHub Pages (branch `main`, pasta `/docs`).
> Instruções em `docs/README.md`. Confirmar que as URLs abrem em navegador anônimo antes de colar no App Store Connect.

## Questionário de privacidade (App Privacy)

Com a fonte Inter embutida (sem `google_fonts` em runtime) e nenhum SDK de rede no projeto,
a resposta correta em **todas** as categorias do questionário é **"Dados não coletados"**.

## Notas para o revisor (App Review Information)

```
O Ponta Verde é uma calculadora offline de regulagem de pulverizadores e plantadeiras. Não há
conta, login ou cadastro de nenhum tipo — o app abre direto no Dashboard. Não há compras nem
assinaturas. Nenhum dado é coletado ou enviado a servidores; tudo fica salvo localmente no
aparelho.

Fluxo sugerido para revisão:
1. Na aba Início, toque em "+ Nova Regulagem".
2. Preencha Produtor, Fazenda e Máquina (Etapa 1) e avance para os Parâmetros (Etapa 2).
3. Em Medições (Etapa 4), informe um valor para uma ponta e veja a classificação automática.
4. Toque em "Salvar" — a regulagem aparece na aba Regulagens (histórico).
5. Em Config → Exportar Dados, a folha de compartilhamento do sistema abre com o backup em
   JSON (nenhum dado sai do dispositivo sem ação explícita do usuário).

Contato para dúvidas da revisão: raudyneyb@gmail.com
```

## Diretriz 4.3 — apps semelhantes na mesma conta

A conta de desenvolvedor já publica outros apps agrícolas (SoloForte, Caderno de Solo,
AgroCalc, Calculadora do Agro). Antes de enviar o Ponta Verde para revisão:

1. **Avalie remover ou arquivar o registro "AgroCalc" (Apple ID 6760232139)** — está ocioso
   ("Preparar para envio") e é o mais próximo do Ponta Verde, inclusive porque a UI deste app
   ainda usa o nome "AgroCalc" internamente em alguns pontos históricos.
2. Garanta que descrição, palavras-chave, ícone e screenshots do Ponta Verde não se sobreponham
   aos dos outros apps da conta.
3. Se a Apple levantar a diretriz 4.3, responda citando o diferencial: medição individual por
   ponta com classificação automática (Ideal/Irregular/Desgaste) e análise econômica de troca
   de bicos — funcionalidade que os outros apps da conta não têm.

## Screenshots

Necessários apenas para **iPhone** (o app foi limitado a `TARGETED_DEVICE_FAMILY = "1"`,
dispensando iPad). Tamanho mínimo obrigatório: iPhone 6.9" (1320 × 2868 px ou 2868 × 1320 px).
Recomendado 3 a 5 imagens, nesta ordem sugerida:
1. Dashboard (tela inicial)
2. Formulário de Regulagem com a tabela de pontas e os badges de status
3. Análise econômica (recomendação de troca)
4. Histórico de regulagens
5. Configurações

## Conformidade de exportação

Já resolvido: `ITSAppUsesNonExemptEncryption = false` em `ios/Runner/Info.plist`.
