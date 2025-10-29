#!/bin/bash

# Script para clonar una página web de forma completa
# Uso: ./clone_website.sh https://ejemplo.com [directorio_destino]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con colores
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar argumentos
if [ $# -eq 0 ]; then
    print_error "Uso: $0 <URL> [directorio_destino]"
    print_error "Ejemplo: $0 https://ejemplo.com mi_sitio_clonado"
    exit 1
fi

URL="$1"
DOMAIN=$(echo "$URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
DEST_DIR="${2:-${DOMAIN}_clonado}"
TEMP_DIR="/tmp/web_clone_$$"

print_status "Iniciando clonación de: $URL"
print_status "Directorio destino: $DEST_DIR"

# Crear directorios
mkdir -p "$DEST_DIR"
mkdir -p "$TEMP_DIR"

# Verificar dependencias
check_dependencies() {
    print_status "Verificando dependencias..."
    
    local deps=("wget" "curl")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Faltan dependencias: ${missing[*]}"
        print_status "Instalar con: sudo apt install ${missing[*]}"
        exit 1
    fi
    
    # Verificar HTTrack (opcional)
    if command -v httrack &> /dev/null; then
        HAS_HTTRACK=true
        print_success "HTTrack disponible - se usará para mejor clonación"
    else
        HAS_HTTRACK=false
        print_warning "HTTrack no disponible - solo se usará wget"
        print_status "Para mejor resultado: sudo apt install httrack"
    fi
}

# Función para descargar robots.txt y sitemap
download_meta_files() {
    print_status "Descargando archivos meta..."
    
    # robots.txt
    curl -s -f "${URL}/robots.txt" -o "$TEMP_DIR/robots.txt" 2>/dev/null || print_warning "No se pudo descargar robots.txt"
    
    # sitemap.xml
    for sitemap in "sitemap.xml" "sitemap_index.xml" "wp-sitemap.xml"; do
        if curl -s -f "${URL}/${sitemap}" -o "$TEMP_DIR/${sitemap}" 2>/dev/null; then
            print_success "Sitemap descargado: $sitemap"
            break
        fi
    done
}

# Función HTTrack (si está disponible)
clone_with_httrack() {
    if [ "$HAS_HTTRACK" = false ]; then
        return
    fi
    
    print_status "Iniciando clonación con HTTrack..."
    
    cd "$DEST_DIR"
    
    httrack "$URL" \
        --max-rate=50000 \
        --connection-per-second=2 \
        --sockets=3 \
        --keep-alive \
        --robots=0 \
        --depth=5 \
        --ext-depth=2 \
        --mirror \
        --quiet \
        --display=0 \
        -%v \
        --disable-security-limits \
        --assume=css,js,png,jpg,jpeg,gif,svg,woff,woff2,pdf \
        --footer="" \
        2>/dev/null || print_warning "HTTrack completado con advertencias"
    
    cd - > /dev/null
    print_success "HTTrack completado"
}

# Función wget principal
clone_with_wget() {
    print_status "Iniciando clonación con wget..."
    
    cd "$DEST_DIR"
    
    # Configurar wget
    cat > "$TEMP_DIR/.wgetrc" << EOF
wait = 1
random_wait = on
user_agent = Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36
robots = off
recursive = on
level = 6
page_requisites = on
convert_links = on
backup_converted = off
html_extension = on
no_parent = on
timestamping = on
continue = on
timeout = 30
tries = 3
EOF
    
    # Ejecutar wget con configuración personalizada
    WGETRC="$TEMP_DIR/.wgetrc" wget \
        --recursive \
        --level=6 \
        --convert-links \
        --page-requisites \
        --html-extension \
        --domains="$DOMAIN" \
        --no-parent \
        --wait=1 \
        --random-wait \
        --limit-rate=200k \
        --reject="*.exe,*.zip,*.tar.gz,*.rar,*.7z,*.deb,*.rpm" \
        --accept-regex=".*\.(html?|php|css|js|png|jpe?g|gif|svg|webp|ico|pdf|woff2?|ttf|otf|eot)(\?.*)?$" \
        --user-agent="Mozilla/5.0 (compatible; WebCloner/1.0)" \
        --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
        --header="Accept-Language: es,en;q=0.5" \
        --progress=bar \
        "$URL" 2>&1 | grep -v "certificado" || print_warning "wget completado con advertencias"
    
    cd - > /dev/null
    print_success "wget completado"
}

# Función para descargar recursos adicionales
download_additional_resources() {
    print_status "Buscando recursos adicionales..."
    
    cd "$DEST_DIR"
    
    # Buscar y descargar CSS/JS referenciados
    find . -name "*.html" -o -name "*.css" -o -name "*.js" | while read -r file; do
        if [ -f "$file" ]; then
            # Extraer URLs de recursos
            grep -oE 'https?://[^"'\''[:space:]>]+\.(css|js|png|jpe?g|gif|svg|woff2?|ttf)' "$file" 2>/dev/null | \
            sort -u | head -20 | while read -r resource_url; do
                resource_name=$(basename "$resource_url" | cut -d'?' -f1)
                if [ ! -f "./$resource_name" ] && [ -n "$resource_name" ]; then
                    wget -q --timeout=10 --tries=2 "$resource_url" -O "./$resource_name" 2>/dev/null || true
                fi
            done
        fi
    done
    
    cd - > /dev/null
}

# Función de limpieza y optimización
cleanup_and_optimize() {
    print_status "Limpiando y optimizando..."
    
    cd "$DEST_DIR"
    
    # Eliminar archivos temporales y no deseados
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name ".htaccess*" -delete 2>/dev/null || true
    find . -name "hts-*" -delete 2>/dev/null || true
    
    # Crear índice simple si no existe
    if [ ! -f "index.html" ] && [ ! -f "index.php" ]; then
        find . -name "*.html" -type f | head -1 | xargs -I {} cp {} index.html 2>/dev/null || true
    fi
    
    cd - > /dev/null
}

# Función para generar reporte
generate_report() {
    print_status "Generando reporte..."
    
    cd "$DEST_DIR"
    
    cat > "CLONACION_REPORTE.txt" << EOF
REPORTE DE CLONACIÓN WEB
========================

URL Original: $URL
Fecha: $(date)
Directorio: $DEST_DIR

ESTADÍSTICAS:
- Archivos HTML: $(find . -name "*.html" | wc -l)
- Archivos CSS: $(find . -name "*.css" | wc -l)
- Archivos JS: $(find . -name "*.js" | wc -l)
- Imágenes: $(find . \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" \) | wc -l)
- Tamaño total: $(du -sh . | cut -f1)

HERRAMIENTAS UTILIZADAS:
- HTTrack: $([ "$HAS_HTTRACK" = true ] && echo "SÍ" || echo "NO")
- wget: SÍ
- Recursos adicionales: SÍ

NOTAS:
- Esta es una copia estática del sitio web
- Funcionalidades dinámicas (PHP, formularios, etc.) no funcionarán
- Para uso personal únicamente
EOF
    
    cd - > /dev/null
}

# Función principal
main() {
    print_status "=== INICIO DE CLONACIÓN WEB ==="
    
    check_dependencies
    download_meta_files
    
    # HTTrack primero (si está disponible)
    clone_with_httrack
    
    # wget para completar
    clone_with_wget
    
    # Recursos adicionales
    download_additional_resources
    
    # Limpieza
    cleanup_and_optimize
    
    # Reporte
    generate_report
    
    # Limpiar temporal
    rm -rf "$TEMP_DIR"
    
    print_success "=== CLONACIÓN COMPLETADA ==="
    print_status "Sitio clonado en: $DEST_DIR"
    print_status "Abrir con: firefox $DEST_DIR/index.html"
    
    # Mostrar estadísticas finales
    cd "$DEST_DIR"
    echo
    print_status "RESUMEN FINAL:"
    echo "  📁 Archivos totales: $(find . -type f | wc -l)"
    echo "  🌐 Páginas HTML: $(find . -name "*.html" | wc -l)"
    echo "  🎨 Archivos CSS: $(find . -name "*.css" | wc -l)"
    echo "  ⚡ Scripts JS: $(find . -name "*.js" | wc -l)"
    echo "  🖼️  Imágenes: $(find . \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" \) | wc -l)"
    echo "  📦 Tamaño: $(du -sh . | cut -f1)"
    cd - > /dev/null
}

# Ejecutar función principal
main