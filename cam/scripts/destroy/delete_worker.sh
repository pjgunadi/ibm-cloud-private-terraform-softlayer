#!/bin/bash
DefaultOrg="ibmcom"
DefaultRepo="icp-inception"
ip=$2

if [ -z "$3" ]; then
  ICPDIR=/opt/ibm/cluster
else
  ICPDIR=$3
fi

# Populates globals $org $repo $tag
function parse_icpversion() {

  # Determine organisation
  if [[ $1 =~ .*/.* ]]
  then
    org=$(echo $1 | cut -d/ -f1)
  else
    org=$DefaultOrg
  fi
  
  # Determine repository and tag
  if [[ $1 =~ .*:.* ]]
  then
    repo=$(echo $1 | cut -d/ -f2 | cut -d: -f1)
    tag=$(echo $1 | cut -d/ -f2 | cut -d: -f2)
  else
    repo=$DefaultRepo
    tag=$1
  fi
}

parse_icpversion $1

kubectl="sudo docker run -e LICENSE=accept --net=host -v $ICPDIR:/installer/cluster -v /root:/root $org/$repo:$tag kubectl"
  
$kubectl config set-cluster cfc-cluster --server=https://localhost:8001 --insecure-skip-tls-verify=true 
$kubectl config set-context kubectl --cluster=cfc-cluster 
$kubectl config set-credentials user --client-certificate=/installer/cluster/cfc-certs/kubecfg.crt --client-key=/installer/cluster/cfc-certs/kubecfg.key 
$kubectl config set-context kubectl --user=user 
$kubectl config use-context kubectl
#$kubectl drain $ip --grace-period=300
$kubectl drain $ip --force
docker run -e LICENSE=accept --net=host -v "$ICPDIR":/installer/cluster $org/$repo:$tag uninstall -l $ip
$kubectl delete node $ip
sudo sed -i "/^$ip.*$/d" /etc/hosts
sudo sed -i "/^$ip.*$/d" /opt/ibm/cluster/hosts
