# Diseño: Informes Parte 1 y Parte 2 — Visión por Computadora

**Fecha:** 2026-04-29  
**Proyecto:** desk-object-detection (1MTR27 PUCP)  
**Autor:** Jamin Yauri Cajas

---

## Objetivo

Producir dos informes LaTeX completos con figuras generadas automáticamente desde MATLAB:
- **Parte 1:** Actualizar `report.tex` existente agregando figuras de pasos intermedios del preprocessing
- **Parte 2:** Crear `report_parte2.tex` nuevo cubriendo clasificación de iluminación + detección adaptativa

---

## Archivos a crear / modificar

```
docs/report/
  report.tex              ← MODIFICAR (agregar figuras A y B)
  report_parte2.tex       ← CREAR (nuevo documento completo)

results/figures/report/
  parte1/
    pipeline_steps_NL.png       ← montage 5 pasos, imagen NL
    pipeline_steps_CSL.png      ← montage 5 pasos, imagen CSL
    before_after_NL.png         ← antes/después NL
    before_after_CSL.png        ← antes/después CSL
  parte2/
    detection_steps.png         ← 5 subplots pipeline detección
    results_NL.png              ← panel 3 columnas condición NL
    results_CL.png              ← panel 3 columnas condición CL
    results_LL.png              ← panel 3 columnas condición LL
    results_RL.png              ← panel 3 columnas condición RL
    results_CSL.png             ← panel 3 columnas condición CSL
    gui_screenshot.png          ← captura del UI (ya disponible)

gen_figs_parte1.m           ← CREAR (script generador figuras P1)
gen_figs_parte2.m           ← CREAR (script generador figuras P2)
```

---

## Script gen_figs_parte1.m

Genera figuras para el informe Parte 1.

**Imágenes fuente:**
- NL representativa: `dataset/reference/NL/Small/` (primera disponible)
- CSL difícil: `dataset/reference/CSL/Small/Ft_01_CSL (Small).jpg`

**Figura A — Montage 5 pasos del pipeline** (por imagen):
```
Original → Bilateral → White Balance → CLAHE → Laplaciano
```
- Subplot 1×5, cada panel con título del paso
- Resolución: 150 DPI, ancho: 1600px
- Guardado como `pipeline_steps_NL.png` y `pipeline_steps_CSL.png`

**Figura B — Antes/después** (por imagen):
```
Original (izq) | Preprocesada (der)
```
- Subplot 1×2 con PSNR y SSIM en sgtitle
- Guardado como `before_after_NL.png` y `before_after_CSL.png`

---

## Script gen_figs_parte2.m

Genera figuras para el informe Parte 2.

**Figura D — Pipeline de detección paso a paso** (sobre imagen CSL):
```
1. Preprocesada (RGB)
2. Enhancement FFT (grayscale)
3. Bordes Canny
4. Morfología rellena (imclose+imfill)
5. Detecciones finales (bboxes sobre preprocesada)
```
- Subplot 1×5
- Resolución 150 DPI
- Guardado como `detection_steps.png`

**Figuras E1–E5 — Resultados por condición:**
- 1 imagen representativa por condición (NL/CL/LL/RL/CSL)
- Panel 3 columnas: Original | Preprocesada [cond] | Detecciones: N
- Sgtitle: condición real vs detectada, N objetos, tiempo
- Resolución 150 DPI, 1400×480px
- Guardados como `results_NL.png`, `results_CL.png`, etc.

**Figura F — GUI screenshot:**
- Ya disponible como captura del usuario (CSL, 9 objetos)
- Copiar/incluir directamente en LaTeX

---

## Estructura report.tex (Parte 1) — cambios

Insertar en **Sección 2 (Metodología)**, después de la tabla del pipeline:

```latex
\begin{figure}[H]
\centering
\includegraphics[width=\linewidth]{../../results/figures/report/parte1/pipeline_steps_NL.png}
\caption{Etapas del pipeline sobre imagen NL bien iluminada.}
\end{figure}
\begin{figure}[H]
\centering
\includegraphics[width=\linewidth]{../../results/figures/report/parte1/pipeline_steps_CSL.png}
\caption{Etapas del pipeline sobre imagen CSL (iluminación combinada).}
\end{figure}
```

Insertar en **Sección 5 (Resultados)**, reemplazando placeholder actual:

```latex
\begin{figure}[H]
\includegraphics[width=\linewidth]{../../results/figures/report/parte1/before_after_NL.png}
\caption{NL — alta similitud: pipeline aplica correcciones mínimas.}
\end{figure}
\begin{figure}[H]
\includegraphics[width=\linewidth]{../../results/figures/report/parte1/before_after_CSL.png}
\caption{CSL — corrección activa de iluminación combinada.}
\end{figure}
```

---

## Estructura report_parte2.tex (Parte 2) — completo

### Secciones

1. **Introducción** — objetivo detección, relación con Parte 1, dataset (5 condiciones: NL/CL/LL/RL/CSL)

2. **Clasificación de iluminación** (`classify_lighting.m`)
   - Features: meanL (canal L de Lab), stdL (contraste), rb = mean(R)/mean(B)
   - Tabla de umbrales calibrados desde dataset real
   - Reglas de clasificación (orden: RL→CL→CSL→NL→LL)
   - Accuracy: 14/15 (93%)

3. **Preprocesamiento adaptativo** (`pipeline_preproc.m`)
   - Tabla de parámetros adaptativos por condición
   - Figuras A y B de pasos intermedios
   - Funciones del equipo: `f_bilateral`, `f_laplaciano`

4. **Pipeline de detección** (`get_bboxes.m`)
   - `img_enhancement` (FFT Laplaciano): ecuación H(u,v) = -(u²+v²)
   - Canny: umbrales óptimos [0.05, 0.20]
   - Morfología: `imclose(disk,5)` + `imfill` + `imclearborder`
   - Filtro: minArea=500, maxArea=7500, minAspect=0.5
   - Figura D (5 pasos)

5. **Resultados**
   - Figuras E1-E5 (panel por condición)
   - Tabla resumen: condición real | detectada | N objetos | tiempo

6. **Interfaz interactiva** (`ui_pipeline.m`)
   - Figura F (GUI screenshot)
   - Descripción de controles y uso

7. **Discusión y Conclusión**
   - Fortalezas: pipeline adaptativo por condición, integración de funciones del equipo
   - Limitaciones: detecciones múltiples sobre un mismo objeto, dependencia de Canny en texturas
   - Trabajo futuro: NMS (Non-Maximum Suppression), descriptor de forma para clasificar objeto

---

## Parámetros técnicos LaTeX

- Mismo preámbulo que `report.tex` (paquetes, fuentes, colores de código)
- Título: "Proyecto de Visión por Computadora (1MTR27) — Parte 2: Detección Adaptativa de Objetos en Escritorio"
- Fecha: 29 de abril de 2026
- Figuras: todas con `[H]`, resolución 150 DPI, ancho `\linewidth`

---

## Orden de ejecución

1. Crear `gen_figs_parte1.m` y correr con MATLAB MCP → genera PNGs en `results/figures/report/parte1/`
2. Crear `gen_figs_parte2.m` y correr con MATLAB MCP → genera PNGs en `results/figures/report/parte2/`
3. Modificar `report.tex` (Parte 1) insertando las figuras
4. Crear `report_parte2.tex` (Parte 2) completo
5. Compilar ambos con `pdflatex`
6. Commit y push
