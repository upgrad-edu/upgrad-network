#!/bin/bash

export PATH=${PWD}/bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  network.sh <mode> [-c <channel name>] [-t <timeout>] [-d <delay>] [-f <docker-compose-file>] [-s <dbtype>] [-l <language>] [-o <consensus-type>] [-i <imagetag>] [-v]"
  echo "    <mode> - one of 'up', 'down', 'restart', or 'generate'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "    -c <channel name> - channel name to use (defaults to \"channelthreeorgs\")"
  echo "    -t <timeout> - CLI timeout duration in seconds (defaults to 20)"
  echo "    -d <delay> - delay duration in seconds (defaults to 20)"
  echo "    -f <docker-compose-file> - specify which docker-compose file use (defaults to docker-compose.yml)"
  echo "    -s <dbtype> - the database backend to use: couchdb (default)"
  echo "    -l <language> - the chaincode language: node (default)"
  echo "    -o <consensus-type> - the consensus-type of the ordering service: kafka (default), solo, or etcdraft"
  echo "    -i <imagetag> - the tag to be used to launch the network (defaults to \"latest\")"
  echo "    -v new version of updated chaincode to install on all endorsers"
  echo "  network.sh -h (print this message)"
  echo
  echo "Typically, one would first generate the required certificates and "
  echo "genesis block, then bring up the network. e.g.:"
  echo
  echo "	network.sh generate -c channelthreeorgs"
  echo "	network.sh up -c channelthreeorgs -s couchdb"
  echo "        network.sh up -c channelthreeorgs -s couchdb -i 1.4.0"
  echo "	network.sh up -l node"
  echo "	network.sh down -c channelthreeorgs"
  echo
  echo "Taking all defaults:"
  echo "	network.sh generate"
  echo "	network.sh up"
  echo "	network.sh down"
}

# Ask user for confirmation to proceed
function askProceed() {
  read -p "Continue? [Y/n] " ans
  case "$ans" in
  y | Y | "")
    echo "proceeding ..."
    ;;
  n | N)
    echo "exiting..."
    exit 1
    ;;
  *)
    echo "invalid response"
    askProceed
    ;;
  esac
}

# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*.mycc.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f "$CONTAINER_IDS"
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# TODO list generated image naming patterns
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*.mycc.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f "$DOCKER_IMAGE_IDS"
  fi
}

# Versions of fabric known not to work with this release of first-network
BLACKLISTED_VERSIONS="^1\.0\. ^1\.1\.0-preview ^1\.1\.0-alpha"

# Do some basic sanity checking to make sure that the appropriate versions of fabric
# binaries/images are available.  In the future, additional checking for the presence
# of go or other items could be added.
function checkPrereqs() {
  # Note, we check configtxlator externally because it does not require a config file, and peer in the
  # docker image because of FAB-8551 that makes configtxlator return 'development version' in docker
  LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:"$IMAGETAG" peer version | sed -ne 's/ Version: //p' | head -1)

  echo "LOCAL_VERSION=$LOCAL_VERSION"
  echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    echo "=================== WARNING ==================="
    echo "  Local fabric binaries and docker images are  "
    echo "  out of  sync. This may cause problems.       "
    echo "==============================================="
  fi

  for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
    echo "$LOCAL_VERSION" | grep -q "$UNSUPPORTED_VERSION"
    if [ $? -eq 0 ]; then
      echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match this newer version of channelthreeorgs and is unsupported. Either move to a later version of Fabric or checkout an earlier version of channelthreeorgs."
      exit 1
    fi

    echo "$DOCKER_IMAGE_VERSION" | grep -q "$UNSUPPORTED_VERSION"
    if [ $? -eq 0 ]; then
      echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match this newer version of channelthreeorgs and is unsupported. Either move to a later version of Fabric or checkout an earlier version of channelthreeorgs."
      exit 1
    fi
  done
}

