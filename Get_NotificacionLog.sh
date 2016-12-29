##############################################################################################
# Proyecto	         : Trafico Y Eventos			               										             #
# Descripcion        : Realiza grep  log de los archivos del servidor GVS y envio de correo  #
# Parametros         : No Aplica                                                             #
# Fecha Creacion     : 19/02/2016             							                                 #
##############################################################################################-------------------------.#

# Path inicial del proceso.
. /home/prod/env.ini
# Parametros Iniciales
PRM_DATE=$(date +"%Y%m%d")
PRM_DATETIMEINI=$(date +"%Y%m%d%H%M%S")


enviocorreo()
{
cd $PRM_PATH_ALERT_TMP_LOG
PRM_CORREO=`grep -i "^"$j".ALERT_EMAIL_LIST*" $PRM_ARCHIVO_PROPERTIES | awk -F= '{printf("%s",$2)}'`
echo "PRM_CORREO $PRM_CORREO"
echo " Se ha generado errores en la carga del proceso : $j Revisar archivo adjunto. " |  mailx -v -s "[ PPM41442 - Daas ] :  Errores Landing Zone " -a Errores_files_$j.txt -S smtp=smtp://10.226.5.191 -S from="Landing Zone Alerts <landing_zone_alerts@telefonica.com>" $PRM_CORREO
}

enviocorreo1()
{
cd $PRM_PATH_ALERT_TMP_LOG
echo "Valor de j es $j"
PRM_CORREO1=`grep -i "^"$j".USER_EMAIL_LIST*" $PRM_ARCHIVO_PROPERTIES | awk -F= '{printf("%s",$2)}'`
echo "PRM_CORREO1 : $PRM_CORREO1"
if [ "$PRM_CORREO1" != '' ];then
echo " Se ha generado errores en la carga del proceso : $j Revisar archivo adjunto. " |  mailx -v -s "[ PPM41442 - Daas ] :  Errores Landing Zone " -a Errores_files_$j.txt -S smtp=smtp://10.226.5.191 -S from="Landing Zone Alerts <landing_zone_alerts@telefonica.com>" $PRM_CORREO1
else
  echo "No se tiene el patron de busqueda en paramteros.ini"
# exit 1
fi

#echo "PRM_CORREO1 $PRM_CORREO1"
#echo " Se ha generado errores en la carga del proceso : $j Revisar archivo adjunto. " |  mailx -v -s "[ PPM41442 - Daas ] :  Errores Landing Zone " -a Errores_files_$j.txt -S smtp=smtp://10.226.5.191 -S from="Landing Zone Alerts <landing_zone_alerts@telefonica.com>" $PRM_CORREO1
}


