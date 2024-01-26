#!/bin/bash

welcome () {
	echo "WELCOME TO"
	echo "#     # ####### ######  ####### ######  #     # #     # #     # ####### ######  
##    # #     # #     # #       #     # #     # ##    # ##    # #       #     # 
# #   # #     # #     # #       #     # #     # # #   # # #   # #       #     # 
#  #  # #     # #     # #####   ######  #     # #  #  # #  #  # #####   ######  
#   # # #     # #     # #       #   #   #     # #   # # #   # # #       #   #   
#    ## #     # #     # #       #    #  #     # #    ## #    ## #       #    #  
#     # ####### ######  ####### #     #  #####  #     # #     # ####### #     # "
	echo "Your Cardano Stack Helper."
	echo "Please visit https://github.com/onchainapps/noderunner for more information."
	echo
	echo 
	echo
}

menu () {
	echo "#########MENU#########"
	echo 
	echo "A: Build Cardano Node with Ogmios Docker images."
	echo "B: Build Kupo Docker image."
	echo "C: Build and Run Postgresql for carp Indexer."
	echo "D: Build Carp Indexer (Only indexs CIP25 metadata with label 721) Docker image."
	echo "E: Build Carp Webserver Docker image that will allow you to query NFT metadata, example is shown after the setup is complete."
	echo "F: Setup Docker for Debian."
	echo "G: Prune unused Docker images, this on average can free up 10GB of HD space. These are images that were used when the different services were building from source."
	echo "H: Setup IPFS Docker contianer. https://docs.ipfs.tech/how-to/run-ipfs-inside-docker/#set-up"
	echo
	read menuItem

	if [ $menuItem == "A" ] || [ $menuItem == "a" ]; then
		ogmios
	elif [ $menuItem == "B" ] || [ $menuItem == "b" ]; then
		kupo
	elif [ $menuItem == "C" ] || [ $menuItem == "c" ]; then
		postgresql
	elif [ $menuItem == "D" ] || [ $menuItem == "d" ]; then
		carp-indexer
	elif [ $menuItem == "E" ] || [ $menuItem == "e" ]; then
		carp-webserver
	elif [ $menuItem == "F" ] || [ $menuItem == "f" ]; then
		installDockerDebian
	elif [ $menuItem == "G" ] || [ $menuItem == "g" ]; then
		dockerPruneImages
	elif [ $menuItem == "H " ] || [ $menuItem == "h" ]; then
		ipfs
	else
		menu
	fi
}

ogmios () {
	echo
	echo "Spinning up up OGMIOS docker container." &&
	echo
	if [ ! -d "./ogmios" ] 
	then
		git clone https://github.com/onchainapps/ogmios
	fi
	cd ogmios &&
	docker build -t cardano-node-ogmios . &&
	echo
	echo "Run the docker command below to spin up Cardano-Node and Ogmios, all other docker containers/services rely on this one."
	echo
	echo "docker run -itd --restart=always --name cardano-node-ogmios -p 1337:1337 -v cardano-node-db:/db -v cardano-node-ipc:/ipc -v cardano-node-config:/config cardano-node-ogmios"
	echo
	echo "you can run 'docker ps -a' to show all running and stopped containers and 'docker logs <container name> will give you all the logs of a container if one stopped for whatever reason."
}

kupo () {
	echo
	echo "Spinning up KUPO docker container."
	echo
	if [ ! -d "./kupo" ]
	then
		git clone https://github.com/onchainapps/kupo
	fi
	cd kupo &&
	docker build -t kupo . &&
	echo
	echo "Run the docker command below to spin up the Kupo UTXO indexer, if you are familiar with command line you can pass extra Kupo parameters otherwise the default will be executed."
	echo
	echo "docker run -itd --restart=always --name kupo -p 0.0.0.0:1442:1442 -v kupo-db:/db -v cardano-node-ipc:/ipc -v cardano-node-config:/config kupo --node-socket /ipc/node.socket --node-config /config/cardano-node/config.json --host 0.0.0.0 --workdir /db --prune-utxo --since 16588737.4e9bbbb67e3ae262133d94c3da5bffce7b1127fc436e7433b87668dba34c354a --match \"*/*\""
	echo
	echo "you can run 'docker ps -a' to show all running and stopped containers and 'docker logs <container name> will give you all the logs of a container if one stopped for whatever reason."
}

postgresql () {
	echo
	echo "Spinning up Postgresql dcoker container."
	echo
	docker run -itd --restart=always --name postgres -p 0.0.0.0:5432:5432 -v carp-postgres-db:/var/lib/postgresql/data -e POSTGRES_LOGGING=true -e POSTGRES_DB=carp -e POSTGRES_USER=carp -e POSTGRES_PASSWORD=carpdb postgres
}

carp-indexer () {
	echo
	echo "Spinning up Carp indexer for CIP-25 metadata."
	echo
	if [ ! -d "./carp" ]
	then
		git clone https://github.com/onchainapps/carp
	fi
	cd carp &&
	docker build -t carp-indexer . &&
	echo
	echo "To run the carp indexer docker container execute the docker command below. Please remember to update the IP address to where your postgresql DB is running"
	echo
	echo "Docker Command"
	echo
	echo "docker run -itd --restart=always --name carp-indexer -v cardano-node-ipc:/app/node-ipc -v ./carp/indexer/configs/:/app/config/indexer -e NETWORK=mainnet -e SOCKET=/app/node-ipc/node.socket -e DATABASE_URL=postgresql://carp:carpdb@<postgres host ip>:5432/carp carp-indexer"
	echo
	echo "you can run 'docker ps -a' to show all running and stopped containers and 'docker logs <container name> will give you all the logs of a container if one stopped for whatever reason."
}

carp-webserver () {
	echo
	echo "Spinning up Carp webserver to access cip-25 metadata through the carp API."
	echo
	if [ ! -d "./carp" ]
	then
		git clone https://github.com/onchainapps/carp
	fi
	cd carp/webserver &&
	docker build -t carp-webserver . &&
	echo
	echo "To run the carp webserver container execute the docker command below. Please remember to update the IP address to where your postgresql DB is running"
	echo
	echo "Docker Command"
	echo
	echo "docker run -itd --restart=always --name carp-webserver -p 0.0.0.0:3000:3000 -e DATABASE_URL=postgresql://carp:carpdb@<Postgresql Host IP address>:5432/carp carp-webserver"
	echo
	echo "Run the curl command below to test if your carp-websever started properly, you can also run 'docker ps -a' and it'll show all running and stopped containers."
	echo
	echo "curl --location --request POST 'http://localhost:3000/metadata/nft' --header 'Content-Type: application/json' --data-raw '{ \"assets\": { \"0fe7b9c1abbf139414d8e138721a85dd8d6e24ee7dc0d895587b4f57\": [ \"6a633030303030303031\" ] } }'"
	echo
}

installDockerDebian () {
	echo
	echo "Attempting to setup Docker"
	echo
	sh ./setupDockerDebian.sh
}

dockerPruneImages () {
	echo
	echo "These images aren't needed unless you plan on rebuilding any service from source, in whcih case keeping them can speed up the process."
	echo
	docker image prune -a
	echo
}

ipfs () {
	echo
	echo "Setting up IPFS Docker conatiner."
	echo
	docker run -d --name ipfs -v ipfs_staging:/export -v ipfs_data:/data/ipfs -p 4001:4001 -p 4001:4001/udp -p 127.0.0.1:8080:8080 -p 127.0.0.1:5001:5001 ipfs/kubo:latest
	echo
}

welcome
menu
