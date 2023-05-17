#!/bin/bash

#Atualizar o sistema
yum update -y
yum upgrade -y

#instalar nfs-utils(necessario para o efs)
yum install -y nfs-utils
sudo yum install -y amazon-efs-utils
#cria o diretorio onde o efs sera montado
mkdir /efs
#espera um pouco para ter certeza que o efs vai conseguir montar
sleep 10
#monta o efs
mount -t efs -o tls "${EFS_ID}":/ /efs
#mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "${EFS_ID}":/ /efs
#vai montar o efs automaticamente toda vez que a instancia for ligada
echo "${EFS_ID}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

#instala docker
yum install docker -y
#habilita o docker
systemctl enable docker
#começa o docker
systemctl start docker
#adiciona o usuario ao grupo docker
usermod -aG docker ec2-user

#instala docker-compose
pip3 install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc

#cria o diretorio onde o docker-compose sera inserido
mkdir /home/ec2-user/wordpress-compose
#cria o arquivo docker-compose.yml em /home/ec2-user/wordpress-compose
cat<< 'EOF' >/home/ec2-user/wordpress-compose/docker-compose.yml
version: '3.1'

services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: "${DB_HOST}"
      WORDPRESS_DB_USER: "admin"
      WORDPRESS_DB_PASSWORD: "admin123"
      WORDPRESS_DB_NAME: "wordpress"
    volumes:
      - /efs/wordpress:/var/www/html
EOF

#inicia o docker-compose
docker-compose -f /home/ec2-user/wordpress-compose/docker-compose.yml up -d