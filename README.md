# Práctica Github Actions

## ¿Qué son las GitHub Actions?
GitHub Actions es una herramienta de integración continua (CI) y entrega/despliegue continuo (CD) integrada directamente en GitHub. Permite automatizar tareas dentro del ciclo de vida de desarrollo de software, como:

- Compilar: Automatizar la construcción de una aplicación, como compilar código o instalar dependencias.
- Pruebas: Ejecutar pruebas automatizadas para verificar la calidad del código.
- Despliegue: Implementar una aplicación en un servidor, servicio en la nube o infraestructura específica.
- Otras tareas: Como formatear código, etiquetar versiones, notificaciones, entre otras.

## Características principales

### `Workflows`:

Son configuraciones que definen qué acciones realizar en ciertos eventos (como un push, un pull request o el cronograma de tiempo).
Se definen en archivos YAML dentro de la carpeta .github/workflows.

### `Eventos`:

Los flujos de trabajo se disparan mediante eventos. Ejemplos:
- `push`: Cada vez que se suben cambios a un repositorio.
- `pull_request`: Cuando se crea o modifica un pull request.
- `schedule`: Ejecutar en horarios específicos.
- `workflow_dispatch`: Ejecución manual.

### `Jobs`:

Son pasos agrupados que se ejecutan en paralelo o secuencialmente dentro de un flujo de trabajo.

### `Steps`:

Son tareas individuales que se ejecutan dentro de un job. Cada step realiza una acción específica, como ejecutar un comando, usar una acción predefinida o instalar dependencias..

### `Runners`:

Son máquinas (virtuales o físicas) que ejecutan las tareas definidas en los workflows.
GitHub ofrece runners hospedados (Linux, macOS, Windows) o puedes usar tus propios runners.

### `Marketplace`:

Una biblioteca de acciones reutilizables creadas por la comunidad para integrar herramientas populares como Docker, Node.js, AWS, entre otras.

## Que conseguimos con las GitHub Actions

- Automatización del ciclo de vida del desarrollo
- Detección temprana de errores
- Mejora en la calidad del código
- Optimización de tiempo
- Despliegues consistentes
- Mayor colaboración en equipo
- Centralización
- Mayor rapidez en los lanzamientos

## Ventajas de GitHub Actions

- `Integración nativa`: No necesitas configurar herramientas externas; todo está dentro de GitHub.
- `Flexibilidad`: Puedes personalizar flujos para adaptarlos a tus necesidades.
- `Automatización completa`: Desde pruebas hasta despliegues y mantenimientos rutinarios.
- `Gratuito para proyectos públicos`: Incluye minutos gratuitos para repositorios públicos y una cuota mensual para repositorios privados.


---


# Workflow configurado:
En este proyecto se ha configurado un workflow para mejorar y automatizar el desarrollo, las pruebas, y el despliegue de la aplicación Next.js.

A continuación vamos a describir el archivo YAML generado, y cada uno de los jobs:

```yaml
# Nombre del workfow
name: nodejs-blog-practica

# Evento: Se ejecuta cuando se hace push a la rama main
on:
  push:
    branches:
      - main

# Conjunto de jobs
jobs:
```

### `linter_job`

**Descripción**:

Analiza el código fuente de la aplicación para identificar errores, inconsistencias o problemas de estilo, sin necesidad de ejecutarlo. Su objetivo principal es mejorar la calidad del código y asegurarse de que cumpla con ciertos estándares definidos.

```yaml
    linter_job:
    # Runner: Se ejecuta en una máquina virtual de Ubuntu
    runs-on: ubuntu-latest

    # Conjunto de steps
    steps:
        # GitHub Action: Descarga el contenido del repositorio en la máquina virtual
        - name: Checkout repository
          uses: actions/checkout@v3

        # GitHub Action: Configura la versión de Node.js que se usará
        - name: Setup Node
          uses: actions/setup-node@v3
          with:
            node-version: 16

        # Instala las dependencias definidas en package.json
        - name: Install dependencies
          run: npm install

        # Ejecuta linter para verificar la sintaxis del código
        - name: Run Linter
          run: npm run lint
```

**Consideraciones**:

![alt text](<Captura de pantalla 2025-01-11 150935.png>)

Este paso nos devuelve errores de código:

 - En el archivo ./pages/api/users/[id].js nos marca errores en el uso de comillas simples y el uso de "var" en la declaración de la variable.
 - En el archivo ./pages/api/users/index.js nos marca errores en el uso de comillas simples.

