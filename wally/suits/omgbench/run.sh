#!/bin/bash

while [[ $# > 1 ]]
do
key="$1"

case $key in
    url)
    URL="$2"
    shift
    ;;
    timeout)
    TIMEOUT="$2"
    shift
    ;;
    clients)
    CLIENTS="$2"
    shift
    ;;
    servers)
    SERVERS="$2"
    shift
    ;;
    num_topics)
    NUM_TOPICS="$2"
    shift
    ;;
    start_broker)
    START_BROKER="$2"
    shift
    ;;
    zmq_host)
    ZMQ_HOST="$2"
    shift
    ;;
    zmq_password)
    ZMQ_PASS="$2"
    shift
    ;;
    zmq_port)
    ZMQ_PORT="$2"
    shift
    ;;
    *)
    echo "Unknown option $key"
    exit 1
    ;;
esac
shift
done


OMGPATH=/tmp
mkdir -p "/tmp/testlogs"
SERVER_LOG_FILE=/tmp/testlogs/server-
CLIENT_LOG_FILE=/tmp/testlogs/client

cd "$OMGPATH/oslo.messaging/tools"
source "$OMGPATH/venv/bin/activate"

if [[ "$START_BROKER" ]]
then
    cat > ${OMGPATH}/zmq.conf <<EOF
[DEFAULT]
transport_url=${URL}
rpc_zmq_matchmaker=redis
[matchmaker_redis]
port=${ZMQ_PORT:-6379}
host=${ZMQ_HOST:-localhost}
password=${ZMQ_PASS:-''}
EOF
    oslo-messaging-zmq-broker --config-file "${OMGPATH}/zmq.conf" &> /dev/null &
    CONF_FILE_OPT="--config-file ${OMGPATH}/zmq.conf"
fi

topics=`python -c "import petname; print ' '.join([petname.Generate(3, '_') for i in range($NUM_TOPICS)])"`
topics_arr=($topics)

for i in `seq "$SERVERS"`;
 do
 python simulator.py $CONF_FILE_OPT --url "$URL" -tp "${topics_arr[$((i % NUM_TOPICS))]}" -l $((TIMEOUT + 5)) rpc-server &> "$SERVER_LOG_FILE$i" &
 done

python simulator.py $CONF_FILE_OPT  -l "$TIMEOUT" -tp $topics --url "$URL" rpc-client -p "$CLIENTS" -m 100 &> "$CLIENT_LOG_FILE" &

while [ "$(ps aux | grep simulator.py | grep -v grep)" ]
do
sleep 1
done

# grep total sent

cat /tmp/testlogs/client | grep "messages were sent" |  grep -o '[0-9,.]\+' | head -2

# grep total received
for i in `seq "$SERVERS"`;
 do
 cat "$SERVER_LOG_FILE$i" | grep "Received total" | grep -o '[0-9,.]\+';
 done

for p in `ps aux | grep zmq-broker | grep -v grep | awk '{print $2}'`;
do
kill "$p"
done