#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

: "${IMAGE_TAG:?Set IMAGE_TAG to the immutable Lago image tag}"
: "${LAGO_TEST_DOMAIN:?Set LAGO_TEST_DOMAIN to the public Lago test domain}"
: "${LAGO_TEST_TLS_SECRET:=lago-linx-iap-test-tls}"

export LAGO_TEST_DOMAIN
export LAGO_TEST_TLS_SECRET
export API_IMAGE="lincanvas-registry.cn-hangzhou.cr.aliyuncs.com/lago-linx-iap-test/lago-api:${IMAGE_TAG}"
export FRONT_IMAGE="lincanvas-registry.cn-hangzhou.cr.aliyuncs.com/lago-linx-iap-test/lago-front:${IMAGE_TAG}"

render_apps() {
  kubectl kustomize "$SCRIPT_DIR" | envsubst
}

filter_kinds() {
  ruby -ryaml -e '
    kinds = ARGV
    YAML.load_stream(STDIN.read).compact.each do |resource|
      next unless kinds.include?(resource["kind"])
      puts YAML.dump(resource)
    end
  ' "$@"
}

case "${1:-apps}" in
  bootstrap)
    render_apps | filter_kinds Namespace ResourceQuota ConfigMap Service
    ;;
  apps)
    render_apps
    ;;
  migrate)
    envsubst < "$SCRIPT_DIR/migrate-job.yaml"
    ;;
  workloads)
    render_apps | filter_kinds Deployment PodDisruptionBudget Ingress
    ;;
  runtime)
    render_apps | filter_kinds Deployment PodDisruptionBudget
    ;;
  ingress)
    render_apps | filter_kinds Ingress
    ;;
  *)
    echo "usage: $0 [bootstrap|apps|migrate|runtime|ingress|workloads]" >&2
    exit 2
    ;;
esac