Los solventamos antes de continuar con el resto de jobs.

---

### `cypress_job`

**Descripción**:

Ejecuta pruebas end-to-end. Prueba la interfaz de usuario (UI) y la experiencia del usuario en el navegador.

```yaml
    cypress_job:
        # Runner: Se ejecuta en una máquina virtual de Ubuntu
        runs-on: ubuntu-latest
        # Dependencia: No se ejecutará hasta que termine linter_job
        needs: linter_job
        
        # Conjunto de steps
        steps:
        # GitHub Action: Descarga el contenido del repositorio en la máquina virtual
        - name: Checkout repository
          uses: actions/checkout@v4

        # Instala las dependencias definidas en package.json
        - name: Install dependencies
          run: npm install

        # Construye la app Next antes de arrancarla
        - name: Build Next app
          run: npm run build

        # Arranca el servidor en segundo plano
        - name: Start Next server
          run: |
          npm run start &
          echo "Server started in background"

        # Espera hasta que localhost:3000 esta listo
        - name: Wait for server
          run: npx wait-on http://localhost:3000 --timeout=60000

        # Ejecuta los tests de Cypress aunque falle. Crea cypress_exitcode.txt
        - name: Run Cypress
          id: run_cypress
          continue-on-error: true
          run: |
          # Desactiva 'exit on error' en Bash para que si Cypress falla, este script continúe
          set +e
          npx cypress run
          EXIT_CODE=$?
          set -e

          echo "Cypress exit code was: $EXIT_CODE"
          echo "$EXIT_CODE" > cypress_exitcode.txt
          ls -l
          cat cypress_exitcode.txt

        # Lee el exit code y crea result.txt con "success" o "failure"
        - name: Evaluate Cypress results
          run: |
          exit_code=$(cat cypress_exitcode.txt)

          if [ "$exit_code" -eq 0 ]; then
              echo "success" > result.txt
          else
              echo "failure" > result.txt
          fi

          echo "Contenido de result.txt:"
          cat result.txt

        # GitHub Action: Sube el archivo result.txt como artefacto
        - name: Upload Cypress results
          uses: actions/upload-artifact@v4
          with:
            name: cypress-result
            path: result.txt
```

---

### `add_badge_job`

**Descripción**:

Actualiza el archivo README.md con un badge que refleja los resultados de las pruebas Cypress.

```yaml
    add_badge_job:
        # Runner: Se ejecuta en una máquina virtual de Ubuntu
        runs-on: ubuntu-latest
        # Dependencia: No se ejecutará hasta que termine cypress_job
        needs: cypress_job

        # Conjunto de steps
        steps:
        # GitHub Action: Descarga el contenido del repositorio en la máquina virtual
        - name: Checkout repository
            uses: actions/checkout@v4

        # GitHub Action: Descarga del artefacto creado en cypress_job
        - name: Download cypress artifact
            uses: actions/download-artifact@v4
            with:
              name: cypress-result
              path: .

        # Genera un output con la lectura de result.txt
        - name: Set outcome output
            id: set_outcome
            run: echo "::set-output name=cypress_outcome::$(cat result.txt)"

        # Custom GitHub Action: actualiza el README
        - name: Update README with badge
            uses: ./ #action.yml
            with:
            # outcome es el valor que contiene "success" o "failure"
            outcome: ${{ steps.set_outcome.outputs.cypress_outcome }}

        # Hace un commit de los cambios del README
        - name: Commit and push changes
            run: |
            git config user.name "github-actions"
            git config user.email "actions@github.com"
            git add README.md
            git commit -m "Actualizando README con badge de Cypress"
            git push
```

**Custom GitHub Action**:

En este job disponemos de una Custom GitHub Action que inserta el budge que refleja los resultados de los test de Cypress. Se compone de estos archivos:

- `action.yaml`

```yaml
name: "Update README Badge"
description: "Modifica el README.md con el badge apropiado en función del outcome de Cypress"
inputs:
  outcome:
    description: "Result of Cypress tests (success or failure)"
    required: true
runs:
  using: "composite"
  steps:
    - name: Ensure script is executable
      shell: bash
      run: chmod +x entrypoint.sh

    - name: Execute script
      shell: bash
      run: ./entrypoint.sh "${{ inputs.outcome }}"
```

