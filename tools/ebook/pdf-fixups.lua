-- Filtro de Pandoc usado únicamente al generar el PDF (motor LaTeX).
--
-- 1) LaTeX no admite un comando de sección (\section, etc.) dentro de un
--    entorno \begin{quote}...\end{quote}. Los blockquotes de Markdown que
--    incluyen un encabezado (por ejemplo "> ## Aviso") son válidos para
--    Pandoc, pero rompen la compilación en LaTeX. Aquí se degrada
--    cualquier Header que aparezca directamente dentro de un BlockQuote a
--    un párrafo en negritas, lo cual es seguro en cualquier formato.
function BlockQuote(el)
  for i, block in ipairs(el.content) do
    if block.t == "Header" then
      el.content[i] = pandoc.Para({ pandoc.Strong(block.content) })
    end
  end
  return el
end

-- 2) El emoji de portapapeles (U+1F4CB) no tiene glifo en ninguna fuente
--    instalada en el entorno de CI (requiere una fuente emoji a color,
--    que XeLaTeX no puede usar como texto). Se sustituye por una viñeta
--    simple para evitar recuadros de "carácter faltante" en el PDF. Otros
--    símbolos del libro (triángulo de advertencia, cruz latina, casilla)
--    sí se resuelven vía una fuente de reserva declarada en el preámbulo
--    de LaTeX, así que conservan su glifo real en el PDF.
function Str(el)
  if el.text:find("\u{1F4CB}") then
    el.text = el.text:gsub("\u{1F4CB}", "\u{2022}")
    return el
  end
end
