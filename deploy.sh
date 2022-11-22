#!/bin/bash
##### Deploy K3s with nfs-provisioners and helm #####
### vars ###
export HELM_VERSION=v3.8.1
export AWX_HOST="awx.data.com.py"
export GENERATE_CERTIFICATE="FALSE"
export NAMESPACE=awx

if [ "$1"x == "x" ]
then
  echo "Debe indicar el tipo de tarea que desea ejecutar"
  echo "--k3s despliega el k3s"
  echo "--awx despliega el awx"
  echo "--all despliega el k3s y el awx"
  exit -1
fi

config_systems () {
  dnf update -y && dnf install jq vim bash-completion tar git -y
  firewall-cmd --add-service=http --add-service=https --permanent && firewall-cmd --reload
  firewall-cmd --add-port=10250/tcp --permanent && firewall-cmd --reload
  firewall-cmd --add-masquerade --permanent && firewall-cmd --reload
}

install_dependencies () {
  curl -sfL https://get.k3s.io | sudo bash -
  sleep 10
  if [ -f /usr/local/bin/k3s ]
  then 
     ln -s /usr/local/bin/k3s /usr/sbin/kubectl
     kubectl completion bash > /etc/bash_completion.d/kubectl_completion
     curl -sO https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz && tar -xvzf helm-$HELM_VERSION-linux-amd64.tar.gz && mv -v linux-amd64/helm /usr/local/bin && rm -rvf helm-$HELM_VERSION-linux-amd64.tar.gz  linux-amd64
 fi
}

generate_certificate () {
   openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out ./base/tls.crt -keyout ./base/tls.key -subj "/CN=${AWX_HOST}/O=${AWX_HOST}" -addext "subjectAltName = DNS:${AWX_HOST}"
}

deploy_awx () {
   mkdir -p ~/.kube
   cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
   chmod 600 ~/.kube/config
   mkdir -p /awx/data/{postgres,projects}
   chmod 755 /awx/data/postgres
   chown 1000:0 /awx/data/projects 
   helm repo add awx-operator https://ansible.github.io/awx-operator/
   helm repo update
   helm install -n awx --create-namespace my-awx-operator awx-operator/awx-operator
   sleep 30
   kubectl apply -k base
}


if [ $1 == '--k3s' ]
then
 config_systems
 install_dependencies
fi

if [ $1 == '--awx' ]
then
  if [ $GENERATE_CERTIFICATE == "TRUE" ]
  then
	  generate_certificate
  fi	  
     deploy_awx
fi

if [ $1 == '--all' ]
then
   config_systems
   install_dependencies
    if [ $GENERATE_CERTIFICATE == "TRUE" ]
    then
          generate_certificate
    fi
   deploy_awx
fi

if [ $1 == '--uninstall' ]
then
  /usr/local/bin/k3s-uninstall.sh
  rm -rf ~/.kube
  rm -f /usr/local/bin/helm
fi

