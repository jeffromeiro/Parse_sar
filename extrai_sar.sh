#!/bin/bash
####################################################################
# Script: extrai_sar.sh
# Autor: Jefferson Romeiro
# Data: 24/07/2018
# v=1.0
# Descrição: Fazer o parse de arquivos sar
# var numero: Alterar a linha para o valor encontrado no cabeçalho
# Modo de Execução: gawk -f parse_sar_cpu.awk arquivo_sar
#####################################################################

CAMINHO_SAR=/var/log/sysstat
DESTINO_ARQUIVOS=/home/jefferson/teste_sar/log
AWK_SCRIPT_DIR=/home/jefferson/teste_sar
ARQUIVO_SAIDA=$DESTINO_ARQUIVOS/sar
ARQUIVO_TEMPORARIO=$DESTINO_ARQUIVOS/arquivo.temp


extrai(){
 arquivo=$(echo $1 |rev |awk -F/ '{print $1}' |rev)
 sar -$metrica -f $CAMINHO_SAR/$arquivo |grep -v "Média" > $DESTINO_ARQUIVOS/$arquivo"_"$metrica.txt
 if [ $metrica == "n" ]
 then
    sar -$metrica DEV -f $CAMINHO_SAR/$arquivo |grep -v "Média" > $DESTINO_ARQUIVOS/$arquivo"_"$metrica.txt
 fi
 gawk -v metrica=$metrica -f $AWK_SCRIPT_DIR/parse_sar.awk $DESTINO_ARQUIVOS/$arquivo"_"$metrica.txt  >> $ARQUIVO_SAIDA"_"$metrica.csv
 limpa_arquivo $DESTINO_ARQUIVOS/$arquivo"_"$metrica.txt
}

limpa_arquivo(){
if [ -f $1 ]
then
    rm $1
fi 
}

ajusta_saida(){
   
   case $metrica in
	u)
          cat $ARQUIVO_SAIDA"_"$metrica.csv |grep -v ";;" |grep -v "%idle" > $ARQUIVO_TEMPORARIO
   	  echo "DATA;CPU;%user;%nice;%system;%iowait;%steal;%idle;" > $ARQUIVO_SAIDA"_"$metrica.csv ;;
        r)
          cat $ARQUIVO_SAIDA"_"$metrica.csv |grep -v ";;" |grep -v "%memused" > $ARQUIVO_TEMPORARIO
   	 echo "DATA;kbmemfree;kbavail;kbmemused;%memused;kbbuffers;kbcached;kbcommit;%commit;kbactive;kbinact;kbdirty" > $ARQUIVO_SAIDA"_"$metrica.csv ;;
        d)
          cat $ARQUIVO_SAIDA"_"$metrica.csv |grep -v ";;" |grep -v "DEV" > $ARQUIVO_TEMPORARIO
         echo "DATA;DEV;tps;rkB/s;wkB/s;areq-sz;aqu-sz;await;svctm;%util" > $ARQUIVO_SAIDA"_"$metrica.csv ;;
        b)
          cat $ARQUIVO_SAIDA"_"$metrica.csv |grep -v ";;" |grep -v "Linux" |grep -v "rtps" > $ARQUIVO_TEMPORARIO
         echo "DATA;tps;rtps;wtps;bread/s;bwrtn/s" > $ARQUIVO_SAIDA"_"$metrica.csv ;;
        q)
          cat $ARQUIVO_SAIDA"_"$metrica.csv |grep -v ";;" |grep -v "Linux" |grep -v "runq-sz" > $ARQUIVO_TEMPORARIO
         echo "DATA;runq-sz;plist-sz;ldavg-1;ldavg-5;ldavg-15;blocked" > $ARQUIVO_SAIDA"_"$metrica.csv ;;
        S)
          cat $ARQUIVO_SAIDA"_"$metrica.csv |grep -v ";;" |grep -v "Linux" |grep -v "kbswpused" > $ARQUIVO_TEMPORARIO
         echo "DATA;kbswpfree;kbswpused;%swpused;kbswpcad;%swpcad" > $ARQUIVO_SAIDA"_"$metrica.csv ;;
        w)
          cat $ARQUIVO_SAIDA"_"$metrica.csv |grep -v ";;" |grep -iv "LINUX" |grep -v "proc/s" > $ARQUIVO_TEMPORARIO
         echo "DATA;proc/s;cswch/s" > $ARQUIVO_SAIDA"_"$metrica.csv ;;
        W)
          cat $ARQUIVO_SAIDA"_"$metrica.csv |grep -v ";;" |grep -iv "LINUX" |grep -v "pswpout/s" > $ARQUIVO_TEMPORARIO
         echo "DATA;pswpin/s;pswpout/s" > $ARQUIVO_SAIDA"_"$metrica.csv ;;
        n)
          cat $ARQUIVO_SAIDA"_"$metrica.csv |grep -v ";;" |grep -iv "LINUX" |grep -v "IFACE" > $ARQUIVO_TEMPORARIO
         echo "DATA;IFACE;rxpck/s;txpck/s;rxkB/s;txkB/s;rxcmp/s;txcmp/s;rxmcst/s;%ifutil" > $ARQUIVO_SAIDA"_"$metrica.csv ;;
   esac


   cat $ARQUIVO_TEMPORARIO >> $ARQUIVO_SAIDA"_"$metrica.csv
   limpa_arquivo $ARQUIVO_TEMPORARIO
}

extrai_metrica(){
   metrica=$1   
   limpa_arquivo $ARQUIVO_SAIDA"_"$metrica.csv
   
   for sar in $CAMINHO_SAR/sa??
   do
      extrai $sar
      #extrai_memoria $sar
      #extrai_disco $sar
      #extrai_runqueue $sar
      #extrai_rede $sar
   done
   ajusta_saida
}

cd $DESTINO_ARQUIVOS

read -p 'Informe a métrica:
(CPU=u, MEM=r,MEM STATIS=M, DISCO=d, 
I/0=b, PAGINACAO=B, RUN QUEUE=r, SWAP=S, 
SWAP STATS=W, PROCESSOS=w, REDES=n)
=> ' tipo_metrica

extrai_metrica $tipo_metrica

exit