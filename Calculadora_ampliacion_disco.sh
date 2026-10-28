#!/usr/bin/env bash
# =============================================================================
# Descripción : Calculadora de ampliación de disco (Linux)
# Versión     : 1.0
# Autor       : Angel Mora Llamozas
# =============================================================================

# Colores ANSI
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # sin color

# Valida que un valor sea numérico (acepta decimales con punto)
es_numero() {
    [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

# Pide un número y repite hasta que sea válido
leer_numero() {
    local mensaje="$1" valor
    while true; do
        read -r -p "$mensaje: " valor
        valor="${valor//,/.}"   # permite escribir coma decimal
        if es_numero "$valor"; then
            echo "$valor"
            return
        fi
        echo -e "${RED}[ERROR] Ingrese un valor numérico válido.${NC}" >&2
    done
}

echo -e "${CYAN}===================================================================${NC}"
echo -e "${CYAN}   CALCULADORA DE AMPLIACIÓN DE DISCO (LINUX)   ${NC}"
echo -e "${CYAN}===================================================================${NC}\n"

# 1. Entrada de datos
tamanoActual=$(leer_numero "Ingrese el tamaño actual del disco (ej. 12.2 o 50)")
read -r -p "Unidad de medida (GB / TB): " unidadMedida
espacioLibre=$(leer_numero "Ingrese el espacio LIBRE actual (ej. 35.4 GB -> 0.0354 en TB)")
porcentajeUsoActual=$(leer_numero "Ingrese el % de USO actual (ej. 99)")

# 2. Espacio ocupado
espacioUsado=$(awk -v t="$tamanoActual" -v l="$espacioLibre" 'BEGIN { printf "%.4f", t - l }')

echo -e "\n${YELLOW}-------------------------------------------------------------------${NC}"
echo -e "${YELLOW} RESUMEN ACTUAL${NC}"
echo -e "${YELLOW}-------------------------------------------------------------------${NC}"
echo "Tamaño Total Actual : ${tamanoActual}${unidadMedida}"
echo "Espacio Usado       : ${espacioUsado}${unidadMedida}"
echo "Espacio Libre       : ${espacioLibre}${unidadMedida}"
echo "Uso Actual          : ${porcentajeUsoActual} %"

# 3. Objetivo
echo -e "\n${YELLOW}-------------------------------------------------------------------${NC}"
echo -e "${YELLOW} OBJETIVO DE OPTIMIZACIÓN${NC}"
echo -e "${YELLOW}-------------------------------------------------------------------${NC}"
pctLibreDeseado=$(leer_numero "Ingrese el % de ESPACIO LIBRE que desea tener (ej. 10, 15, 20)")

if awk -v p="$pctLibreDeseado" 'BEGIN { exit !(p <= 0 || p >= 100) }'; then
    echo -e "\n${RED}[ERROR] El porcentaje libre deseado debe ser entre 1 y 99.${NC}"
    exit 1
fi

# 4. Cálculos matemáticos
# nuevoTotal = usado / (1 - libre%/100) ; aumentar = nuevoTotal - actual ; nuevoLibre = nuevoTotal - usado
read -r nuevoTamanoTotal discoAumentar nuevoEspacioLibre < <(
    awk -v u="$espacioUsado" -v t="$tamanoActual" -v p="$pctLibreDeseado" 'BEGIN {
        nuevo = u / (1 - p / 100)
        printf "%.6f %.6f %.6f\n", nuevo, nuevo - t, nuevo - u
    }'
)

# 5. Muestra de resultados
echo -e "\n${GREEN}===================================================================${NC}"
echo -e "${GREEN} RESULTADOS Y RECOMENDACIÓN${NC}"
echo -e "${GREEN}===================================================================${NC}"
pctUsoObjetivo=$(awk -v p="$pctLibreDeseado" 'BEGIN { printf "%g", 100 - p }')
echo "Para lograr un ${pctLibreDeseado}% de espacio libre (Uso al ${pctUsoObjetivo}%):"

if awk -v d="$discoAumentar" 'BEGIN { exit !(d > 0) }'; then
    printf "\n${CYAN} -> DISCO A AUMENTAR     : %.2f %s${NC}\n" "$discoAumentar" "$unidadMedida"
    printf " -> NUEVO TAMAÑO TOTAL    : %.2f %s\n" "$nuevoTamanoTotal" "$unidadMedida"
    printf " -> NUEVO ESPACIO LIBRE   : %.2f %s\n" "$nuevoEspacioLibre" "$unidadMedida"
else
    echo -e "\n${YELLOW}El disco ya cumple con el espacio libre deseado.${NC}"
fi
echo -e "${GREEN}===================================================================${NC}\n"
