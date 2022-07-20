# deploy_awx
Despliega el awx sobre k3s y nfs provisioner para persistir los datos

# Preparación de script
En caso de que necesite agregar los certificados firmados por la CA de su preferencia es necesario copiar en la carpeta base el certificado con el siguente nomrbre
tls.crt y tls.key en caso de que sea un experto en kubernetes puede modificar el kustomization.yaml y personalizar el nombre a gusto.
Tener en cuanta que en caso de no contar con un certificado el instalador por defecto crea un autofirmado solo tiene que faciliar el hostname en el archivo base/awx.yml y en el deploy.sh

# Entorno de prueba
Rocky Linux 8.5

# Parametros
 --k3s Instala unificamente el k3s
 --awx deploy del operador y del awx
 --all ejecuta el --k3s y awx solo recomendado si cuenta con buen ancho de banda para descargar las imagenes y dependecias.
 --uninstall remueve la instalacion completa
# Pasos para ejecutar
```bash
# git clone https://github.com/huacqui/deploy_awx.git
# cd deploy_awx/
# ./deploy.sh --all
```
# Obtener el admin password
```bash
# kubectl get secret awx-admin-password -o json  -n awx | jq -r .data.password | base64 -d
```
