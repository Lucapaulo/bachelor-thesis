#!/bin/bash

# Part -1: Make sure hardware virtualization is enabled.
echo "------WARNING------"
echo "If you haven't enabled hardware virtualization and given this VM at least two cores to work on, stop the script now and fix that!"
sleep 5s

# Part 0: Get Mahimahi set up.
sudo sysctl -w net.ipv4.ip_forward=1

# Part I: Set up temp directories
TMP_DIR="/tmp/quic-exp"
mkdir $TMP_DIR &> /dev/null
rm -rf $TMP_DIR/* &> /dev/null
pkill -f python &> /dev/null
pkill -f httpsserver.sh &> /dev/null
pkill -f quic_server &> /dev/null

# Non-temporary data directories.
SCRIPTS_DIR=~/CS244-16-Reproducing-QUIC/experiment_scripts
GRAPHS_DIR=~/CS244-16-Reproducing-QUIC/graphs
TRACE_DIR=~/CS244-16-Reproducing-QUIC/traces
mkdir $GRAPHS_DIR &> /dev/null

# Graphs from the thesis
DELAYS=(  10 100 200 )
BANDWIDTHS=( 1 10 100 )

LOSS_RATES=( 0.0 0.0025 0.005 0.0075 0.010 0.0125 0.015 0.0175 0.020 0.0225 0.025 0.0275 0.030 0.0325 0.035 0.0375 0.040 )

for DELAY in "${DELAYS[@]}"
do

echo "----------Running with delay $DELAY----------"

for BANDWIDTH in "${BANDWIDTHS[@]}"
do 
    echo -e "Running with bandwidth $BANDWIDTH"

    cd ~/tlslite-ng/tests
    ./httpsserver.sh &> /dev/null &
    sleep 5s # give enough time for server to set up
    echo -e "HTTPS server running."

    HOST_IP=$(echo `hostname -I`)
    export HOST_IP
    MM_CMD="mm-link $TRACE_DIR/${BANDWIDTH}mb.trace $TRACE_DIR/${BANDWIDTH}mb.trace mm-delay $DELAY mm-loss downlink"

    for LOSS in "${LOSS_RATES[@]}"
    do
	echo -e "\tRunning TCP client with loss rate $LOSS"
	$MM_CMD $LOSS -- time -v -o $TMP_DIR/tcp_${DELAY}_${BANDWIDTH}_${LOSS}.out ./httpsclient.py &> /dev/null
    done

    grep -i "elapsed" $TMP_DIR/tcp_${DELAY}_${BANDWIDTH}* > $TMP_DIR/tcp_loss_${DELAY}_${BANDWIDTH}_aggregate.txt

    # Clean up
    rm index.html.* &> /dev/null
    pkill -f httpsserver.sh &> /dev/null

    # Part II: Set up the quic server and fetch from the quic client
    cd ~/chromium/src
    ./out/Debug/quic_server \
	--quic_in_memory_cache_dir=/home/user/quic-data/www.example.org \
	--certificate_file=net/tools/quic/certs/out/leaf_cert.pem \
	--key_file=net/tools/quic/certs/out/leaf_cert.pkcs8 &> /dev/null &
    sleep 5s # give enough time for server to set up
    echo -e "\nQUIC server running."

    for LOSS in "${LOSS_RATES[@]}"
    do
	echo -e "\tRunning QUIC client with loss rate $LOSS"
	$MM_CMD $LOSS -- time -v -o $TMP_DIR/quic_${DELAY}_${BANDWIDTH}_${LOSS}.out ./out/Debug/quic_client  --host=100.64.0.1 --port=6121 https://www.example.org/index.html &> /dev/null
    done

    grep -i "elapsed" $TMP_DIR/quic_${DELAY}_${BANDWIDTH}* > $TMP_DIR/quic_loss_${DELAY}_${BANDWIDTH}_aggregate.txt

    pkill -f quic_server &> /dev/null

    cd $GRAPHS_DIR
    FILE_SIZE=`wc -c ~/quic-data/www.example.org/index.html  | head -n1 | cut -d " " -f1`
    python $SCRIPTS_DIR/generate_graphs.py $TMP_DIR/tcp_loss_${DELAY}_${BANDWIDTH}_aggregate.txt $TMP_DIR/quic_loss_${DELAY}_${BANDWIDTH}_aggregate.txt $FILE_SIZE $BANDWIDTH $DELAY

done
done
