#!/bin/bash
##### Deploy K3s with nfs-provisioners and helm #####
### vars ###
export IP_NFS_SERVER=$(hostname -I | awk '{print $1}')
export OPERATOR_TAG=0.14.0
export HELM_VERSION=v3.7.0
export AWX_HOST="awx.labtest.com.py"
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
  dnf update -y && dnf install vim bash-completion nfs-utils tar -y
  firewall-cmd --add-service=nfs --add-service=http --add-service=https --permanent && firewall-cmd --reload
  firewall-cmd --add-masquerade --permanent && firewall-cmd --reload
  sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
  setenforce 0
  systemctl enable nfs-server --now
}

install_dependencies () {
  curl -sfL https://get.k3s.io | sudo bash -
  sleep 10
  if [ -f /usr/local/bin/k3s ]
  then 
     ln -s /usr/local/bin/k3s /usr/sbin/kubectl
     kubectl completion bash > /etc/bash_completion.d/kubectl_completion
     curl -sO https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz && tar -xvzf helm-$HELM_VERSION-linux-amd64.tar.gz && mv -v linux-amd64/helm /usr/sbin/ && rm -rvf helm-$HELM_VERSION-linux-amd64.tar.gz  linux-amd64
     helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
     mkdir -v /data && chown -Rv nobody.nobody /data
     echo "/data $IP_NFS_SERVER/32(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
     exportfs -arv
     exportfs -s
     helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=$IP_NFS_SERVER --set nfs.path=/data --kubeconfig=/etc/rancher/k3s/k3s.yaml
 fi
}

generate_certificate () {
   openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out ./base/tls.crt -keyout ./base/tls.key -subj "/CN=${AWX_HOST}/O=${AWX_HOST}" -addext "subjectAltName = DNS:${AWX_HOST}"
}
deploy_awx () {
   #kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/$OPERATOR_TAG/deploy/awx-operator.yaml
   git clone --single-branch --branch=$OPERATOR_TAG https://github.com/ansible/awx-operator.git
   cd awx-operator
   make deploy
   sleep 30
   cd ..
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

