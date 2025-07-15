#!/bin/bash

export HYDRA_FULL_ERROR=1
export PYTORCH_CUDA_ALLOC_CONF='expandable_segments:True'
git config --global credential.helper store

# === Setup All 10 Swarms ===
for i in {1..10}; do
  port=$((3000 + i))
  swarm_dir="/root/my_rl_swarm_${i}"

  echo "[$(date +%H:%M:%S)]-[setup] Setting up swarm $i at port $port..."

  # Clone repo
  git clone https://github.com/gensyn-ai/rl-swarm.git "$swarm_dir" || continue
  cd "$swarm_dir" || continue

  # Get latest run script
  rm -f run_rl_swarm.sh
  wget -q -O run_rl_swarm.sh https://raw.githubusercontent.com/pulagam344/gsyn_runsh/main/run_rl_swarm.sh
  chmod +x run_rl_swarm.sh

  # Download credentials
  mkdir -p modal-login/temp-data
  wget -q -O modal-login/temp-data/userData.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/1/userData.json
  wget -q -O modal-login/temp-data/userApiKey.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/1/userApiKey.json

  # Patch config files with correct port
  sed -i "s|3000|$port|" hivemind_exp/chain_utils.py
  sed -i "s|REPLACE|$port|" run_rl_swarm.sh
  sed -i "s|3000|$port|" rgym_exp/config/rg-swarm.yaml
done

# === Run a swarm with logging ===
run_swarm() {
  local dir=$1
  local swarm_name=$2
  (
    cd "$dir" && ./run_rl_swarm.sh 2>&1 |
    while IFS= read -r line; do
      echo "[$(date +%H:%M:%S)]-[$swarm_name] $line"
    done
  )
}

# === Monitor and Restart Swarms if Needed ===
monitor_swarms() {
  while true; do
    for i in {1..10}; do
      port=$((3000 + i))
      if [ ! -f "/root/running_${port}.txt" ]; then
        echo "[$(date +%H:%M:%S)]-[monitor] Swarm_${i} stopped, restarting..."
        run_swarm "/root/my_rl_swarm_${i}" "swarm_${i}" &
      fi
    done
    sleep 60
  done
}

# === Start All Swarms ===
for i in {1..10}; do
  run_swarm "/root/my_rl_swarm_${i}" "swarm_${i}" &
  sleep 5  # Prevent simultaneous GPU overload
done

# === Start Monitoring After Initial Boot ===
sleep 60
monitor_swarms &

# === Wait for all background jobs ===
wait
