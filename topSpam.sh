#!/bin/bash
#
# versao 0.1
#
# INFORMAÇÕES
#   topSpam.sh
#
# DESCRICAO
#    Lista os e-mails mais enviados com o mesmo assunto
#
# NOTA
#   Testado e desenvolvido em CentOS 7
#
#  DESENVOLVIDO_POR
#  Valdenir Luíz Mezadri Junior			- valdenirmezadri@live.com
#
#  MODIFICADO_POR		(DD/MM/YYYY)
#  Valdenir Luíz Mezadri Junior	19/02/2019	- Criado script
#  Valdenir Luíz Mezadri Junior 20/02/2019  - Finalizado testes
#
#########################################################################################################################################
#### Variáveis que você deve alterar ####################################################################################################

#Score mínimo que um spam deve receber para ser considerado "definitivamente spam", qualquer coisa abaixo disso cairá na lista
SCORE_MINIMO="12" 

#Quantos assuntos serão analisados
QTDTOP="10"

#Nome do servidor
SERVIDOR="Servidor2"

#Destinatários
DESTINATARIOS="junior@hardtec.srv.br, jeferson@hardtec.srv.br"

#### Variaveis que dificilmente você deveria alterar ####################################################################################
TMP="/tmp"

#log do MailScanner
MAILLOG="/var/log/maillog"

################## NÃO ALTERAR A PARTIR DESTA LINHA ####################################################################################
#pega os top  assuntos
function getTop10() {
	TOP10=$(awk -F"subject  " '/subject/ {print $2}'  $MAILLOG| sort | uniq -c | sort -n|tail -n$QTDTOP)
	ASSTOP10=$(echo "$TOP10"|awk '{$1="";print $0}'|sed 's/^ //')
	getIDS "$ASSTOP10"
	enviaEmail
}

#Geramos uma lista de ids de todas as mensagens que tenham o assunto
function getIDS() {
	while IFS= read -r assunto
	  do
		IDS=$(fgrep -i "$assunto" $MAILLOG|awk -F"message " '{print $2}'|egrep -v 'blacklisted|whitelisted'|cut -d" " -f1)
		getScore "$assunto" "$IDS"

	done < <(printf '%s\n' "$1")
}

#Geramos uma lista de scores pelo id de cada assunto
function getScore() {
	while IFS= read -r id
          do
		grep "$id" $MAILLOG|awk -F"score=" '{print $2}'| cut -d" " -f1| sed '/^$/d'| sed 's/,//g' >> $TMP/Score
	done < <(printf '%s\n' "$2")
	MEDIA=$(cat "$TMP/Score")
	rm -rf $TMP/Score
	getMedia "$1" "$MEDIA"

}

#Geramos uma média do Score de cada assunto
function getMedia() {
	assunto="$1"
	MEDIA=$(echo "$2"|awk '{s+=$1}END{print int(s/NR)}')
	geraLista  $MEDIA $SCORE_MINIMO "$assunto"
}

#Gera uma lista de assuntos se a média for inferior ao score mínimo
function geraLista() {
	assunto="$3"
        if [[ $1 -lt $2 ]];
                then
		echo -e "Assunto do e-mail: $assunto \nMédia: $1\n" >> $TMP/ListaDeSpam
	fi
}

#Se existir o arquivo com a lista de asunta média indicada for menor que a média de score do assunto, enviamos um e-mail para análise
function enviaEmail() {
	if [ -f $TMP/ListaDeSpam ];
		then
		mensagem=$(cat "$TMP/ListaDeSpam")
		rm -rf $TMP/ListaDeSpam
		echo "$mensagem" | mail -s "$SERVIDOR E-mails com muitos envios e média inferior a $SCORE_MINIMO" $DESTINATARIOS
	fi
}

getTop10
