# Guía Rápida: CI/CD con GitHub Actions (Quickstart)

Esta guía describe cómo implementar la arquitectura de Integración y Entrega Continua (CI/CD) estandarizada en cualquier repositorio nuevo de la organización, garantizando calidad, verificación continua y despliegue seguro a GitHub Container Registry (GHCR).

---

## 1. Cinco Pasos para Activar GitHub Actions en un Proyecto Nuevo

1. **Copiar el Workflow:**
   Copia el archivo `template.yml` en la ruta `.github/workflows/ci.yml` de tu repositorio.
2. **Configurar SonarCloud (`sonar-project.properties`):**
   Crea o ajusta el archivo `sonar-project.properties` en la raíz de tu proyecto reemplazando los identificadores de tu organización y proyecto:
   ```properties
   sonar.projectKey=<tu-organizacion>_<tu-proyecto>
   sonar.organization=<tu-organizacion>
   sonar.projectName=<tu-proyecto>
   sonar.projectVersion=1.0
   sonar.sources=src
   sonar.tests=src
   sonar.test.inclusions=src/tests.py,src/**/test_*.py
   sonar.exclusions=src/tests.py,src/**/__pycache__/**
   sonar.python.version=3.11
   sonar.python.coverage.reportPaths=coverage.xml
   sonar.qualitygate.wait=true
   ```
3. **Cargar los Secretos Requeridos:**
   Dirígete a **Settings > Secrets and variables > Actions** en GitHub y añade `SONAR_TOKEN` y `DISCORD_WEBHOOK`.
4. **Habilitar Permisos para GitHub Container Registry (GHCR):**
   En **Settings > Actions > General**, en la sección *Workflow permissions*, asegúrate de marcar:
   - **Read and write permissions** (o permitir que los workflows gestionen paquetes `packages: write`).
5. **Comprobar la Ejecución:**
   Haz un push de una rama y abre un Pull Request hacia `main`, o dispara manualmente el workflow desde la pestaña **Actions > CI/CD Pipeline > Run workflow**.

---

## 2. Configuración de Secretos (Repository Secrets)

Para registrar secretos en GitHub: navega a **Settings > Secrets and variables > Actions > New repository secret**.

| Secreto | Descripción | ¿Dónde obtenerlo? |
| :--- | :--- | :--- |
| `SONAR_TOKEN` | Token de autenticación para enviar análisis y verificar el Quality Gate en SonarCloud. | En SonarCloud: **My Account > Security > Generate Token** (tipo *User Token*). |
| `DISCORD_WEBHOOK` | URL del canal de Discord donde se publicarán alertas de fallo y reportes de build. | En Discord: **Ajustes del Canal > Integraciones > Webhooks > Nuevo Webhook > Copiar URL**. |
| `GITHUB_TOKEN` | Token generado internamente por GitHub con permisos definidos por el workflow. | **Automático:** No se configura manualmente; GitHub lo inyecta en cada ejecución. |

---

## 3. Configuración Manual de Branch Protection en `main`

Para asegurar el principio fundamental de V&V (**"ningún código llega a `main` sin verificarse"**), es mandatorio proteger la rama principal:

1. Ve a **Settings > Branches** en tu repositorio de GitHub.
2. En la sección **Branch protection rules**, haz clic en **Add branch protection rule**.
3. En **Branch name pattern**, escribe: `main`.
4. Activa las siguientes casillas:
   - [x] **Require a pull request before merging:** Evita que desarrolladores hagan push directo a producción.
   - [x] **Require status checks to pass before merging:** Obliga a que las pruebas pasen antes del merge.
   - [x] **Require branches to be up to date before merging:** Asegura que el código esté probado contra la última versión de `main`.
5. En la barra de búsqueda de *Status checks*, busca y selecciona individualmente cada combinación de la matriz:
   - `test (3.10)`
   - `test (3.11)`
   - `test (3.12)`
6. (Recomendado) Activa **Do not allow force pushes** y **Do not allow deletions**.
7. Haz clic en **Create** / **Save changes**.

---

## 4. Cómo Leer los Logs Cuando Falla un Job

Cuando un pull request o commit falle, sigue este procedimiento de diagnóstico rápido:

```
[GitHub PR] -> Pestaña "Checks" o "Actions" -> Clic en el Run en rojo -> Inspeccionar Job fallido
```

1. **Identificar la fase que falló:**
   - **Check linting (Ruff):** Si falla este paso, revisa los errores de estilo o sintaxis reportados. Puedes reproducir y corregir localmente ejecutando `ruff check .` o `ruff check --fix .`.
   - **Test with pytest and generate coverage:** Observa las líneas en rojo al final de la traza de pytest. Indicarán qué aserción falló (`assert expected == actual`) y el archivo/línea exacto.
   - **SonarQube Scan:** Si falla indicando `Quality Gate failed`, el código no cumple los umbrales de cobertura mínima, o introdujo nuevos *bugs*, vulnerabilidades o *code smells*.
   - **Build and Push Docker Image:** Revisa fallos en directivas del `Dockerfile` o falta de permisos `packages: write`.
2. **Descarga e Inspección de Artefactos de Prueba:**
   - En la parte inferior de la página principal del Run de Actions, localiza la sección **Artifacts**.
   - Encontrarás un archivo descargable por versión: `test-results-python-3.10`, `test-results-python-3.11` y `test-results-python-3.12`.
   - Descarga y descomprime el ZIP:
     - Abre `htmlcov/index.html` en tu navegador para ver un mapa interactivo de qué líneas no están cubiertas por pruebas unitarias.
     - Revisa `junit.xml` para trazas de errores estructuradas.
