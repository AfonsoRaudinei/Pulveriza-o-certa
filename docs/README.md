# Site do Ponta Verde (GitHub Pages)

Três páginas estáticas, sem build, sem dependências — só HTML/CSS:

- `index.html` — página inicial, com links para as duas abaixo.
- `privacidade.html` — Política de Privacidade.
- `suporte.html` — Central de Suporte.

## Como publicar no GitHub Pages

1. Suba este repositório para o GitHub (ou só a pasta `docs/`, se preferir
   outro repositório).
2. No GitHub: **Settings → Pages**.
3. Em **Build and deployment → Source**, escolha **Deploy from a branch**.
4. Em **Branch**, escolha a branch (ex.: `main`) e a pasta **`/docs`** → **Save**.
5. Aguarde alguns minutos. O GitHub mostra a URL final no topo dessa mesma
   página, algo como:
   - `https://<seu-usuario>.github.io/<repositorio>/`
   - `https://<seu-usuario>.github.io/<repositorio>/privacidade.html`
   - `https://<seu-usuario>.github.io/<repositorio>/suporte.html`

## No App Store Connect

Em **App Information** (ficha do app), cole:
- **Privacy Policy URL** → o link de `privacidade.html`
- No cartão de cada versão, em **App Review Information → Support URL** →
  o link de `suporte.html` (ou `index.html`, se preferir a página inicial)

Depois de me passar a URL final, eu atualizo os links em `STORE.md` e no
restante do projeto.