FiltraLog()
{
cd $PRM_PATH_ALERT_TMP_LOG 
rm $PRM_PATH_ALERT_TMP_LOG/* 2>/dev/null
find $PRM_PATH_ALERT_LOG/* -mmin -$Tiempo -name "tengine_$j*" -exec cp {}  $PRM_PATH_ALERT_TMP_LOG \;
cd $PRM_PATH_ALERT_TMP_LOG  
#echo "LOG Temporal es $PRM_PATH_ALERT_TMP_LOG"
}

Barreflujo()
{

archivo=`ls -ltr tengine_$j*.log 2>/dev/null | awk '{print $9}' `

if [ "$archivo" != '' ];then
#echo "Encontro archivos log"
echo "Busca en archivos log " >> $archlog

flag=0
for i in $archivo 
do
echo "Log : " $PRM_PATH_ALERT_TMP_LOG/$i >> $archlog
grep   "FAILED*\|SEVERE*" $PRM_PATH_ALERT_TMP_LOG/$i > $PRM_PATH_ALERT_TMP_LOG/Resultado1.txt
cantidad=`wc -l  $PRM_PATH_ALERT_TMP_LOG/Resultado1.txt | awk '{print $1'} `
#echo "cantidad es $cantidad"
#echo "Resultado1 $PRM_PATH_ALERT_TMP_LOG/Resultado1.txt"
#export cantidad
if [ $cantidad != 0 ] && [ $flag == 0 ];then
flag=1
echo "Genera Log"
echo "-------------------------------------------------------------------------------------" > $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-- Proyecto    : Trafico y Eventos (Landing zone)"                                     >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-- Proceso     : $j:"                                                                  >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-- Ruta de log : $PRM_PATH_ALERT_LOG "                                                 >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-------------------------------------------------------------------------------------" >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
fi  

if  [ $cantidad != 0 ] && [ $flag == 1 ];then
echo " " >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo " " >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-------------------------------------------------------------------------------------" >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "----Nombre del log es $i "                                                             >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-------------------------------------------------------------------------------------" >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
grep  -B10 -A50 "FAILED*\|SEVERE*" $i                                                       >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt

fi  

done

if [ $flag == 1 ];then
echo "Variables enviocorreo"
enviocorreo
fi

fi

}


Barreflujo1()
{

archivo=`ls -ltr tengine_$j*.log 2>/dev/null | awk '{print $9}' `

if [ "$archivo" != '' ];then
#echo "Encontro archivos log"
echo "Busca en archivos log " >> $archlog

flag=0
for i in $archivo 
do
echo "Log : " $PRM_PATH_ALERT_TMP_LOG/$i >> $archlog
grep   "INVALID_FILE_O_STRUCTURE*" $PRM_PATH_ALERT_TMP_LOG/$i > $PRM_PATH_ALERT_TMP_LOG/Resultado1.txt
cantidad=`wc -l  $PRM_PATH_ALERT_TMP_LOG/Resultado1.txt | awk '{print $1'} `

if [ $cantidad != 0 ] && [ $flag == 0 ];then
flag=1
echo "Genera Log"
echo "-------------------------------------------------------------------------------------" > $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-- Proyecto    : Trafico y Eventos (Landing zone)"                                     >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-- Proceso     : $j:"                                                                  >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-- Ruta de log : $PRM_PATH_ALERT_LOG "                                                 >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-------------------------------------------------------------------------------------" >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
fi  

if  [ $cantidad != 0 ] && [ $flag == 1 ];then
echo " " >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo " " >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-------------------------------------------------------------------------------------" >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "----Nombre del log es $i "                                                             >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
echo "-------------------------------------------------------------------------------------" >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt
grep  -B10 -A50 "INVALID_FILE_O_STRUCTURE*" $i                                               >> $PRM_PATH_ALERT_TMP_LOG/Errores_files_$j.txt

fi  

done

if [ $flag == 1 ];then
echo "Variables enviocorreo1"
enviocorreo1
fi

fi

}

#---------------------#
# INICIO DEL PROGRAMA #
#---------------------#
echo '************************'
echo 'Trafico y Eventos' 
echo '************************'
echo '1. Inicio de Notificaciones' 
archlog=$PRM_PATH_ALERT_TMP_LOG/Notifica_$PRM_DATETIMEINI.log
PRM_ARCHIVO_PROPERTIES=$PRM_PATH_PROPERTIES_NIFI/properties.ini
export archlog

Resultado=`curl --head $PRM_IP_EGDE_NODE_1:8086 2>/dev/null | grep "OK"`  
echo "Resultado : $Resultado"

if [ "$Resultado" = '' ];then

echo "-------------------------------------" >> $archlog
echo "Inicio del proceso Notificacion : `date`"  >> $archlog
Tiempo=$1log

if [ $# -ne 1 ]; then
Tiempo=5000
else
Tiempo=$Tiempo
fi
echo "Valor de Tiempo es $Tiempo " 
echo "Valor de Tiempo es $Tiempo " >> $archlog

NuevaLista=`cat /var/opt/teradata/tf_lz/dev/helper_tools/alertas/Procesos.txt`
for j in $NuevaLista
do
echo "j $j"  >> $archlog
FiltraLog  $j
Barreflujo $j
Barreflujo1 $j
#enviocorreo $j
done


#exit 1
echo "Fin del proceso Notificacion: `date`" >> $archlog

else 
echo "se conecta  remotamente al Servidor $PRM_IP_EGDE_NODE_1"
echo "se conecta  remotamente al Servidor $PRM_IP_EGDE_NODE_1" >> $archlog

fi
cat $archlog
#---------------------#
# FIN DEL PROGRAMA    #
#---------------------#