- `entrypoint.sh`

```sh
#!/usr/bin/env bash
set -e

OUTCOME=$1
README_FILE="README.md"

# Rutas de los badges
BADGE_FAILURE="https://img.shields.io/badge/test-failure-red"
BADGE_SUCCESS="https://img.shields.io/badge/tested%20with-Cypress-04C38E.svg"

# Texto que indica dónde añadiremos el badge
SEARCH_TEXT="RESULTADOS DE LOS ÚLTIMOS TESTS"

# Dependiendo del OUTCOME, elegimos un badge
if [ "$OUTCOME" = "success" ]; then
    BADGE="$BADGE_SUCCESS"
else
    BADGE="$BADGE_FAILURE"
fi

# Añade la línea del badge al final del README, después de la línea de SEARCH_TEXT
# Verifica si ya existe la sección "RESULTAT DELS ÚLTIMS TESTS"
if grep -q "$SEARCH_TEXT" "$README_FILE"; then
    # Añadimos el badge justo después
    sed -i "/$SEARCH_TEXT/a ![Cypress test badge]($BADGE)" "$README_FILE"
else
    # Si no existe el texto, lo añadimos al final
    echo "" >> "$README_FILE"
    echo "$SEARCH_TEXT" >> "$README_FILE"
    echo "![Cypress test badge]($BADGE)" >> "$README_FILE"
fi

echo "README.md modificado con el badge ($OUTCOME): $BADGE"
```

---

### `deploy_job`

**Descripción**:

Despliega automáticamente la aplicación en la plataforma Vercel.

```yaml
    deploy_job:
        # Runner: Se ejecuta en una máquina virtual de Ubuntu
        runs-on: ubuntu-latest
        # Dependencia: No se ejecutará hasta que termine cypress_job
        needs: cypress_job
        
        # Conjunto de steps
        steps:
        # GitHub Action: Descarga el contenido del repositorio en la máquina virtual
        - name: Checkout repository
            uses: actions/checkout@v4

        # Despliega la aplicación en Vercel
        - name: Deploy to Vercel
            uses: amondnet/vercel-action@v20
            with:
              # Secrets necesarias para conectar con Vercel
              vercel-token: ${{ secrets.VERCEL_TOKEN }}
              vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
              vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
              working-directory: ./
              vercel-args: "--prod"
```

**Consideraciones**:

![alt text](<Captura de pantalla 2025-01-11 210025.png>)

En el repositorio definiremos estas secrets para la action, necesarias para la conexión con Vercel.

![alt text](<Captura de pantalla 2025-01-11 211236.png>)

Al realizarse el workflow, podemos ver como se despliega nuestra aplicación en el dominio proporcionado por Vercel.

---

### `notification_job`

**Descripción**:

Envía notificaciones a Gmail con el estado de cada job ejecutado en el workflow.

```yaml
    notification_job:
        # Runner: Se ejecuta en una máquina virtual de Ubuntu
        runs-on: ubuntu-latest
        # Dependencia: No se ejecutará hasta que terminen toda  la lista de jobs
        needs: [linter_job, cypress_job, add_badge_job, deploy_job]
        # Se ejecutará incluso si alguno de estos jobs falla
        if: always()

        # Conjunto de steps
        steps:
        # GitHub Action: Descarga el contenido del repositorio en la máquina virtual
        - name: Checkout repository
            uses: actions/checkout@v3

        # Custom GitHub Action: Envío del email
        - name: Send notification email
            uses: ./github_actions/send-mail
            env:
              # Secrets necesarias para conectar con Gmail
              GMAIL_USER: ${{ secrets.GMAIL_USER }}
              GMAIL_PASS: ${{ secrets.GMAIL_PASS }}
            with:
              to: ${{ secrets.PERSONAL_EMAIL }}
              subject: "Resultado del workflow ejecutado"
              body: |
                Se ha realizado un push en la rama main que ha provocado la ejecución del workflow "nodejs-blog-practica_workflow" con los siguientes resultados:

                - linter_job: ${{ needs.linter_job.result }}
                - cypress_job: ${{ needs.cypress_job.result }}
                - add_badge_job: ${{ needs.add_badge_job.result }}
                - deploy_job: ${{ needs.deploy_job.result }}
```

**Custom GitHub Action**:

En este job disponemos de una Custom GitHub Action que realizará el envío del email desde Gmail. Se compone de estos archivos:

- `action.yaml`

