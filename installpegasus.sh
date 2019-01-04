#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='pegasus.conf'
CONFIGFOLDER='/root/.pegasus'
COIN_DAEMON='pegasusd'
COIN_CLI='pegasus-cli'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/AstaClover/peginnstall/releases/download/v.10/pegasus.tar.gz'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='pegasus'
COIN_PORT=2171
RPC_PORT=2170

NODEIP=$(curl -s4 api.ipify.org)


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


function download_node() {
  echo -e "Prepare to download ${GREEN}$COIN_NAME${NC}."
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZ
  tar xvzf $COIN_ZIP -C $COIN_PATH >/dev/null 2>&1
  compile_error
  cp $COIN_DAEMON $COIN_CLI $COIN_PATH >/dev/null 2>&1
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}


function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
User=root
Group=root
Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid
ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}


function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
EOF
}

function create_key() {
  echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
    sleep 30
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  fi
  $COIN_PATH$COIN_CLI stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=16
bind=$NODEIP
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
#Nodes
addnode=211.26.199.214
addnode=149.28.39.43
addnode=149.28.56.15
addnode=185.92.223.224
addnode=185.92.223.224
addnode=68.183.115.210
addnode=144.202.4.50
addnode=159.65.111.123
addnode=107.172.2.189
addnode=66.70.206.98
addnode=95.216.162.89
addnode=68.183.32.177
addnode=108.61.75.21
addnode=82.146.58.102
addnode=149.248.53.229
addnode=104.223.49.122:46080
addnode=104.248.244.55:49678
addnode=107.172.2.189:64242
addnode=108.160.135.165:47722
addnode=108.61.175.189:44048
addnode=108.61.75.21:50354
addnode=118.25.137.211:2171
addnode=120.105.97.51:39624
addnode=120.105.97.51:42218
addnode=120.105.97.51:43058
addnode=120.105.97.51:54084
addnode=120.105.97.51:56580
addnode=120.105.97.51:56592
addnode=128.199.207.71:39296
addnode=139.180.195.46:47858
addnode=140.143.208.254:2171
addnode=140.82.13.16:2171
addnode=142.93.243.67:58218
addnode=144.202.10.156:52980
addnode=144.202.107.244:43368
addnode=144.202.120.67:50924
addnode=144.202.120.67:56554
addnode=144.202.120.67:56614
addnode=144.202.22.119:50962
addnode=144.202.22.119:59974
addnode=144.202.22.119:59990
addnode=144.202.22.119:59992
addnode=144.202.22.119:60018
addnode=144.202.22.119:60024
addnode=144.202.25.227:39248
addnode=144.202.4.50:2171
addnode=144.202.93.53:46590
addnode=146.71.79.156:45174
addnode=149.248.53.229:59968
addnode=149.28.112.27:51050
addnode=149.28.158.248:52396
addnode=149.28.226.210:53948
addnode=149.28.39.43:35374
addnode=149.28.53.16:57116
addnode=149.28.56.15:33530
addnode=149.28.75.199:54574
addnode=155.94.181.110:58436
addnode=157.230.100.221:47254
addnode=157.230.110.123:48672
addnode=157.230.31.9:45840
addnode=157.230.96.223:55616
addnode=157.230.96.44:2171
addnode=157.230.98.160:56108
addnode=159.65.111.123:34816
addnode=159.65.111.123:38746
addnode=159.65.111.123:39608
addnode=173.249.11.55:53040
addnode=173.249.42.178:2171
addnode=173.249.51.96:45486
addnode=173.249.51.96:48900
addnode=173.249.51.96:48902
addnode=173.61.1.51:60025
addnode=185.144.158.252:59832
addnode=185.219.135.153:42428
addnode=185.243.113.53:55252
addnode=185.92.223.224:58984
addnode=193.124.131.38:55444
addnode=193.124.131.38:58294
addnode=193.124.131.38:60266
addnode=193.124.131.38:61898
addnode=194.67.194.219:2171
addnode=198.46.179.174:2171
addnode=198.46.179.174:54591
addnode=198.46.179.188:2171
addnode=198.46.179.206:53901
addnode=198.46.179.206:54231
addnode=198.46.179.206:54312
addnode=198.46.179.206:62488
addnode=199.247.1.124:2171
addnode=199.247.19.155:2171
addnode=199.247.23.68:38470
addnode=206.189.105.224:45886
addnode=206.189.22.115:41980
addnode=207.148.5.192:54560
addnode=207.180.236.184:45536
addnode=207.180.236.184:55962
addnode=207.180.247.67:38328
addnode=209.250.237.32:49314
addnode=212.154.74.91:51811
addnode=212.154.74.91:52847
addnode=212.154.74.91:56598
addnode=212.154.74.91:57366
addnode=212.154.74.91:57421
addnode=212.154.74.91:57422
addnode=212.154.74.91:57431
addnode=212.154.74.91:57721
addnode=212.154.74.91:57786
addnode=212.154.74.91:57939
addnode=212.154.74.91:60547
addnode=212.154.74.91:61843
addnode=35.190.169.19:56426
addnode=35.196.152.229:49554
addnode=35.204.138.147:38904
addnode=35.226.179.189:39050
addnode=37.235.206.128:58654
addnode=45.32.180.196:57792
addnode=45.32.213.51:37726
addnode=45.63.100.82:41364
addnode=45.63.38.221:47650
addnode=45.76.167.25:38422
addnode=45.76.173.84:39304
addnode=45.77.144.85:55234
addnode=45.77.203.157:2171
addnode=45.77.29.37:44108
addnode=45.77.88.14:60528
addnode=45.77.91.221:51864
addnode=51.38.145.138:36894
addnode=51.77.201.240:60178
addnode=51.77.202.40:55426
addnode=66.42.101.2:55756
addnode=66.42.54.121:56356
addnode=66.42.81.162:35148
addnode=66.42.81.162:37968
addnode=66.42.81.162:38084
addnode=66.42.81.162:44908
addnode=66.42.81.162:45324
addnode=66.42.81.162:50312
addnode=66.42.83.10:35030
addnode=66.42.83.10:50044
addnode=66.42.83.10:50872
addnode=66.42.83.10:60134
addnode=66.42.83.10:60954
addnode=68.183.32.177:2171
addnode=71.238.165.48:2171
addnode=80.211.2.129:41928
addnode=80.211.37.93:2171
addnode=80.240.25.63:52436
addnode=80.240.30.170:2171
addnode=81.243.160.248:56866
addnode=95.179.138.190:55884
addnode=95.179.178.69:58656
addnode=95.179.183.233:37386
addnode=95.179.193.157:33546
addnode=95.179.208.67:35118
addnode=95.216.162.89:53434
addnode=95.216.162.89:59954
EOF
}


function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}


function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 api.ipify.org))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}


function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "Preparing the system to install ${GREEN}$COIN_NAME${NC} master node."
echo -e "This might take up to 15 minutes and the screen will not move, so please be patient."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
 exit 1
fi
clear
}

function important_information() {
 echo -e "================================================================================================================================"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${RED}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "VPS_IP:PORT ${RED}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${RED}$COINKEY${NC}"
 echo -e "Please check ${RED}$COIN_NAME${NC} daemon is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "Use ${RED}$COIN_CLI masternode status${NC} to check your MN."
 if [[ -n $SENTINEL_REPO  ]]; then
  echo -e "${RED}Sentinel${NC} is installed in ${RED}$CONFIGFOLDER/sentinel${NC}"
  echo -e "Sentinel logs is: ${RED}$CONFIGFOLDER/sentinel.log${NC}"
 fi
 echo -e "================================================================================================================================"
}

function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  important_information
  configure_systemd
}


##### Main #####
clear

checks
prepare_system
download_node
setup_node
