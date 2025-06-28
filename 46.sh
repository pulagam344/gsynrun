#!/bin/bash

sudo apt-get update
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v
sudo npm install -g yarn
yarn -v
pip install git+https://github.com/huggingface/trl.git@main
pip install wandb==0.15.12
export HYDRA_FULL_ERROR=1

# Part 1
git clone https://github.com/gensyn-ai/rl-swarm.git /root/my_rl_swarm_91
cd /root/my_rl_swarm_91
rm -f run_rl_swarm.sh && wget -O run_rl_swarm.sh https://raw.githubusercontent.com/pulagam344/gsyn_runsh/main/run_rl_swarm.sh && chmod +x run_rl_swarm.sh
wget -O modal-login/temp-data/userData.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/91/userData.json
wget -O modal-login/temp-data/userApiKey.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/91/userApiKey.json
wget -O swarm.pem https://raw.githubusercontent.com/pulagam344/swarm_peers/main/91/swarm.pem
mkdir -p configs
wget -O configs/rg-swarm.yaml https://raw.githubusercontent.com/pulagam344/gsyn_connfig/main/rg-swarm.yaml
sed -i 's|3000|3001|' hivemind_exp/chain_utils.py
sed -i 's|REPLACE|3001|' run_rl_swarm.sh
sed -i 's|REPLACE|3001|' configs/rg-swarm.yaml

# Part 2
git clone https://github.com/gensyn-ai/rl-swarm.git /root/my_rl_swarm_92
cd /root/my_rl_swarm_92
rm -f run_rl_swarm.sh && wget -O run_rl_swarm.sh https://raw.githubusercontent.com/pulagam344/gsyn_runsh/main/run_rl_swarm.sh && chmod +x run_rl_swarm.sh
wget -O modal-login/temp-data/userData.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/92/userData.json
wget -O modal-login/temp-data/userApiKey.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/92/userApiKey.json
wget -O swarm.pem https://raw.githubusercontent.com/pulagam344/swarm_peers/main/92/swarm.pem
mkdir -p configs
wget -O configs/rg-swarm.yaml https://raw.githubusercontent.com/pulagam344/gsyn_connfig/main/rg-swarm.yaml
sed -i 's|3000|3002|' hivemind_exp/chain_utils.py
sed -i 's|REPLACE|3002|' run_rl_swarm.sh
sed -i 's|REPLACE|3002|' configs/rg-swarm.yaml

git config --global credential.helper store
export PYTORCH_CUDA_ALLOC_CONF='expandable_segments:True'


# Function to run a swarm with logging
run_swarm() {
  local dir=$1
  local cuda_device=$2
  local swarm_name=$3
  export CUDA_VISIBLE_DEVICES=$cuda_device
  (
    cd "$dir" && ./run_rl_swarm.sh 2>&1 |
    while IFS= read -r line; do
      echo "[$(date +%H:%M:%S)]-[$swarm_name] $line"
    done
  )
}

# Function to monitor and restart swarms
monitor_swarms() {
  while true; do
    # Check swarm_91
    if [ ! -f "/root/my_rl_swarm_91/logs/system_info.txt" ]; then
      echo "[$(date +%H:%M:%S)]-[monitor] Swarm_91 stopped, restarting..."
      run_swarm "/root/my_rl_swarm_91" 0 "swarm_91" &
    fi

    # Check swarm_92
    if [ ! -f "/root/my_rl_swarm_92/logs/system_info.txt" ]; then
      echo "[$(date +%H:%M:%S)]-[monitor] Swarm_92 stopped, restarting..."
      run_swarm "/root/my_rl_swarm_92" 1 "swarm_92" &
    fi

    # Wait before next check (e.g., every 15 minutes)
    sleep 900
  done
}

# Start both swarms
export CUDA_VISIBLE_DEVICES=0
run_swarm "/root/my_rl_swarm_91" 0 "swarm_91" &
sleep 600
export CUDA_VISIBLE_DEVICES=1
run_swarm "/root/my_rl_swarm_92" 1 "swarm_92" &

# Start monitoring after 15 minutes
sleep 900
monitor_swarms &

# Wait for all background processes to complete
wait
