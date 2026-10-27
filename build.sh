#!/bin/bash
# DESC: Build and push the opencode-sandbox image (Debian trixie + glibc
# opencode CLI, Node via nvm, core dev tooling, and a Homebrew seed).
# CI publishes on every merge; this script is the local/emergency path.
# Renovate pins the resulting digest in ImranR98/Infra on its daily run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
IMAGE="${IMAGE:-ghcr.io/imranr98/opencode-sandbox:latest}"

if docker info >/dev/null 2>&1; then
    ENGINE=docker
elif podman info >/dev/null 2>&1; then
    ENGINE=podman
else
    echo "Error: neither Docker nor Podman is usable" >&2
    exit 1
fi

echo "==> Building $IMAGE (linux/amd64) with $ENGINE"
"$ENGINE" build --platform linux/amd64 -t "$IMAGE" "$SCRIPT_DIR"

echo "==> Pushing $IMAGE"
if [ "$ENGINE" = podman ]; then
    # The GHCR login lives in ~/.docker/config.json; podman only reads it when
    # passed explicitly. --digestfile reports the registry manifest digest, not
    # the pre-push local RepoDigest.
    authfile="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
    push_args=()
    [ -f "$authfile" ] && push_args+=(--authfile "$authfile")
    digestfile="$(mktemp)"
    "$ENGINE" push "${push_args[@]}" --digestfile "$digestfile" "$IMAGE"
    digest="$(cat "$digestfile")"
    rm -f "$digestfile"
else
    "$ENGINE" push "$IMAGE"
    digest="$("$ENGINE" inspect --format='{{index .RepoDigests 0}}' "$IMAGE" | sed 's/^[^@]*@//')"
fi
[ -n "$digest" ] || { echo "Error: no pushed digest found for $IMAGE" >&2; exit 1; }

echo "Pushed $IMAGE@$digest"
echo "Renovate will pin this digest in ImranR98/Infra on its next daily run."
