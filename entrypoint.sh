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