```yaml
name: "Send Mail Action"
description: "Enviar correo con los resultados"
inputs:
  to:
    required: true
  subject:
    required: true
  body:
    required: true
runs:
  using: "node16"
  main: "dist/index.js"
```

- `index.js`

```js
const core = require('@actions/core');
const nodemailer = require('nodemailer');

async function run() {
    try {
        const to = core.getInput('to');
        const subject = core.getInput('subject');
        const body = core.getInput('body');

        const user = process.env.GMAIL_USER;
        const pass = process.env.GMAIL_PASS;
        if (!user || !pass) {
            throw new Error("Missing credentials for Gmail authentication");
        }

        let transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: { user, pass },
        });

        await transporter.sendMail({
            from: user,
            to,
            subject,
            text: body
        });

        console.log("Correo enviado");
    } catch (error) {
        core.setFailed(error.message);
    }
}

run();
```

Para la ejecución óptima de este script en JavaScript hemos empaquetado todas las dependencias necesarias con ncc. Así el runner no tiene la necesidad de instalar módulos adicionales.

Para ello hemos seguido estos pasos:

- Instalación de ncc en la carpeta de la action.

```
    npm install -g @vercel/ncc
```

- Creación de un archivo `package.json` en la carpeta de la action.

```json
{
    "name": "send-mail",
    "version": "1.0.0",
    "main": "index.js",
    "dependencies": {
        "@actions/core": "^1.10.0",
        "nodemailer": "^6.9.1"
    }
}
```

- Instalación de las dependencias localmente.

```
    npm install
```

- Compilación de la action con ncc para generar un único fichero.

```
    ncc build index.js --out dist
```

**Consideraciones**:

![alt text](<Captura de pantalla 2025-01-11 220105.png>)

En el repositorio definiremos estas secrets para la action, necesarias para la conexión con Gmail.

![alt text](<Captura de pantalla 2025-01-11 225224.png>)

Email enviado después de concluir el job.

---

### `metrics_job`

**Descripción**:

Genera y actualiza dinámicamente métricas de los lenguajes más utilizados por el desarrolador en su perfil de GitHub, junto con otros parámetros en el README.

```yaml
    metrics_job:
        # Runner: Se ejecuta en una máquina virtual de Ubuntu
        runs-on: ubuntu-latest
        # Dependencia: No se ejecutará hasta que termine add_badge_job
        needs: add_badge_job

        # Conjunto de steps
        steps:
        # GitHub Action: Descarga el contenido del repositorio en la máquina virtual
        - name: Checkout current repository
            uses: actions/checkout@v3
        
        # Action: Genera las métricas de GitHub
        - name: Create metrics
            uses: lowlighter/metrics@latest
            with:
            token: ${{ secrets.METRICS_TOKEN }}
            user: fmontesdev
            base: repositories          
            template: classic           
            config_timezone: Europe/Madrid
            plugin_languages: yes
            plugin_languages_sections: most-used
            plugin_languages_indepth: yes
            plugin_languages_recent_load: 20
            plugin_languages_recent_days: 14
            filename: github-metrics.svg

        # Inserta las metricas del archivo svg dentro del bloque delimitado por Markdown
        - name: Replace metrics block with markdown image using sed
            run: |
            sed -i -E '/<!--START_SECTION:metrics-->/, /<!--END_SECTION:metrics-->/c\
            <!--START_SECTION:metrics-->\
            ![GitHub Metrics](/github-metrics.svg)\
            <!--END_SECTION:metrics-->' README.md
            echo "README.md after replacement:"
            cat README.md

        # Hace un commit de los cambios
        - name: Final commit and push
            run: |
            git config --global user.email "f.montesdoria@gmail.com"
            git config --global user.name "fmontesdev"
            git add .
            git commit -m "Añadidas métricas" || echo "No changes to commit"
            git pull --rebase --strategy-option=theirs
            git push origin main
```

**Consideraciones**:

En el repositorio definiremos la secret `METRICS_TOKEN` para dar los permisos necesarios para la action.

Para ello hemos definido un PAT (personla access token) en nuestra cuenta con las siguientes características:

![alt text](<Captura de pantalla 2025-01-12 002351.png>)

---


## Resultado final

![alt text](<Captura de pantalla 2025-01-13 003348.png>)


---


## Métricas

<!--START_SECTION:metrics-->

<!--END_SECTION:metrics-->
