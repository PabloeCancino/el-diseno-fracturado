# Guía: publicar un libro en GitHub + GitHub Pages (mdBook)

Documenta el proceso completo que se siguió para publicar *El Diseño Fracturado*, para reutilizarlo tal cual en los próximos títulos. Son dos partes independientes: **(1)** subir el manuscrito a un repositorio de GitHub y **(2)** desplegarlo como sitio navegable con mdBook. La parte 1 se puede hacer sola (repo con los `.md` en bruto); la parte 2 requiere que la parte 1 ya exista.

---

## Parte 1 — Repositorio en GitHub

### 1.1 Estructura mínima antes del primer commit

```
nombre-del-libro/
├── capitulos/          (o el nombre que prefieras: manuscrito en Markdown)
├── LICENSE.md
├── README.md
└── .gitignore          ← créalo ANTES del primer `git add`
```

### 1.2 Seguridad primero: `.gitignore`

Si el proyecto usa algún script, contenedor Docker o pipeline de publicación automática, casi siempre habrá un `.env` con credenciales (tokens, claves). **Ese archivo nunca debe llegar al repo**, y GitHub no perdona: una vez pusheado un secreto a un repo público, se considera comprometido aunque lo borres después (queda en el historial). Crea `.gitignore` desde el primer commit:

```
# Secretos y configuración local — nunca deben subirse al repo
.env
.env.*

# Salida de compilación de mdBook
/book/

# Archivos de sistema
.DS_Store
Thumbs.db
```

Verifica que no haya quedado nada suelto antes de cada `git add`:

```bash
git status
```

Si algo que no debería estar ahí aparece como "Untracked" o "Changes to be committed", revísalo antes de seguir. Si tienes duda de si un archivo con datos sensibles ya quedó trackeado en un commit anterior, dilo y se revisa antes de tocar nada — no se resuelve a ciegas.

### 1.3 Flujo básico (crear o actualizar)

```bash
cd "ruta/al/repo"
git status                     # qué cambió
git add archivo1 archivo2      # evita `git add .` a ciegas; añade lo que sí revisaste
git commit -m "Mensaje descriptivo"
git push origin main
```

### 1.4 Si el push es rechazado ("non-fast-forward")

Pasa cuando el repo remoto (GitHub) tiene un commit que tu copia local no tiene — por ejemplo, si editaste algo directamente en la web de GitHub. La solución es traer ese cambio antes de subir el tuyo:

```bash
git pull origin main
```

Esto puede abrir un editor de texto pidiendo un mensaje de merge — no hay que escribir nada, solo guardar y cerrar (Vim: `Esc` → `:wq` → Enter; Notepad/VS Code: `Ctrl+S` y cerrar). Luego:

```bash
git push origin main
```

---

## Parte 2 — Despliegue como libro (mdBook + GitHub Pages)

Convierte el repo en un sitio web navegable y con buscador, publicado gratis en `https://<usuario>.github.io/<repo>/`.

### 2.1 Estructura que espera mdBook

```
nombre-del-libro/
├── book.toml
├── src/
│   ├── SUMMARY.md
│   ├── 00_presentacion.md
│   ├── 01_capitulo1.md
│   └── ...
└── .github/
    └── workflows/
        └── deploy.yml
```

mdBook busca los capítulos dentro de `src/`, no en `capitulos/`. Si ya tienes el manuscrito en `capitulos/`, dos opciones: mover los archivos con `git mv capitulos/*.md src/` (conserva el historial de cada archivo), o dejar `capitulos/` como está y apuntar `src = "capitulos"` en `book.toml`. En *El Diseño Fracturado* se optó por mantener ambas carpetas en paralelo — funciona, pero exige acordarte de editar los dos lados cada vez que cambies un capítulo. Para el próximo título, mejor evitarlo: un solo árbol de origen.

### 2.2 `book.toml` (plantilla)

```toml
[book]
title = "Título del libro"
authors = ["Nombre del autor"]
description = "Descripción breve"
language = "es"
src = "src"

[output.html]
default-theme = "light"
preferred-dark-theme = "navy"
git-repository-url = "https://github.com/<usuario>/<repo>"
edit-url-template = "https://github.com/<usuario>/<repo>/edit/main/{path}"

[output.html.search]
enable = true
limit-results = 20
```

