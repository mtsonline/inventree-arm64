# inventree-arm64
Docker compose setup for Inventree on a Raspberry Pi 5 ARM64 
## description
this docker compose setup allows you to install Inventree on an ARM64 based Raspberry (e.g. RasPi 5)    
As the original image does not start on ARM platform operating systems I created a dockerfile that rebuilds the image with some changes in package versions, that would not build or run on a Raspberry Pi.    
I removed the hash verification of the requirements - if someone has enough time this could be improved by recreating all the hashes for the currently working packages and replacing the old requirements file during the build of the image in the dockerfile.    
It also would be great to use the most recent working package versions instead of the ones Inventree uses originally - but at least I got it to run with the versions specyfied in the dockerfile for all requirements.    
The last tested version of Inventree was V0.17.13.

## installation
* Checkout the repo:    

        git clone https://github.com/mtsonline/inventree-arm64.git inventree    

* change the settings in the .env file and the hash in the specyfied secret key file.    
* decide if you need selfsigned certs: in the Caddyfile comment "tls internal" if you are going to use a public domain.    
* execute the following commands:    

        cd inventree # change into the cloned directory    
        chown -R 1000:999 backup_data # set the correct users that will be used in the docker container    
        chown -R 1000:999 inventree-data # set the correct users that will be used in the docker container    
        chown -R 999 pgdb # set the correct users that will be used in the docker container    
        docker pull python:3.11-slim-bookworm # does preload the image - much faster    
        docker compose build # builds the image for ARM64    
        docker compose run inventree-server  invoke update # does initialize inventree - see the documentation for more details on the installation of inventree    
        docker compose up -d # starts inventree    



Hope this may help others to install Inventree on their Raspberry Pies :-)    
Feel free to improve or enhance this setup
