# deploy_awx
Despliega el awx sobre ks3 y nfs provisioner para persistir los datos

# Preparación de script
En caso de que necesite agregar los certificados firmados por la CA de su preferencia es necesario copiar en la carpeta base el certificado con el siguente nomrbre
server.crt y server.key en caso de que sea un experto en kubernetes puede modificar el kustomization.yaml y personalizar el nombre a gusto.
Tener en cuanta que en caso de no contar con un certifica el instalador por defecto crea un autofirmado solo tiene que faciliar el hostname en el archivo base/awx.yml y en el deploy.sh
El deploy.sh edite para modificar los parametros declarados en el inicio

# Parametros
 --ks3 Instala unificamente el k3s
 --awx deploy del operador y del awx
 --all ejecuta el --ks3 y awx solo recomendado si cuenta con buen ancho de banda para descargar las imagenes y dependecias.
