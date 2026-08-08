# Guía: sitio navegable con mdBook + GitHub Pages

Esto es independiente del contenedor Docker. No lo toca, no depende de él. Es
configuración que vive directamente en el repo del libro (`el-diseno-fracturado`
u otro).

## 1. Reestructurar carpetas

mdBook espera los capítulos dentro de `src/`, no en `capitulos/`. Desde la raíz
del repo del libro:

```bash
mkdir -p src
git mv capitulos/*.md src/
```

(`git mv` conserva el historial de cada archivo; un `mv` + `git add` normal
también funciona pero pierde la trazabilidad del historial por commit.)

## 2. Copiar estos tres archivos a la raíz del repo del libro

- `book.toml` → raíz del repo (edita `title`, `git-repository-url` y
  `edit-url-template` si es un libro distinto a El Diseño Fracturado).
- `src/SUMMARY.md` → dentro de `src/`, junto a los capítulos que ya moviste.
- `.github/workflows/deploy.yml` → tal cual, en esa misma ruta.

## 3. Activar GitHub Pages en el repo

En GitHub: **Settings → Pages → Build and deployment → Source → GitHub
Actions**. No selecciones "Deploy from a branch" — el workflow ya se encarga
de publicar mediante `actions/deploy-pages`.

## 4. Probar

Haz push a `main`. En la pestaña **Actions** del repo verás correr el
workflow "Publicar libro en GitHub Pages". Si termina en verde, el sitio
queda en `https://pabloecancino.github.io/el-diseno-fracturado/`.

## 5. Verificar localmente antes de hacer push (opcional pero recomendado)

Si instalas mdBook en tu máquina (`cargo install mdbook`, o el binario
precompilado desde la página de releases), puedes correr:

```bash
mdbook serve
```

y revisar el sitio en `http://localhost:3000` antes de publicarlo — así ves
errores de `SUMMARY.md` (rutas rotas, capítulos no listados) sin gastar una
corrida del Action.

## Nota sobre lo que NO cambia

- El pipeline Docker (PDF/DOCX/EPUB) sigue funcionando igual, para las
  versiones descargables.
- El repo sigue teniendo `capitulos/` como Markdown fuente si prefieres no
  moverlo — en ese caso, ajusta `src = "capitulos"` en `book.toml` en vez de
  mover los archivos a `src/`. Es una preferencia de organización, no un
  requisito técnico.
- Los tres pendientes de gobernanza que ya identificamos (correo
  institucional, referencia a `evaluacion/` sin respaldo verificable, y el
  resto del checklist de riesgo por repo) siguen siendo independientes de
  esto — móntalo cuando quieras, pero no reemplaza esas decisiones.
