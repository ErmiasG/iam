# IAM repository review

Reviewed 2026-10-01 for the local `/home/ermias/Downloads/values.iam.yaml`.
Scope: tracked Dockerfiles, shell/Expect scripts, LDAP and Keycloak fixtures,
Helm charts/templates, Jenkins build manifest, and deployment/smoke-test scripts.
The existing untracked `scripts/test-oauth1.sh` and ignored local artifacts were
left untouched. No cluster or image-build integration test has been run.

## Integration contract

IAM runs in namespace `iam`; Hopsworks runs in `hopsworks`.

| Requirement | IAM artifact/configuration |
| --- | --- |
| LDAP endpoint | `kerberos-ldap.iam.svc.cluster.local:389` |
| LDAP bind | `cn=admin,dc=hopsworks,dc=ai`, password `adminpw` |
| OAuth issuer | `http://keycloak.iam.svc.cluster.local:8080/realms/hopsworks` |
| OAuth clients | `hopsworks-app`, `hopsworks-app0` |
| Client secret | `hopsworks-app-client-secret`, keys matching both client IDs |
| LDAP secret | `ldap-credentials-secret`, key `credentials` |
| Kerberos realm | `HOPSWORKS.AI` |
| HTTP principal | `HTTP/hopsworks-release.hopsworks.svc.cluster.local@HOPSWORKS.AI` |
| Keytab | `keytab-secret`, key `service.keytab` |
| Client Kerberos configuration | `server-krb5-config`, key `krb5.conf` |

Kubernetes Secrets and ConfigMaps cannot be mounted across namespaces. The
sync script copies only the four required resources into Hopsworks' namespace.
It excludes the administrative keytab from the exported keytab Secret.
Run it before installing Hopsworks and again whenever IAM is recreated: the
ephemeral KDC generates new keys. Restart Hopsworks after keytab replacement
so its authentication service reloads the credentials.

## Findings addressed on the improvement branch

| Severity | Finding | Change |
| --- | --- | --- |
| High | HTTP service principal used the IAM namespace; default server name was missing | Explicit Hopsworks server name/namespace and matching integration overlay |
| High | Required Hopsworks credential Secrets were absent | Parent chart creates LDAP/client Secrets; explicit cross-namespace sync |
| High | LDAP-backed realm was followed by a second database creation based on a nonexistent file-backed database | Removed redundant `init-db` container |
| High | Init shells could hide failed LDAP/Kerberos initialization | Fail-fast shell execution for user provisioning and keytab publication |
| High | Keytab Secret was deleted before recreation and errors were ignored | Dry-run generation followed by apply; no deletion gap |
| High | KDC argument `-w 2` was passed as one argument | Separate `-w` and `2` arguments |
| High | Cluster-wide credentials and infrastructure access | Namespace Role; create Secrets, get/patch only the configured keytab Secret |
| High | Keycloak bootstrap used fixed sleeps and could report success despite configuration errors | Bounded discovery polling, strict configuration script, process cleanup, successful-bootstrap marker |
| High | OAuth smoke test printed credentials, ignored supplied user/password, and shared token files | Private temporary directory, cleanup, URL-encoded inputs, HTTP and JSON checks |
| Medium | Deployment script applied parent values directly to subcharts and used developer-specific paths | Portable umbrella-chart deployment with wait and caller-supplied overrides |
| Medium | Default image paths/tags differed from build-manifest names/version | Aligned parent image prefix, Kerberos suffix, and tags to the current 0.2.0 build |
| Medium | KDC configuration advertised obsolete ciphers | AES-only supported principal encryption types |
| Medium | Ingress rewrite could collapse OIDC endpoint paths | Removed default rewrite annotation; integration overlay uses cluster DNS |
| Medium | Helm OAuth test used a deployment name rather than the Service | Discovery request through the configured Service |
| Medium | Bare group names expected by Hopsworks conflicted with full-path group claims | Group mapper emits bare names |
| Medium | Globally named PriorityClasses caused cross-release conflicts and required cluster permissions | Optional preexisting priority class rather than creating cluster-scoped objects |
| Medium | Rolling replacement could overlap independent KDCs | Recreate deployment strategy and TCP startup/readiness probes |
| Low | Empty JSON templates failed subchart lint | Removed empty template placeholders |
| Low | LDAP password expansion and missing-file handling were unsafe | Quoted password arguments and fail-fast missing-file handling |
| High | Generated SSHA hashes containing `/` broke LDAP password substitution | Used a delimiter outside the hash alphabet |
| High | Retried LDAP fixture import stopped at the first existing OU or user | Import individual LDIF entries in order; skip only LDAP result 68 and fail on other errors |
| High | Autogroup adds `member` to ITpeople, but `groupOfURLs` does not permit that attribute | Added the `extensibleObject` auxiliary class to this test fixture so computed members are schema-valid |

