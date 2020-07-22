## PRE-REQUISITES
- Docker 1.12.0 (See [Appendix A](#appendix-a))
- Services 
  - Sbt 
  - Swagger
- UI


## IP RANGE:
- Mysql               : 10-14
- Postgress           : 15-19
- Elastic Search      : 20-24
- Kibana              : 25
- Redis               : 30-34
- Cassandra           : 50-54  
- Zookeeper           : 70-79
- Kafka               : 80-84
- AWS Kinesis         : 85-89
- Keycloak            : 90-91
- HA proxy            : 95
- Services            : 90-100

## CONTAINERS
- 172.18.0.10   : Mysql
- 172.18.0.20   : Elastic Search
- 172.18.0.30   : Redis
- 172.18.0.70   : Zookeeper
- 172.18.0.80   : Kafka
- 172.18.0.90   : keycloak


## SETUP

1. Add bin folder to OS's PATH (Preferably in folder where other vizix projects are )

   For Debian/Ubuntu
   ```sh
   # add to ~/.bashrc
   export MAX_HOME=<max-projects-folder>/max-dev-bin
   export PATH="$PATH:$MAX_HOME"
   source $MAX_HOME/set-env
   ```
   
2. Open a new terminal.
   It should show in the console the list of IP address.

3. create max network

    ```sh
    create-network
    ```

4. create data folder to mount the volumes:

    ```sh
    mkdir ~/docker-volumes
    ```

5. create basic services

    ```sh
    run-elasticsearch
    run-kafka-zookeeper
    ```

    ***IMPORTANT***
    Please when building docker images sometimes you will need to stop resolvable container.


6. deploy services

    build product order backend

    ```sh
    cd <path_to_product_order_backend>
    build-product-order-backend
    ```

    build party management backend
   
       ```sh
       cd <path_to_party_management_backend>
       build-party-management-backend
       ```
    
## Optional third parties
For Monitoring, visualisation & management for Docker (https://www.weave.works/products/weave-scope/)
```sh
run-weavescope
```
## Appendix A
If you do not have Docker installed in your PC, you can install it depending your OS, the following link has specific details depending on your distribution or OS:
https://docs.docker.com/engine/installation/
