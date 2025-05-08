#!/usr/bin/env bash

#==================== CONFIGURAÇÕES ====================#
# Cores para melhor visualização
RED='\033[31;1m'
GREEN='\033[32;1m'
BLUE='\033[34;1m'
YELLOW='\033[33;1m'
CYAN='\033[36;1m'
MAGENTA='\033[35;1m'
RED_BLINK='\033[31;5;1m'
END='\033[m'

# Informações do script
VERSION='2.0'
AUTHOR='joapedroo'
TITLE='PARSING HTML TOOL'
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Arquivos temporários
TMP_HTML="index_${TIMESTAMP}.html"
TMP_LINKS="links_${TIMESTAMP}.txt"
TMP_HOSTS="hosts_${TIMESTAMP}.txt"
LOG_FILE="parsing_log_${TIMESTAMP}.txt"

#==================== FUNÇÕES ====================#
show_banner() {
    clear
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                                                                              #${END}"
    echo -e "${YELLOW}#${CYAN}                         Título: ${TITLE}${END}"
    echo -e "${YELLOW}#${CYAN}                         Autor: ${AUTHOR}${END}"
    echo -e "${YELLOW}#${CYAN}                         Versão: ${VERSION}${END}"
    echo -e "${YELLOW}#                                                                              #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
}

show_usage() {
    echo -e "${RED}Modo de uso   : $0 [OPÇÕES] [URL]${END}"
    echo -e "${RED}Exemplo       : $0 -v www.site.com${END}"
    echo
    echo -e "${BLUE}Opções disponíveis:${END}"
    echo -e "  -v, --verbose   Mostra saída detalhada durante a execução"
    echo -e "  -o, --output    Especifica um arquivo de saída para os resultados"
    echo -e "  -l, --log       Especifica um arquivo de log para registrar a execução"
    echo -e "  -h, --help      Mostra esta mensagem de ajuda"
    echo
}

cleanup() {
    echo -e "${YELLOW}[+] Limpando arquivos temporários...${END}"
    [[ -f "$TMP_HTML" ]] && rm -f "$TMP_HTML"
    [[ -f "$TMP_LINKS" ]] && rm -f "$TMP_LINKS"
    [[ -f "$TMP_HOSTS" ]] && rm -f "$TMP_HOSTS"
    echo -e "${GREEN}[+] Limpeza concluída!${END}"
}

log_message() {
    local message="$1"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
    [[ $VERBOSE -eq 1 ]] && echo -e "$message"
}

validate_url() {
    local url="$1"
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    else
        url="http://$url"
    fi
    
    if curl --output /dev/null --silent --head --fail "$url"; then
        echo "$url"
        return 0
    else
        return 1
    fi
}

extract_links() {
    log_message "${BLUE}[+] Extraindo links de $TMP_HTML...${END}"
    
    # Extrai links de forma mais robusta
    grep -o -E 'href="([^"#]+)"' "$TMP_HTML" | \
    grep -v -E '\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)' | \
    sed -E 's/href="([^"]*)"/\1/' | \
    awk -F/ '{print $3}' | \
    sort -u > "$TMP_LINKS"
    
    local count=$(wc -l < "$TMP_LINKS")
    log_message "${GREEN}[+] Encontrados $count links únicos.${END}"
}

resolve_hosts() {
    log_message "${BLUE}[+] Resolvendo hosts...${END}"
    
    while read -r domain; do
        if [[ -n "$domain" ]]; then
            host "$domain" | grep "has address" | awk '{print $4 "\t\t" $1}' >> "$TMP_HOSTS"
        fi
    done < "$TMP_LINKS"
    
    local count=$(wc -l < "$TMP_HOSTS")
    log_message "${GREEN}[+] Resolvidos $count hosts.${END}"
}

show_results() {
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                         LINKS ENCONTRADOS                                   #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    column -t "$TMP_LINKS" | sed 's/^/  /'
    
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                         HOSTS RESOLVIDOS                                    #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    [[ -s "$TMP_HOSTS" ]] && column -t "$TMP_HOSTS" | sed 's/^/  /' || echo -e "${RED}  Nenhum host pôde ser resolvido.${END}"
    
    echo
    echo -e "${BLUE}================================================================================${END}"
    echo -e "${CYAN}                         RESUMO DA EXECUÇÃO${END}"
    echo -e "${BLUE}================================================================================${END}"
    echo
    echo -e "  Links encontrados : $(wc -l < "$TMP_LINKS")"
    echo -e "  Hosts resolvidos  : $(wc -l < "$TMP_HOSTS")"
    echo -e "  Arquivo de log    : $LOG_FILE"
    [[ -n "$OUTPUT_FILE" ]] && echo -e "  Arquivo de saída : $OUTPUT_FILE"
    echo
    echo -e "${BLUE}================================================================================${END}"
    echo
}

#==================== PROCESSAMENTO DE ARGUMENTOS ====================#
VERBOSE=0
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_banner
            show_usage
            exit 0
            ;;
        *)
            URL="$1"
            shift
            ;;
    esac
done

#==================== EXECUÇÃO PRINCIPAL ====================#
show_banner

if [[ -z "$URL" ]]; then
    show_usage
    exit 1
fi

# Validar URL
log_message "${BLUE}[+] Validando URL: $URL${END}"
VALID_URL=$(validate_url "$URL")
if [[ $? -ne 0 ]]; then
    log_message "${RED_BLINK}[ERRO] URL inválida ou inacessível: $URL${END}"
    exit 1
fi

log_message "${GREEN}[+] URL válida: $VALID_URL${END}"

# Baixar página
log_message "${BLUE}[+] Baixando página...${END}"
wget -q -c --show-progress -O "$TMP_HTML" "$VALID_URL" 2>&1 | tee -a "$LOG_FILE"

if [[ $? -ne 0 ]]; then
    log_message "${RED_BLINK}[ERRO] Falha ao baixar a página. Verifique a URL e sua conexão.${END}"
    exit 1
fi

log_message "${GREEN}[+] Download concluído com sucesso!${END}"

# Processamento
extract_links
resolve_hosts
show_results

# Salvar resultados se especificado
if [[ -n "$OUTPUT_FILE" ]]; then
    echo -e "Resultados da análise de $URL em $(date)" > "$OUTPUT_FILE"
    echo -e "\n=== LINKS ENCONTRADOS ===\n" >> "$OUTPUT_FILE"
    cat "$TMP_LINKS" >> "$OUTPUT_FILE"
    echo -e "\n=== HOSTS RESOLVIDOS ===\n" >> "$OUTPUT_FILE"
    [[ -s "$TMP_HOSTS" ]] && cat "$TMP_HOSTS" >> "$OUTPUT_FILE" || echo "Nenhum host resolvido." >> "$OUTPUT_FILE"
    log_message "${GREEN}[+] Resultados salvos em $OUTPUT_FILE${END}"
fi

# Limpeza
cleanup

exit 0
