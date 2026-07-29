# Linx Apple IAP Lago test overlay

This overlay deploys an isolated Lago test environment for the paid voice clone
Apple IAP flow.

## Isolation boundary

- Namespace: `lago-linx-iap-test`
- PostgreSQL database and account: create dedicated test resources
- Redis: create a dedicated test instance
- ACR namespace: `lago-linx-iap-test`
- API repository: `lago-linx-iap-test/lago-api`
- Front repository: `lago-linx-iap-test/lago-front`
- TLS Secret: configured with `LAGO_TEST_TLS_SECRET`

Do not reuse the `lago-zhuyi` database, Redis, runtime Secrets, or Namespace.

## Required variables

```bash
export IMAGE_TAG=<immutable-git-sha>
export LAGO_TEST_DOMAIN=<lago-test-domain>
export LAGO_TEST_TLS_SECRET=<tls-secret-name>
```

`LAGO_TEST_TLS_SECRET` defaults to `lago-linx-iap-test-tls`.

## Required Secrets

Create these Secrets in `lago-linx-iap-test` before deploying workloads:

- `lago-runtime`
- `lago-connections`
- `lago-apple-root-ca`
- the TLS Secret named by `LAGO_TEST_TLS_SECRET`

`lago-runtime` contains the Lago encryption keys, `SECRET_KEY_BASE`,
`LAGO_RSA_PRIVATE_KEY`, and object-storage credentials. `lago-connections`
contains the dedicated `DATABASE_URL` and `REDIS_URL`.

Create the pinned Apple Root CA Secret from a reviewed local certificate file:

```bash
kubectl create secret generic lago-apple-root-ca \
  --namespace lago-linx-iap-test \
  --from-file=apple-root-ca-g3.pem=/secure/path/apple-root-ca-g3.pem \
  --dry-run=client -o yaml | kubectl apply -f -
```

Never commit Apple API private keys or Lago runtime private keys to this
overlay.

## Render

Render commands only print YAML:

```bash
deploy/overlays/linx-iap-test/render.sh bootstrap
deploy/overlays/linx-iap-test/render.sh migrate
deploy/overlays/linx-iap-test/render.sh runtime
deploy/overlays/linx-iap-test/render.sh ingress
deploy/overlays/linx-iap-test/render.sh apps
```

## Release order

1. Create the dedicated PostgreSQL database/account and Redis instance.
2. Apply `bootstrap`.
3. Create `lago-runtime`, `lago-connections`, and `lago-apple-root-ca`.
4. Apply the unique migration Job and wait for `Complete`.
5. Apply `runtime` and verify `/health` and `/ready` inside the cluster.
6. Create the TLS Secret and apply `ingress`.
7. Configure DNS and verify external HTTPS.
8. Initialize the Lago organization, API key, Apple IAP provider, and backend
   webhook endpoint.
