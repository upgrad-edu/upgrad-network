#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Upgrad Network - Updating Chaincode"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
VERSION="$4"
: ${CHANNEL_NAME:="channelthreeorgs"}
: ${DELAY:="5"}
: ${LANGUAGE:="node"}
: ${VERSION:=1.1}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
ORGS="amazon flipkart paytm"

CC_SRC_PATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/"

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

## Install new version of chaincode on peer0 of all 5 orgs making them endorsers
echo "Updating chaincode on peer0.amazon.upgrad-network.com ..."
installChaincode 0 'amazon' $VERSION
echo "Updating chaincode on peer0.flipkart.upgrad-network.com ..."
installChaincode 0 'flipkart' $VERSION
echo "Updating chaincode on peer0.paytm.upgrad-network.com ..."
installChaincode 0 'paytm' $VERSION

# Upgrade chaincode on the channel using peer0.amazon
echo "Upgrading chaincode on channel using peer0.amazon.upgrad-network.com ..."
upgradeChaincode 0 'amazon' $VERSION

echo
echo "========= All GOOD, Upgrad Network Chaincode Update completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
