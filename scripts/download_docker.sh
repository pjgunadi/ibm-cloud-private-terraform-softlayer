#!/bin/bash
LOGFILE=/tmp/download_install_docker.log
exec  > $LOGFILE 2>&1

BASEDIR=$(dirname "$0")
docker_src_server=$1
docker_src_user=$2
docker_src_password=$3
docker_src_path=$4
docker_tgt_path=$5

if [ -n "$docker_src_user" -a -n "$docker_src_password" -a -n "$docker_src_path" -a -n "$docker_tgt_path" -a ! -s "$docker_tgt_path" ]; then
  if [[ "${docker_src_path:0:3}" == "s3:" ]]; then
    pip install awscli
    echo -e "${docker_src_user}\n${docker_src_password}\n${docker_src_server}\n" | aws configure
    aws s3 cp ${docker_src_path} ${docker_tgt_path}
    rm -f ~/.aws/credentials
  else
    echo "Start downloading installation file"
    sshpass -p "$docker_src_password" scp -o StrictHostKeyChecking=no $docker_src_user@$docker_src_server:$docker_src_path $docker_tgt_path
    if [ "$?" != "0" ]; then
      python $BASEDIR/remote_copy.py $docker_src_server $docker_src_user $docker_src_password $docker_src_path $docker_tgt_path
      echo "Completed download installation file"
    fi
  fi
elif [ -z "$docker_src_user" -a -z "$docker_src_password" -a -n "$docker_src_path" -a -n "$docker_tgt_path" -a ! -s "$docker_tgt_path" ]; then
  mv $docker_src_path $docker_tgt_path
elif [ -s "$docker_tgt_path" ]; then
  echo "Target file exist"
else
  echo "No input for download."
fi

if [ -n "$docker_tgt_path" -a -f "$docker_tgt_path" ]; then
  chmod +x $docker_tgt_path
  sudo $docker_tgt_path --install
fi

#If no installer, download docker from internet
if grep -q -i ubuntu /etc/*release
  then
    OSLEVEL=ubuntu
  else
    OSLEVEL=other
fi
if [ "$OSLEVEL" == "ubuntu" ]; then
  if [ -z "$(which docker)" ]; then
    retries=20
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get install -y docker-ce
    while [ $? -ne 0 -a "$retries" -gt 0 ]; do
      retries=$((retries-1))
      echo "Another process has acquired the apt-get install/upgrade lock; waiting 10s" >&2
      sleep 10;
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      sudo apt-get install -y docker-ce
    done
    if [ $? -ne 0 -a "$retries" -eq 0 ] ; then
      echo "Maximum number of retries (20) for apt-get install attempted; quitting" >&2
      exit 1
    fi
  fi
else
  if [ -z "$(which docker)" ]; then
    sudo rpm -ivh http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.21-1.el7.noarch.rpm
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum -y install docker-ce
  fi
fi

sudo systemctl enable docker
sudo systemctl start docker