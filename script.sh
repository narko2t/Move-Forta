#!/bin/bash
echo -e "\e[1m\e[32m1. Enter Forta passphrase(passwrod) \e[0m"
read -p "Forta Passphrase: " FORTA_PASSPHRASE
echo -e "\e[1m\e[32m2. Enter owner address(any metamask address that you have access to) \e[0m"
read -p "Forta Owner Address: " FORTA_OWNER_ADDRESS
echo -e "\e[1m\e[32m3. Chain id=Polygon (137)\e[0m"
read -p "Chain id: " CHAIN_ID
echo -e "\e[1m\e[32m4. Enter RPC url \e[0m"
read -p "Enter RPC url: " FORTA_RPC_URL

echo "=================================================="

echo -e "\e[1m\e[32m Forta Passphrase: \e[0m" $FORTA_PASSPHRASE
echo -e "\e[1m\e[32m Forta Owner Address:  \e[0m" $FORTA_OWNER_ADDRESS
echo -e "\e[1m\e[32m RPC url:  \e[0m" $FORTA_RPC_URL
echo -e "\e[1m\e[32m Forta Chain Id:  \e[0m" $CHAIN_ID

echo -e "\e[1m\e[32m5. Updating list of dependencies... \e[0m" && sleep 1
sudo apt-get update
cd $HOME

echo "=================================================="

echo -e "\e[1m\e[32m6. Verifying Docker version... \e[0m" && sleep 1

if [[ $(docker version -f "{{.Server.Version}}") != "20.10."* ]]; then
    echo -e "\e[1m\e[32m6.2 Updating/Installing Docker... \e[0m" && sleep 1
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    sudo apt-cache policy docker-ce
    sudo apt install docker-ce -y
    docker version -f "{{.Server.Version}}"
fi

echo "=================================================="

echo -e "\e[1m\e[32m7. Check if Docker service is active... \e[0m" && sleep 1

if [[ $(systemctl is-active docker) != "active" ]]; then
    echo -e "\e[91m Docker service is not active, please make sure that Docker is working properly and try again later. \e[0m" && sleep 1
    exit
fi

echo "=================================================="

echo -e "\e[1m\e[32m8. Install forta node... \e[0m" && sleep 1
sudo curl https://dist.forta.network/pgp.public -o /usr/share/keyrings/forta-keyring.asc -s
echo 'deb [signed-by=/usr/share/keyrings/forta-keyring.asc] https://dist.forta.network/repositories/apt stable main' | sudo tee -a /etc/apt/sources.list.d/forta.list
sudo apt-get update
sudo apt-get install forta

echo "=================================================="

echo -e "\e[1m\e[32m9. Configure forta node... \e[0m" && sleep 1
echo '{
   "default-address-pools": [
        {
            "base":"172.17.0.0/12",
            "size":16
        },
        {
            "base":"192.168.0.0/16",
            "size":20
        },
        {
            "base":"10.99.0.0/16",
            "size":24
        }
    ]
}' > /etc/docker/daemon.json
sudo systemctl restart docker
if [[ $(systemctl is-active docker) != "active" ]]; then
    echo -e "\e[91m Docker service is not active, please make sure that Docker is working properly and try again later. \e[0m" && sleep 1
    exit
fi
sudo mkdir -p /lib/systemd/system/forta.service.d

echo "[Service]
Environment='FORTA_DIR=$HOME/.forta'
Environment='FORTA_PASSPHRASE=$FORTA_PASSPHRASE'" > /lib/systemd/system/forta.service.d/env.conf

FORTA_SCANNER_ADDRESS=$(forta init --passphrase $FORTA_PASSPHRASE | awk '/Scanner address: /{print $3}') && sleep 2
if [ -z "$FORTA_SCANNER_ADDRESS" ]; then
    echo -e "\e[91m Wasn't able execute forta init, possible reason is that fora was already initiated before. \e[0m" && sleep 1
    exit
fi

sed -i 's,<required>,'$FORTA_RPC_URL',g' $HOME/.forta/config.yml
sed -i 's/chainId: .*/chainId: '$CHAIN_ID'/g' $HOME/.forta/config.yml
nano $HOME/.forta/config.yml

echo "=================================================="

echo -e "\e[1m\e[32m10. Поменяй если нужно скан адресс через файлзиллу, создай папку forta.service.d и файл в ней env.conf, запусти ноду \e[0m \n" && sleep 1

echo "=================================================="

echo -e "\e[1m\e[32m11. For starting Forta service... \e[0m" && sleep 1
echo -e "\e[1m\e[39msudo systemctl daemon-reload \n \e[0m"
echo -e "\e[1m\e[39msudo systemctl enable forta \n \e[0m"
echo -e "\e[1m\e[39msudo systemctl start forta \n \e[0m"

echo "=================================================="

echo -e "\e[1m\e[32mTo check status: \e[0m" 
echo -e "\e[1m\e[39mforta status \n \e[0m"

echo -e "\e[1m\e[32mYour scanner address: \e[0m" 
echo -e "\e[1m\e[39mforta account address \n \e[0m"

echo -e "\e[1m\e[32mYour owner address: \e[0m" 
echo -e "\e[1m\e[39m$FORTA_OWNER_ADDRESS \n \e[0m" 

echo -e "\e[1m\e[32mYour passphrase: \e[0m" 
echo -e "\e[1m\e[39m$FORTA_PASSPHRASE \n \e[0m"