Solo hay que cambiar `title`, `authors`, `description` y las dos URLs de `<usuario>/<repo>`.

### 2.3 `src/SUMMARY.md`

Índice de navegación del sitio — controla qué aparece en el menú lateral y en qué orden. Un capítulo que exista como archivo pero no esté listado aquí, simplemente no aparece en el sitio:

```markdown
# Índice

[Presentación](./00_presentacion.md)

- [Capítulo 1 — Título](./01_capitulo1.md)
- [Capítulo 2 — Título](./02_capitulo2.md)
```

### 2.4 Workflow de GitHub Actions (`.github/workflows/deploy.yml`)

Compila el libro y lo publica automáticamente en cada push a `main`:

```yaml
name: Publicar libro en GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Descargar el repositorio
        uses: actions/checkout@v4

      - name: Instalar mdBook
        uses: peaceiris/actions-mdbook@v2
        with:
          mdbook-version: "latest"

      - name: Compilar el libro
        run: mdbook build

      - name: Configurar GitHub Pages
        uses: actions/configure-pages@v5

      - name: Subir el sitio compilado
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./book

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Publicar en GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

Se copia tal cual — no depende del título del libro.

### 2.5 Activar GitHub Pages (el paso que más falla)

**Este paso va ANTES del primer push con el workflow, no después.** Si el workflow corre sin que Pages esté activado, falla con `HttpError: Not Found — Get Pages site failed`.

1. En el repo (no en tu cuenta): pestaña **Settings**.
2. Menú lateral → **Pages**.
3. En "Build and deployment → Source", selecciona **GitHub Actions** (no "Deploy from a branch").
4. Confirma que diga "GitHub Pages source saved".

**No toques el campo "Custom domain"** salvo que tengas un dominio propio comprado. Ahí NO va la URL de `usuario.github.io` — ese campo espera un dominio desnudo (`midominio.com`), sin `https://` ni ruta; si pegas la URL completa, GitHub la rechaza con "Domain is not a valid public domain". Déjalo vacío: la URL `usuario.github.io/repo` se genera sola.

### 2.6 Verificar el despliegue

Pestaña **Actions** del repo → el workflow "Publicar libro en GitHub Pages" debe aparecer en verde. Si falló en el primer intento porque Pages no estaba activado todavía, no hace falta un push nuevo — el workflow tiene `workflow_dispatch`, así que se puede relanzar a mano: **Actions → (nombre del workflow) → Run workflow → Run workflow**.

Los warnings sobre "Node.js 20 is deprecated" en las anotaciones son informativos — GitHub sigue ejecutando las actions igual, forzándolas a Node 24. No bloquean el despliegue y no requieren acción mientras el run diga "Success".

Sitio final: `https://<usuario>.github.io/<repo>/`.

### 2.7 Contenido administrativo: que viva en el libro, no solo en el README

El sitio publicado se compila **únicamente** desde `src/` — el `README.md` de la raíz no se incluye nunca en el sitio; solo lo ve quien navega el repo en GitHub. Licencia, cómo citar y datos de contacto deben repetirse dentro de algún capítulo de `src/` (recomendado: al final de la Presentación), o un lector que entra directo al sitio publicado nunca los ve.

---

## Checklist para el próximo título

1. Copia `capitulos/` (manuscrito) a `src/`, con `SUMMARY.md` actualizado.
2. Copia `book.toml` y edita título, autor, descripción y las dos URLs de GitHub.
3. Copia `.github/workflows/deploy.yml` tal cual.
4. Copia `.gitignore` tal cual.
5. Añade la sección de licencia/cita/contacto al final de la Presentación, dentro de `src/`.
6. Activa Pages (Settings → Pages → Source → GitHub Actions) **antes** del primer push.
7. `git add` → `git commit` → `git push origin main`.
8. Verifica en Actions que el run quede en verde.
9. Abre `https://<usuario>.github.io/<repo>/` y confirma que el contenido — incluida la licencia — se ve bien.
