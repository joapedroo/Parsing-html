#!/usr/bin/env bash

#====================INICIO=========================#
# Constantes para facilitar a utilização das cores.
RED='\033[31;1m'
GREEN='\033[32;1m'
BLUE='\033[34;1m'
YELLOW='\033[33;1m'
RED_BLINK='\033[31;5;1m'
END='\033[m'

# Versão do Script
version='1.0'
criador='joapedroo'
titulo='PARSING HTML'

clear
if [ "$1" == "" ]
then
    echo  # BANNER
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                                                                              #${END}"
    echo -e "${YELLOW}#                            Titulo: $titulo                                      #${END}"
    echo -e "${YELLOW}#                            Criador: $criador                                         #${END}"
    echo -e "${YELLOW}#                            Version: $version                                      #${END}"
    echo -e "${YELLOW}#                                                                              #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    echo -e "${RED}Modo de uso   : $0 [URL]${END}"
    echo -e "${RED}Example       : $0 www.site.com${END}"
    echo
else

    # Baixa o arquivo pelo WGET e mostra os links

    echo -e "${GREEN}[+]****** AGUARDE ISSO PODE LEVAR UNS MINUTOS ******[+]${END}"
    echo
    wget -q -c --show-progress $1;
    echo -e "${RED}\n[+] Download completo!\n\n"

    grep href index.html | cut -d "/" -f 3 | grep "\." | cut -d '"' -f 1 | grep -v "<l" > lista

    # Mostra os links achados

    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                         Links encontrados.                                   #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    while read lista; do
        echo $lista
    done < lista

    # Hosts encontrados serão salvo em host.

    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                         Hosts encontrados.                                   #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo

    for url in $(cat lista);
    do 
    host $url | grep "has address" | awk '{print $4 "\t\t" $1}';
    done > host

    echo -e "${BLUE}\n[+]############################# Arquivo salvo! #############################[+]\n\n${END}"

    # Mostrar quantidade de lista e de host.

    printf "\n================================================================================\n\n"
    printf "\nTotal: \n\n"
    printf "Encontrados :\t" ; wc -l lista
    printf "Encontrados :\t" ; wc -l host
    printf "\n================================================================================\n\n"

    # Remover a lista o host e o Index.html baixado.

    rm -rf host &>/dev/null;
    rm -rf index.html &>/dev/null;
fi
