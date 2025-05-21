#!/bin/bash

# Part 1
git clone https://github.com/gensyn-ai/rl-swarm.git /root/my_rl_swarm_47
cd /root/my_rl_swarm_47
rm -f run_rl_swarm.sh && wget -O run_rl_swarm.sh https://raw.githubusercontent.com/pulagam344/swarm/main/run_rl_swarm.sh && chmod +x run_rl_swarm.sh
wget -O modal-login/temp-data/userData.json https://raw.githubusercontent.com/pulagam344/gsyn/main/47/userData.json
wget -O modal-login/temp-data/userApiKey.json https://raw.githubusercontent.com/pulagam344/gsyn/main/47/userApiKey.json
wget -O swarm.pem https://raw.githubusercontent.com/pulagam344/gsyn/main/47/swarm.pem
wget -O hivemind_exp/configs/gpu/grpo-qwen-2.5-0.5b-deepseek-r1.yaml https://raw.githubusercontent.com/pulagam344/genconnfig/main/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
sed -i 's|3000|3001|' hivemind_exp/chain_utils.py
sed -i 's|PORT_CHANGE|3001|' run_rl_swarm.sh
sed -i 's|38330|38331|' run_rl_swarm.sh

# Part 2
git clone https://github.com/gensyn-ai/rl-swarm.git /root/my_rl_swarm_48
cd /root/my_rl_swarm_48
rm -f run_rl_swarm.sh && wget -O run_rl_swarm.sh https://raw.githubusercontent.com/pulagam344/swarm/main/run_rl_swarm.sh && chmod +x run_rl_swarm.sh
wget -O modal-login/temp-data/userData.json https://raw.githubusercontent.com/pulagam344/gsyn/main/48/userData.json
wget -O modal-login/temp-data/userApiKey.json https://raw.githubusercontent.com/pulagam344/gsyn/main/48/userApiKey.json
wget -O swarm.pem https://raw.githubusercontent.com/pulagam344/gsyn/main/48/swarm.pem
wget -O hivemind_exp/configs/gpu/grpo-qwen-2.5-0.5b-deepseek-r1.yaml https://raw.githubusercontent.com/pulagam344/genconnfig/main/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
sed -i 's|3000|3002|' hivemind_exp/chain_utils.py
sed -i 's|PORT_CHANGE|3002|' run_rl_swarm.sh
sed -i 's|38330|38332|' run_rl_swarm.sh

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
    # Check swarm_47
    if [ ! -d "/root/my_rl_swarm_47/runs/gsm8k/multinode" ]; then
      echo "[$(date +%H:%M:%S)]-[monitor] Swarm_47 stopped, restarting..."
      run_swarm "/root/my_rl_swarm_47" 0 "swarm_47" &
    fi

    # Check swarm_48
    if [ ! -d "/root/my_rl_swarm_48/runs/gsm8k/multinode" ]; then
      echo "[$(date +%H:%M:%S)]-[monitor] Swarm_48 stopped, restarting..."
      run_swarm "/root/my_rl_swarm_48" 1 "swarm_48" &
    fi

    # Wait before next check (e.g., every 15 minutes)
    sleep 900
  done
}

# Start both swarms
export CUDA_VISIBLE_DEVICES=0
run_swarm "/root/my_rl_swarm_47" 0 "swarm_47" &
sleep 30
export CUDA_VISIBLE_DEVICES=1
run_swarm "/root/my_rl_swarm_48" 1 "swarm_48" &

# Start monitoring after 15 minutes
sleep 900
monitor_swarms &

# Wait for all background processes to complete
wait
