# Ponta Verde

Calculadora offline de regulagem para pulverizadores e plantadeiras, feita
para consultores agronômicos, RTVs e técnicos em campo.

## O que o app faz

- Regulagem de pulverizador em 4 etapas: contexto, parâmetros, cálculos e
  medição por ponta, com classificação automática (Ideal / Irregular /
  Desgaste) e análise econômica de troca de bicos.
- Regulagem de plantadeira: largura útil e rendimento operacional.
- Histórico com busca, exclusão com desfazer e detalhe somente leitura.
- Configurações com limites ajustáveis e backup em JSON (exportar/importar).
- 100% offline — nenhum dado sai do dispositivo, nenhuma conta é exigida.

## Rodando o projeto

```
flutter pub get
flutter run
```

## Testes

```
flutter analyze
flutter test
```

## Documentação do projeto

- [`PONTA VERDE PRD.md`](PONTA%20VERDE%20PRD.md) — requisitos de produto.
- [`CALCULOS/`](CALCULOS) — especificação de cada fórmula de regulagem.
- [`AGENTIPA.md`](AGENTIPA.md) — histórico de builds e envio à App Store.
- [`STORE.md`](STORE.md) — texto da ficha na App Store Connect.
- [`docs/`](docs) — política de privacidade e página de suporte do app.
