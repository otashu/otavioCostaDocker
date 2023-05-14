#!/bin/bash

yum install -y nfs-utils
mkdir /efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "${EFS_ID}":/ /efs
echo "${EFS_ID}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

yum install mysql -y
yum install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
pip3 install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
mkdir /home/ec2-user/wordpress-compose
cat<< 'EOF' >/home/ec2-user/wordpress-compose/docker-compose.yml
version: '3.1'

services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: ${DB_HOST}
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: admin123
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /efs/wordpress:/var/www/html
EOF

docker-compose -f /home/ec2-user/wordpress-compose/docker-compose.yml up -d