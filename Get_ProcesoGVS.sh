##########################################################################
# Proyecto	         : Trafico Y Eventos			                           #
# Descripcion        : Realiza ftp de los archivos del servidor GVS      #
# Parametros         : No Aplica                                         #
# Fecha Creacion     : 19/02/2016             							             #
##########################################################################
# Path inicial del proceso.

. /home/prod/env.ini
# Parametros Iniciales
PRM_DATE=$(date +"%Y%m%d")
PRM_DATETIMEINI=$(date +"%Y%m%d%H%M%S")


fTransferenciaTotal()
{
ftp -inv $PRM_IP_GVS > $PRM_PATH_GVS_LOG/FtpGVSctl_$PRM_DATETIMEINI.log << EOF
        user $PRM_USR_GVS $PRM_PWD_GVS
        cd $PRM_PATH_GVS_REMOTE
#       mget *.ctl
        mget *.$extension
        bye
EOF

#Validar ejecucion FTP
PRM_FTP=$(grep 'Transfer complete' $PRM_PATH_GVS_LOG/FtpGVSctl_$PRM_DATETIMEINI.log)
PRM_FTP1=`echo $PRM_FTP | cut -c1-22`
echo "PRM_FTP1 : $PRM_FTP1 "
if [[ $PRM_FTP1 = "226 Transfer complete." ]]
then
  echo "Extracciones  txt y ctl OK"
ftp -inv $PRM_IP_GVS > $PRM_PATH_GVS_LOG/FtpGVSctl_$PRM_DATETIMEINI.log << EOF
        user $PRM_USR_GVS $PRM_PWD_GVS
        cd $PRM_PATH_GVS_REMOTE
        mget *.ctl
        bye
EOF
else
  echo "No se han encontrado archivos en el repositorio de GVS" >> $archlog
PRM_CORREO=`grep -i "^GVS.USER_EMAIL_LIST*" $PRM_ARCHIVO_PROPERTIES | awk -F= '{printf("%s",$2)}'`
echo "PRM_CORREO $PRM_CORREO"
  echo " No se han encontrado archivos en el repositorio de GVS , favor de verificar Servidor $PRM_IP_GVS  Ruta: $PRM_PATH_GVS_REMOTE " |  mailx -v -s "[ PPM41442 - Daas ] :  Errores Landing Zone "  -S smtp=smtp://10.226.5.191 -S from="Landing Zone Alerts <landing_zone_alerts@telefonica.com>" $PRM_CORREO
#exit 1
fi
}

fBorradoFTPtxt()
{
archivo=$1    
ftp -inv $PRM_IP_GVS > $PRM_PATH_GVS_LOG/FtpGVSctl_"$archivo"_$PRM_DATETIMEINI.log << EOF
        user $PRM_USR_GVS $PRM_PWD_GVS
        cd $PRM_PATH_GVS_REMOTE
        prompt off
        delete $archivo
        bye
EOF
PRM_FTP=$(grep 'DELE*' $PRM_PATH_GVS_LOG/FtpGVSctl_"$archivo"_$PRM_DATETIMEINI.log)
PRM_FTP1=`echo $PRM_FTP | cut -c1-22`
if [[ $PRM_FTP1 = "250 DELE command succe" ]]
then

   echo "archivo $archivo borrado" >> $archlog
else

   echo  "No encontro $archivo   en servidor ftp  para borrar"  >> $archlog
fi
}

#---------------------#
# INICIO DEL PROGRAMA #
#---------------------#
echo '************************'
echo 'Trafico y Eventos' 
echo '************************'
echo '1. Inicio de Proceso get GVS' 
archlog=${PRM_PATH_GVS_LOG}/GVSFTP_$PRM_DATETIMEINI.log
export archlog

Resultado=`curl --head $PRM_IP_EGDE_NODE_1:8086 2>/dev/null | grep "OK"`  
echo "Resultado : $Resultado"

if [ "$Resultado" = '' ];then

PRM_ARCHIVO_PROPERTIES=$PRM_PATH_PROPERTIES_NIFI/properties.ini

extension=`grep -i "^GVS.EXTENSION" $PRM_ARCHIVO_PROPERTIES | awk -F= '{printf("%s",$2)}'`

echo "-------------------------------------" >>$archlog
echo "Inicio del proceso ftpgetGVS : `date`"  >> $archlog
cd $PRM_PATH_GVS_TMP    

fTransferenciaTotal


ArchivoFTP=`grep -i "^GVS.FILENAME_FILTER" $PRM_ARCHIVO_PROPERTIES | awk -F= '{printf("%s",$2)}'`

echo "ArchivoFTP : $ArchivoFTP"

NomArchivoctl=`ls -lt "${ArchivoFTP}"*.ctl   2>/dev/null  | tail -1 | awk '{print $9}'` 
NomArchivotxt=`ls -lt "${ArchivoFTP}"*.txt   2>/dev/null  | tail -1 | awk '{print $9}'`

echo "Inicio  de borrado de archivo  servidor 10.4.40.191" >> $archlog

#listado=`ls V* 2>/dev/null` 
listado=`ls "${ArchivoFTP}"* 2>/dev/null` 

if [ "$listado" != '' ];then
for i in $listado
do

fBorradoFTPtxt $i
done

#echo "Fin de borrado de archivos servidor 10.4.40.191" 
echo "Fin de borrado de archivo  servidor 10.4.40.191" >> $archlog

else
echo "No hay archivos que borrar"
exit 1
fi 
#fi
if [ "$NomArchivoctl" != '' ];then

echo "NOMBRE de ARCHIVO ctl es $NomArchivoctl"
CantArchivoctl=`wc -l  $PRM_PATH_GVS_TMP/$NomArchivoctl`

echo "Cantidad de archivos ctl es $CantArchivoctl"

echo "Cantidad de archivos ctl es $CantArchivoctl" >> $archlog 
chmod -R 660 $NomArchivoctl 
dos2unix $NomArchivoctl 
mv $NomArchivoctl $PRM_PATH_GVS 
else 
echo "No se encontro archivo ctl para $NomArchivotxt "
echo "No se encontro archivo ctl para $NomArchivotxt " >> $archlog
fi

if [ "$NomArchivotxt" != '' ];then
CantArchivotxt=`wc -l $PRM_PATH_GVS_TMP/$NomArchivotxt`

echo "Cantidad de archivos txt es $CantArchivotxt" >> $archlog
chmod -R 660 $NomArchivotxt  
dos2unix $NomArchivotxt      
mv $NomArchivotxt $PRM_PATH_GVS  
else 
echo "No se encontro archivos txt "
echo "No se encontro archivos txt " >> $archlog
exit 1
fi


echo "Fin del proceso FTPGVS : `date`" >> $archlog


else 
echo "se conecta  remotamente al Servidor $PRM_IP_EGDE_NODE_1"
echo "se conecta  remotamente al Servidor $PRM_IP_EGDE_NODE_1" >> $archlog

fi 

cat $archlog

#---------------------#
# FIN DEL PROGRAMA    #
#---------------------#
