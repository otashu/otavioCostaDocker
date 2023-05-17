# Documentação de uma arquitetura na AWS utilizando Docker
Este repositório tem como objetivo conter uma documentação necessária para configurar uma arquitetura na AWS e a utilização de docker, de acordo com os requisitos citados abaixo.

## Arquitetura a ser implementada:
<p align="center">
  <img src="https://github.com/PinheiroChequin/TrabalhoDocker/assets/117855728/a739dc36-9159-4b95-8ed6-e633545a202f">
</p>

Na implementação da arquitetura acima, foi utilizado o Terraform visando aplicabilidade e eficiência. Todos os arquivos utilizados estão disponíveis no seguinte repositório: [Terraform](https://github.com/otashu/otavioCostaDocker/tree/main/proj-compass).

A configuração das instâncias utilizadas encontra-se abaixo:

# Configuração das Instâncias:
-Instâncias principais-
- _**SO: Amazon Linux 2**_
- _**Família: t3.small**_
- _**Volume: 1x16GB gp2**_

-Bastion Host-
- _**SO: Amazon Linux 2**_
- _**Família: t2.micro**_
- _**Volume: 1x8GB gp2**_

Observação: O docker, bem como o docker-compose já foram inicializados na criação das instâncias através do `userdata`.

Todo o `userdata` encontra-se comentado em: [userdata](https://github.com/otashu/otavioCostaDocker/tree/main/proj-compass/user_data.sh)

O script do docker-compose encontra-se em: [docker-compose](https://github.com/otashu/otavioCostaDocker/blob/main/docker-compose.yml)

# Configuração da VPC(Virtual Private Cloud)
Com a Amazon Virtual Private Cloud (Amazon VPC), é possível iniciar recursos da AWS em uma rede virtual definida pelo usuário. Essa rede virtual é bem parecida com uma rede tradicional, com a vantagem de usar a infraestrutura da AWS.

<p align="center">
  <img src="https://github.com/PinheiroChequin/TrabalhoDocker/assets/129349503/f4e098f6-8918-4ba0-a9b7-b06f8c441832">
</p>
<p align="center">
  Fonte: <a href="https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html" style="display: block; text-align: center;">Amazon Virtual Private Cloud</a>
</p>

## **Criação de uma VPC**
Após definir uma rede virtual, a VPC foi configurada com sub-redes, tabelas de rotas, um gateway da Internet e um gateway NAT.
No exemplo utilizado, encontram-se:

- _4 sub-redes (2 privadas e 2 públicas)_ 

Assim estará acessível em duas zonas de disponibilidade.

- _2 tabelas de rotas(1 para gateway de internet e outra para o NAT)_
- _2 gateways(O gateway de internet e o NAT)_


-> Uma `subnet` é uma gama de endereços IP na VPC. Uma sub-rede deve residir em uma única zona de disponibilidade. 

-> Usa-se `route tables` para determinar para onde o tráfego da sub-rede ou do gateway será direcionado.

-> Um `gateway` conecta a VPC a uma outra rede. Por exemplo, use um **gateway da Internet** para conectar a VPC à Internet.

Toda configuração da VPC foi feita atráves do Terraform e encontra-se neste repositório: [VPC](https://github.com/otashu/otavioCostaDocker/tree/main/proj-compass/network.tf)

# Configuração do Aplication Load Balancer
O Elastic Load Balancer utilizado distribui automaticamente o tráfego de entrada, monitorando a 'saúde' dos alvos e encaminhando o tráfego somente para esses alvos saudáveis.

A estrutura utilizada é:
Load Balacer -> Listener e suas regras -> Target Group

1. Load Balancer: serve como um único ponto de contato para clientes, sendo assim ele que irá distribuir o tráfego de entrada da aplicação em vários destinos;
2. Listener: verifica as solicitações de conexão de clientes, as regras aplicadas ao listener que determinam como o load balancer roteia as solicitações para os destinos registrados;
3. Target Group: encaminha solicitações para os destinos registrados, como no caso desta aplicação para um instância EC2 usando protocolo e o número da porta especificado.

Em resumo, nesta aplicação O Aplication Load Balancer recebe uma solicitação, avalia as regras definidas no Listener e por fim seleciona um destino do Target Group para executar a ação da regra.

Na arquitetura proposta o Aplication Load Balancer irá receber o tráfego de clientes, o Listener a regra de protocolo HTTP e porta 80 e por fim o Target Group possui como alvo uma das duas instâncias com a aplicação do WordPress rodando. 

Toda configuração do Load Balancer foi feita atráves do Terraform e encontra-se neste repositório: [Load Balancer](https://github.com/otashu/otavioCostaDocker/tree/main/proj-compass/vm.tf)

# Configuração do RDS da AWS

A Amazon Relational DataBase Service (RDS) é um serviço da Web que facilita a configuração de um banco de dados relacional. 

No projeto em questão foi usado uma instância de banco de dados, o qual é um ambiente de banco de dados isolado em nuvem. 
O mecanismo de suporte ao banco de dados que foi utilizado é o MySQL. 

Na criação da instância, assim como qualquer banco de dados, foi criado o usuário principal, senha e nome do banco de dados. Além disso, na criação foi atribuído uma VPC e não foi dado um IP público a instância de banco de dados, sendo assim o acesso só é possível através das instâncias EC2 que encontram-se na mesma VPC que o banco de dados.

Toda configuração do RDS foi feita atráves do Terraform e encontra-se neste repositório: [RDS](https://github.com/otashu/otavioCostaDocker/tree/main/proj-compass/main.tf)
# Configuração do Terraform

Nota: É necessário possuir um par de chaves e as credenciais do usuário da AWS para prosseguir com a configuração do Terraform. 

A configuração inicial do Terraform, do EFS e do RDS encontram-se no [`main.tf`](https://github.com/otashu/otavioCostaDocker/tree/main/proj-compass/main.tf)

Toda configuração da VPC, com suas sub-redes, tabelas de rotas, gateway de internet e o NAT gateway encontram-se em [`network.tf`](https://github.com/otashu/otavioCostaDocker/tree/main/proj-compass/network.tf)

O [`outputs.tf`](https://github.com/PinheiroChequin/TrabalhoDocker/blob/main/proj-compass/outputs.tf) apenas mostrará o DNS do Load Balancer criado no Terraform.

E por fim, a configuração das instâncias EC2 juntamente com a configuração do grupo de segurança, configuração do Load Balancer e do Auto Scaling encontram-se em [`vm.tf`](https://github.com/otashu/otavioCostaDocker/tree/main/proj-compass/vm.tf)

Os códigos usados no Terraform encontram-se todos comentados nesse repositório.