## Remaining risks and follow-up work

1. **High: test-only trust model.** Known passwords/client secrets are in values
   and ConfigMaps; LDAP/OIDC use plaintext HTTP and Keycloak `start-dev` embeds
   a local database. Restrict this installation to isolated test clusters. Do
   not expose it publicly or reuse credentials elsewhere. Production requires
   TLS, externally managed Secrets, database storage, and Keycloak production
   configuration. The Kerberos account uses LDAP administrator privileges.
2. **High: restart/persistence semantics.** LDAP reconfiguration, realm creation,
   and principal creation are not reconciliations. LDAP fixture import skips
   existing entries without changing their attributes. A retry after partial LDAP
   bootstrap or reusing persistent LDAP data may fail or mutate existing data.
   Persistence values reference PVCs but the chart does not provision them.
   Keep persistence disabled; recreate a failed test deployment deliberately.
   The Keycloak marker skips successful bootstrap on init restart, but cannot
   recover a partial realm creation. A fresh Pod resets its emptyDir data.
3. **High: singleton requirement.** Multiple replicas produce unrelated
   databases and race to publish the same keytab. Keep both replica counts at
   one and OAuth autoscaling disabled. No HPA template exists despite values.
4. **Medium: hostname coupling.** The overlay assumes an HTTPS Hopsworks URL
   using `hopsworks-release.hopsworks.svc.cluster.local`. A browser-visible
   hostname must resolve from both the browser and Hopsworks. Adjust redirect
   URIs and add the corresponding HTTP service principal/keytab entries for a
   different external hostname. Port-forwarding does not automatically rewrite
   discovery endpoints or the issuer. Kerberos authentication also requires
   synchronized clocks, reachable KDC TCP/UDP ports, and a valid browser TGT.
5. **Medium: build reproducibility/supply chain.** Ubuntu packages and kubectl
   are unpinned; LDAP's kubectl download is amd64-only and lacks checksum
   verification. Keycloak 26.0.7 has not been assessed for current security
   support. Version/image naming is duplicated across Jenkins, Docker, and
   Helm. Rebuild changed images under a new immutable tag and override chart
   tags; existing registry images do not include these fixes. The Jenkins
   shared builder must provide each Dockerfile's directory as build context
   for relative COPY paths; its implementation is outside this repository.
6. **Medium: fixture limitations.** `addprinc.sh` parses only simple unwrapped
   LDIF; base64 fields, colons/whitespace in values, and escaped principal
   characters are not supported. Retain the checked-in test fixtures only.
   LDAP group filter `objectCategory=group` in the supplied Hopsworks values
   targets AD rather than these OpenLDAP group classes; test explicit group
   lookup separately before enabling group synchronization. `jdoe` has
   unverified email and should fail Hopsworks' verify-email policy.
7. **Medium: real login coverage.** Password-grant smoke tests do not verify
   authorization-code redirects, session logout, Hopsworks role provisioning,
   LDAP principal searches, or browser SPNEGO. Run Hopsworks integration tests
   with the supplied values and exercise all these flows before declaring the
   fixture compatible end to end. Direct grants are enabled only in the test
   overlay; leave them disabled for normal authorization-code clients.
8. **Low: chart hygiene.** Static Service/ConfigMap names are intentional for
   the supplied Hopsworks contract but permit only one IAM release per
   namespace. Unused LDAP standalone and persistence/autoscaling options need
   schemas or removal. Legacy `init_db.sh` remains unused; it contains an
   unbounded Expect wait. There is no automated test suite/CI chart validation.

## Validation

Local validation includes Helm lint for all charts, rendering parent and
standalone charts, YAML parsing and embedded JSON parsing, shell syntax checks,
and diff whitespace checks. These establish configuration consistency, not
runtime compatibility. No cluster resources were modified during review.
