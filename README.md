# opencode-sandbox

Sandboxed dev-environment image for the in-cluster
[opencode](https://opencode.ai) agent in `ImranR98/Infra`.

The upstream opencode image is Alpine/musl; Homebrew on Linux needs glibc, so
this image is Debian trixie with the glibc opencode CLI build. It bakes in
Homebrew, nvm and a Node LTS seed; the entrypoint copies them onto the
PVC-backed tools volume on first start. The agent runs as UID/GID 1000 with
only its home PVC, the tools PVC and the sandbox share mounted.

Image: `ghcr.io/imranr98/opencode-sandbox:latest` (digest-pinned in Infra).

CI: `test` builds and verifies the image on every PR; `publish` on `main`
pushes `:sha-<commit>`, verifies that digest, then promotes `:latest`.
Renovate updates the Docker base and the `OPENCODE_VERSION` / `NODE_VERSION` /
`NVM_VERSION` ARGs, automerging after `test`.

Local build (emergency path): `./build.sh`.