# Generate the needed certificates, the genesis block and start the network.
function networkUp() {
  checkPrereqs
  # generate artifacts if they don't exist
  if [ ! -d "crypto-config" ]; then
    generateCerts
    replacePrivateKey
    generateChannelArtifacts
  fi
  if [ "${IF_COUCHDB}" == "couchdb" ]; then
    if [ "$CONSENSUS_TYPE" == "kafka" ]; then
      IMAGE_TAG=$IMAGETAG docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_FILE_KAFKA" up -d 2>&1
      docker ps -a
    elif [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
      IMAGE_TAG=$IMAGETAG docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_FILE_RAFT2" up -d 2>&1
      docker ps -a
    else
      IMAGE_TAG=$IMAGETAG docker-compose -f "$COMPOSE_FILE" up -d 2>&1
      docker ps -a
    fi
  else
    if [ "$CONSENSUS_TYPE" == "kafka" ]; then
      IMAGE_TAG=$IMAGETAG docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_FILE_KAFKA" up -d 2>&1
      docker ps -a
    elif [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
      IMAGE_TAG=$IMAGETAG docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_FILE_RAFT2" up -d 2>&1
      docker ps -a
    else
      IMAGE_TAG=$IMAGETAG docker-compose -f "$COMPOSE_FILE" up -d 2>&1
      docker ps -a
    fi
  fi
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  fi

  if [ "$CONSENSUS_TYPE" == "kafka" ]; then
    sleep 1
    echo "Sleeping 40s to allow $CONSENSUS_TYPE cluster to complete booting"
    sleep 39
  fi

  if [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
    sleep 1
    echo "Sleeping 15s to allow $CONSENSUS_TYPE cluster to complete booting"
    sleep 14
  fi

  if [ "$CONSENSUS_TYPE" == "solo" ]; then
    sleep 1
    echo "Sleeping 10s to allow cluster to complete booting"
    sleep 9
  fi

  # now run the bootstrap script
  docker exec cli scripts/bootstrap.sh "$CHANNEL_NAME" "$CLI_DELAY" "$LANGUAGE" "$CLI_TIMEOUT" "$VERBOSE"
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Test failed"
    exit 1
  fi
}

# Generate the needed certificates, the genesis block and start the network.
function bootstrapRetry() {
  checkPrereqs
  # now run the bootstrap script
  docker exec cli scripts/bootstrap.sh "$CHANNEL_NAME" "$CLI_DELAY" "$LANGUAGE" "$CLI_TIMEOUT" "$VERBOSE"
}

function setupComposer() {
  checkPrereqs
  CONNECTION_PROFILE=./composer/networkConnection-amazon.yaml

  # Fetch the private key from crypto materials and use it to create the private key and certificate path
  CURRENT_DIR=$PWD
  cd crypto-config/peerOrganizations/amazon.upgrad-network.com/users/Admin@amazon.upgrad-network.com/msp/keystore/ || exit
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR" || exit
  PRIVATE_KEY=./crypto-config/peerOrganizations/amazon.upgrad-network.com/users/Admin@amazon.upgrad-network.com/msp/keystore/"${PRIV_KEY}"
  CERT=./crypto-config/peerOrganizations/amazon.upgrad-network.com/users/Admin@amazon.upgrad-network.com/msp/signcerts/Admin@amazon.upgrad-network.com-cert.pem
  CARDOUTPUT=PeerAdmin@upgrad-network-amazon.card

  # Create a new business network card for the administrator to use to deploy the composer business network to fabric network
  # TODO: Repeat this step for all organizations
  composer card create -p "$CONNECTION_PROFILE" -u PeerAdmin -c "$CERT" -k "$PRIVATE_KEY" -r PeerAdmin -r ChannelAdmin -f "$CARDOUTPUT"

  # Check if a card with the same name has previously been imported? If yes, remove it before importing a new one.
  if composer card list -c PeerAdmin@upgrad-network-amazon >/dev/null; then
    composer card delete -c PeerAdmin@upgrad-network-amazon
  fi

  # Import the business network card for Amazon into the wallet
  # TODO: Repeat this step for all organizations
  composer card import -f PeerAdmin@upgrad-network-amazon.card --card PeerAdmin@upgrad-network-amazon
  composer card list
  echo "Hyperledger Composer PeerAdmin@upgrad-network-amazon card has been imported"

  # Remove the card file from filesystem after card has been imported to wallet
  # TODO: Repeat this step for all organizations
  rm PeerAdmin@upgrad-network-amazon.card

  # Create a composer business network archive (bna) based on the model and script file
  cd ./composer || exit
  composer archive create -t dir -n . -a dist/upgrad-network.bna

  # Install the composer business network on fabric peer nodes for Amazon
  # TODO: Repeat this step to install composer BBN on peers of all organizations
  composer network install --card PeerAdmin@upgrad-network-amazon --archiveFile ./dist/upgrad-network.bna

  # Retrieve certificates for a user [Aakash] to use as the business network administrator for Amazon
  # TODO: Retrieve certificates for administrators of all organizations
  composer identity request -c PeerAdmin@upgrad-network-amazon -u admin -s adminpw -d aakash

  # Start the business network with user [Aakash] from Amazon as the administrator allowing him to add new participants from their orgs.
  # TODO: Add the administrators from other orgs to this command
  composer network start -c PeerAdmin@upgrad-network-amazon -n upgrad-network -V 0.0.1 -o endorsementPolicyFile=./endorsement-policy.json -A aakash -C aakash/admin-pub.pem

  # Create a business network card that Aakash can use to access the business network on behalf of Amazon
  composer card create -p ./../"$CONNECTION_PROFILE" -u aakash -n upgrad-network -c aakash/admin-pub.pem -k aakash/admin-priv.pem

  # Check if a card with the same name has previously been imported? If yes, remove it before importing a new one.
  if composer card list -c aakash@upgrad-network >/dev/null; then
    composer card delete -c aakash@upgrad-network
  fi

  # Import the business network card into wallet for Amazon admin user [Aakash]
  composer card import -f aakash@upgrad-network.card

  # Ping the network using this card just created
  composer network ping -c aakash@upgrad-network

  # Add a new participant (Amazon Pay) as a Manufacturer to the business network
  composer participant add -c aakash@upgrad-network -d '{"$class":"org.upgrad.network.Manufacturer","traderId":"1290", "companyName":"Amazon Pay", "address": {"$class": "org.upgrad.network.Address"}}'

  # Issue a new identity for the Amazon Pay manufacturer
  composer identity issue -c aakash@upgrad-network -f apay.card -u apay -a "resource:org.upgrad.network.Manufacturer#1290"

  # Import the card for new Amazon Pay user into wallet
  composer card import -f apay.card

  # Test the business network access of Amazon Pay user
  composer network ping -c apay@upgrad-network
}

function updateChaincode() {
  checkPrereqs
  docker exec cli scripts/updateChaincode.sh "$CHANNEL_NAME" "$CLI_DELAY" "$LANGUAGE" "$VERSION_NO"
}

function installChaincode() {
  checkPrereqs
  docker exec cli scripts/installChaincode.sh "$CHANNEL_NAME" "$CLI_DELAY" "$LANGUAGE" "$VERSION_NO"
}

# Tear down running network
function networkDown() {
  # stop all containers
  # stop kafka and zookeeper containers in case we're running with kafka consensus-type
  docker-compose -f "$COMPOSE_FILE" down --volumes --remove-orphans

  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # Bring down the network, deleting the volumes
    #Delete any ledger backups
    docker run -v "$PWD":/tmp/channelthreeorgs --rm hyperledger/fabric-tools:"$IMAGETAG" rm -Rf /tmp/channelthreeorgs/ledgers-backup
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove orderer block and other channel configuration transactions and certs
    rm -rf channel-artifacts/*.block channel-artifacts/*.tx crypto-config
  fi
}

# Using docker-compose.yml, replace constants with private key file names
# generated by the cryptogen tool and output a docker-compose.yml specific to this
# configuration
function replacePrivateKey() {
  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and delete it at the end of the function
  ARCH=$(uname -s | grep Darwin)
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi

  # Copy the template to the file that will be modified to add the private key
  cp docker-compose-template.yaml docker-compose.yml

  # The next steps will replace the template's contents with the
  # actual values of the private key file names for the two CAs.
  CURRENT_DIR=$PWD
  cd crypto-config/peerOrganizations/amazon.upgrad-network.com/ca/ || exit
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR" || exit
  sed $OPTS "s/AMAZON_CA_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml
  cd crypto-config/peerOrganizations/flipkart.upgrad-network.com/ca/ || exit
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR" || exit
  sed $OPTS "s/FLIPKART_CA_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml
  cd crypto-config/peerOrganizations/paytm.upgrad-network.com/ca/ || exit
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR" || exit
  sed $OPTS "s/PAYTM_CA_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml
  # If MacOSX, remove the temporary backup of the docker-compose file
  if [ "$ARCH" == "Darwin" ]; then
    rm docker-compose.ymlt
  fi
}

# We will use the cryptogen tool to generate the cryptographic material (x509 certs)
# for our various network entities.  The certificates are based on a standard PKI
# implementation where validation is achieved by reaching a common trust anchor.
#
# Cryptogen consumes a file - ``crypto-config.yaml`` - that contains the network
# topology and allows us to generate a library of certificates for both the
# Organizations and the components that belong to those Organizations.  Each
# Organization is provisioned a unique root certificate (``ca-cert``), that binds
# specific components (peers and orderers) to that Org.  Transactions and communications
# within Fabric are signed by an entity's private key (``keystore``), and then verified
# by means of a public key (``signcerts``).  You will notice a "count" variable within
# this file.  We use this to specify the number of peers per Organization; in our
# case it's two peers per Org.  The rest of this template is extremely
# self-explanatory.
#
# After we run the tool, the certs will be parked in a folder titled ``crypto-config``.

# Generates Org certs using cryptogen tool
function generateCerts() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
  fi
  set -x
  cryptogen generate --config=./crypto-config.yaml
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo
}

# The `configtxgen tool is used to create four artifacts: orderer **bootstrap
# block**, fabric **channel configuration transaction**, and two **anchor
# peer transactions** - one for each Peer Org.
#
# The orderer block is the genesis block for the ordering service, and the
# channel transaction file is broadcast to the orderer at channel creation
# time.  The anchor peer transactions, as the name might suggest, specify each
# Org's anchor peer on this channel.
#
# Configtxgen consumes a file - ``configtx.yaml`` - that contains the definitions
# for the sample network. There are three members - one Orderer Org (``OrdererOrg``)
# and two Peer Orgs (``Org1`` & ``Org2``) each managing and maintaining two peer nodes.
# This file also specifies a consortium - ``SampleConsortium`` - consisting of our
# two Peer Orgs.  Pay specific attention to the "Profiles" section at the top of
# this file.  You will notice that we have two unique headers. One for the orderer genesis
# block - ``TwoOrgsOrdererGenesis`` - and one for our channel - ``TwoOrgsChannel``.
# These headers are important, as we will pass them in as arguments when we create
# our artifacts.  This file also contains two additional specifications that are worth
# noting.  Firstly, we specify the anchor peers for each Peer Org
# (``peer0.amazon.upgrad-network.com`` & ``peer0.flipkart.upgrad-network.com``).  Secondly, we point to
# the location of the MSP directory for each member, in turn allowing us to store the
# root certificates for each Org in the orderer genesis block.  This is a critical
# concept. Now any network entity communicating with the ordering service can have
# its digital signature verified.
#
# This function will generate the crypto material and our four configuration
# artifacts, and subsequently output these files into the ``config``
# folder.
#
# If you receive the following warning, it can be safely ignored:
#
# [bccsp] GetDefault -> WARN 001 Before using BCCSP, please call InitFactories(). Falling back to bootBCCSP.
#
# You can ignore the logs regarding intermediate certs, we are not using them in
# this crypto implementation.

# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  echo "CONSENSUS_TYPE="$CONSENSUS_TYPE
  set -x
  if [ "$CONSENSUS_TYPE" == "solo" ]; then
    configtxgen -profile OrdererGenesis -channelID upgrad-sys-channel -outputBlock ./channel-artifacts/genesis.block
  elif [ "$CONSENSUS_TYPE" == "kafka" ]; then
    configtxgen -profile OrdererGenesis -channelID upgrad-sys-channel -outputBlock ./channel-artifacts/genesis.block
  elif [ "$CONSENSUS_TYPE" == "etcdraft" ]; then
    configtxgen -profile OrdererGenesis -channelID upgrad-sys-channel -outputBlock ./channel-artifacts/genesis.block
  else
    set +x
    echo "unrecognized CONSESUS_TYPE='$CONSENSUS_TYPE'. exiting"
    exit 1
  fi
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  set -x
  configtxgen -profile ChannelThreeOrgs -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID "$CHANNEL_NAME"
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for AmazonMSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile ChannelThreeOrgs -outputAnchorPeersUpdate ./channel-artifacts/AmazonMSPanchors.tx -channelID "$CHANNEL_NAME" -asOrg AmazonMSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for AmazonMSP..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for FlipkartMSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile ChannelThreeOrgs -outputAnchorPeersUpdate \
    ./channel-artifacts/FlipkartMSPanchors.tx -channelID "$CHANNEL_NAME" -asOrg FlipkartMSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for FlipkartMSP..."
    exit 1
  fi
  echo

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for PayTMMSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile ChannelThreeOrgs -outputAnchorPeersUpdate \
    ./channel-artifacts/PayTMMSPanchors.tx -channelID "$CHANNEL_NAME" -asOrg PayTMMSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for PayTMMSP..."
    exit 1
  fi
  echo

}

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform, e.g., darwin-amd64 or linux-amd64
OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=15
# default for delay between commands
CLI_DELAY=5
# channel name defaults to "channelthreeorgs"
CHANNEL_NAME="channelthreeorgs"
# version for updating chaincode
VERSION_NO=1.1
# use this as the default docker-compose yaml definition
COMPOSE_FILE=docker-compose.yml
# kafka and zookeeper compose file
COMPOSE_FILE_KAFKA=docker-compose-kafka.yml
# two additional etcd/raft orderers
COMPOSE_FILE_RAFT2=docker-compose-etcdraft2.yml
#
# use golang as the default language for chaincode
LANGUAGE="node"
# default image tag
IMAGETAG="latest"
# default consensus type
CONSENSUS_TYPE="solo"
# default couch DB
IF_COUCHDB="false"
# Parse commandline args
if [ "$1" = "-m" ]; then # supports old usage, muscle memory is powerful!
  shift
fi
MODE=$1
shift
# Determine whether starting, stopping, restarting, generating or upgrading
if [ "$MODE" == "up" ]; then
  EXPMODE="Starting"
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping"
elif [ "$MODE" == "restart" ]; then
  EXPMODE="Restarting"
elif [ "$MODE" == "retry" ]; then
  EXPMODE="Retrying bootstrap"
elif [ "$MODE" == "composer" ]; then
  EXPMODE="Setting up composer"
elif [ "$MODE" == "update" ]; then
  EXPMODE="Updating chaincode"
elif [ "$MODE" == "install" ]; then
  EXPMODE="Installing chaincode"
elif [ "$MODE" == "generate" ]; then
  EXPMODE="Generating certs and genesis block"
else
  printHelp
  exit 1
fi

while getopts "h?c:t:d:f:s:l:i:o:v:" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
  c)
    CHANNEL_NAME=$OPTARG
    ;;
  t)
    CLI_TIMEOUT=$OPTARG
    ;;
  d)
    CLI_DELAY=$OPTARG
    ;;
  f)
    COMPOSE_FILE=$OPTARG
    ;;
  s)
    IF_COUCHDB=$OPTARG
    ;;
  l)
    LANGUAGE=$OPTARG
    ;;
  v)
    VERSION_NO=$OPTARG
    ;;
  i)
    IMAGETAG=$(go env GOARCH)"-"$OPTARG
    ;;
  o)
    CONSENSUS_TYPE=$OPTARG
    ;;
  esac
done

# Announce what was requested

if [ "${IF_COUCHDB}" == "couchdb" ]; then
  echo
  echo "${EXPMODE} for channel '${CHANNEL_NAME}' with CLI timeout of '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds and using database '${IF_COUCHDB}' and chaincode version '${VERSION_NO}' "
else
  echo "${EXPMODE} for channel '${CHANNEL_NAME}' with CLI timeout of '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds and chaincode version '${VERSION_NO}' "
fi
# ask for confirmation to proceed
askProceed

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  generateCerts
  replacePrivateKey
  generateChannelArtifacts
elif [ "${MODE}" == "restart" ]; then ## Restart the network
  networkDown
  networkUp
elif [ "${MODE}" == "retry" ]; then ## Retry bootstrapping the network
  bootstrapRetry
elif [ "${MODE}" == "composer" ]; then ## Run the composer setup commands
  setupComposer
elif [ "${MODE}" == "update" ]; then ## Run the composer setup commands
  updateChaincode
elif [ "${MODE}" == "install" ]; then ## Run the composer setup commands
  installChaincode
else
  printHelp
  exit 1
fi
