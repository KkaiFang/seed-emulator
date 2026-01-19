#!/bin/bash

LOGFILE="pos_geth_sync_$(date '+%Y%m%d_%H%M%S').log"

docker ps --format '{{.Names}}' | grep POS | while IFS= read -r eth_container; do
    timestamp=$(date '+%F %T')

    result=$(docker exec "$eth_container" geth attach --exec 'eth.syncing' 2>&1)
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        line="$timestamp  ERROR on $eth_container: $result"
    else
        if [[ "$result" == "false" ]]; then
            block=$(docker exec "$eth_container" geth attach --exec 'eth.blockNumber' 2>/dev/null)
            line="$timestamp  $eth_container  SYNCED  block=$block"
        else
            current=$(echo "$result" | grep -o "currentBlock: [^,]*" | awk '{print $2}')
            highest=$(echo "$result" | grep -o "highestBlock: [^}]*" | awk '{print $2}')
            line="$timestamp  $eth_container  SYNCING  current=$current highest=$highest"
        fi
    fi

    echo "$line"
    echo "$line" >> "$LOGFILE"
done

