#!/usr/bin/env bash

# Strictly handle script failures
set -euo pipefail

# Visual logs
log_info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

# Cleanup function to kill background processes on EXIT or SIGINT
PIDS=()
cleanup() {
  log_warn "Shutting down background processes..."
  for pid in "${PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done
  log_info "Cleanup complete. Exiting."
}
trap cleanup EXIT INT TERM

# Cross-platform browser launcher
open_url() {
  local url="$1"
  if command -v xdg-open &>/dev/null; then
    xdg-open "$url" &>/dev/null &
  elif command -v open &>/dev/null; then
    open "$url" &>/dev/null &
  else
    log_warn "No supported browser launcher found. Please open: $url"
  fi
}

# Wait for a TCP port to become available
wait_for_port() {
  local port="$1"
  local timeout=30
  local count=0
  log_info "Waiting for localhost:${port} to become accessible..."
  while ! nc -z localhost "$port" &>/dev/null; do
    sleep 1
    count=$((count + 1))
    if [ "$count" -ge "$timeout" ]; then
      log_error "Timeout waiting for port ${port}!"
      exit 1
    fi
  done
}

# Check pre-flight requirements
for cmd in minikube kubectl nc; do
  if ! command -v "$cmd" &>/dev/null; then
    log_error "Required CLI tool '$cmd' is not installed or not in PATH."
    exit 1
  fi
done

# 1. Start Minikube
log_info "Starting Minikube cluster..."
minikube start

# 2. Launch Minikube Tunnel (Requires elevated permissions for route binding)
log_info "Starting Minikube Tunnel in background..."
sudo -v # Refresh sudo timestamp before backgrounding
sudo minikube tunnel > /dev/null 2>&1 &
PIDS+=($!)

# 3. Port Forward Prometheus
log_info "Setting up Prometheus port-forward (http://localhost:9090)..."
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 > /dev/null 2>&1 &
PIDS+=($!)
wait_for_port 9090

# 4. Port Forward Grafana
log_info "Setting up Grafana port-forward (http://localhost:3000)..."
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 > /dev/null 2>&1 &
PIDS+=($!)
wait_for_port 3000

# 5, 6, 7. Open Application & Observability Dashboards
log_info "Opening web interfaces..."
open_url "http://three-tier.local"
open_url "http://localhost:9090"
open_url "http://localhost:3000"

log_info "Environment is fully operational!"
log_info "Press [CTRL+C] to stop tunnels, port-forwards, and exit."

# Keep script alive to maintain background tunnels/port-forwards
wait
