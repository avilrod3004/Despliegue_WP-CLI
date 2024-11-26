# Despliegue_LAMP
Scripts para instalar LAMP, WordPress y solicitar un certificado SSL/TLS

## Requisitos para ejecutar los scripts
- Máquina con Ubuntu server 24.04
- Renombrar el fichero de ejemplo de las variables de entorno y completar con los datos

## Pasos
1. Dar permisos de ejecución a los scripts: `chmod +x script.sh`
2. Ejecutar los scripts como `root`
3. Ejecutar primero `install_lamp.sh`
4. Después, ejecutar `deploy_wordpress_with_wpcli.sh`
5. Por último, ejecutar `setup_letsencrypt_https.sh`