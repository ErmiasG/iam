# IAM authentication test fixture

LDAP-backed MIT Kerberos and Keycloak OIDC providers for Hopsworks integration
tests. **Test clusters only:** defaults contain public fixture credentials and
use plaintext LDAP/HTTP and Keycloak development mode.

## Deploy for Hopsworks

Requires Helm 3, kubectl, jq, and a configured Kubernetes context. Build/push
the changed Docker images first using each Dockerfile's directory as its build
context; use a new tag and override both chart image tags when deploying.
The Kerberos build depends on the LDAP image of the same VERSION.
Images are published under `docker.hops.works/dev/ermias/iam/` with names
`ldap`, `kerberos`, and `keycloak`; `global.image.repository` sets this shared
prefix for the umbrella chart.

```bash
bash scripts/deploy.sh -f helm/values.hopsworks-it.yaml \
  --set kerberos.image.tag=YOUR_TAG --set oauth.image.tag=YOUR_TAG
kubectl create namespace hopsworks --dry-run=client -o yaml | kubectl apply -f -
bash scripts/sync-hopsworks-auth.sh
```

Then install Hopsworks using its `values.iam.yaml` in namespace `hopsworks`.
This repository's `helm/values.hopsworks-it.yaml` is an **IAM chart overlay**,
not a replacement for the Hopsworks chart's values file.

Default IAM namespace/release: `iam`/`iam`. Override with `NAMESPACE`/`RELEASE`.
The sync script uses `IAM_NAMESPACE` and `HOPSWORKS_NAMESPACE`. Its operator
needs get access to source Secrets/ConfigMaps and create/patch access in the
target namespace; the IAM Pod itself has no cross-namespace permissions.

The overlay matches the local Hopsworks IAM settings: issuer
`http://keycloak.iam.svc.cluster.local:8080/realms/hopsworks`, clients
`hopsworks-app` and `hopsworks-app0`, LDAP base `dc=hopsworks,dc=ai`, and principal
`HTTP/hopsworks-release.hopsworks.svc.cluster.local@HOPSWORKS.AI`.
Adjust `global.serverName`, `global.serverNamespace`, and both client redirect
URIs if the Hopsworks hostname differs. Keep one replica per provider and
persistence disabled. Re-sync credentials and restart Hopsworks after IAM
recreation because the keytabs change.

## Smoke checks

```bash
helm test iam --namespace iam
bash scripts/test-oauth.sh -i hopsworks-app -u admin@hopsworks.ai -p adminpw
bash scripts/test-oauth.sh -i hopsworks-app -u alice@hopsworks.ai -p aliceoauth
kubectl --namespace iam exec deployment/kerberos -c kdc -- \
  kadmin.local -q 'getprinc HTTP/hopsworks-release.hopsworks.svc.cluster.local@HOPSWORKS.AI'
```

Run the OAuth script from a host with cluster DNS/network access; set
`KEYCLOAK_URL` to a reachable issuer if necessary. Password grant is explicitly
enabled in the test overlay; it is not a browser authorization-code test.
Inspect the exported service keytab with `klist -k` and use `kinit`/`kvno` with
the generated `server-krb5-config` to verify ticket issuance.

See `REVIEW.md` for the complete findings, remaining risks, and validation
limits. No changes are committed automatically.
