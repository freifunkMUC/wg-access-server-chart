## Installing the Chart

To install the chart with the release name `wireguard`:

```bash
$ helm install wireguard --repo https://freifunkMUC.github.io/wg-access-server-chart/ wg-access-server
```

The command deploys wg-access-server on the Kubernetes cluster in the default configuration. The configuration section lists the parameters that can be configured during installation.

A wireguard private key needs to be set in order for the pod to start successfully. Use `wg genkey` and append `--set wireguard.config.privateKey="<wg-private-key>"` to the command above.

Per default persistence is disabled and devices will not persist. To enable persistence, set `persistence.enabled`.

Because IPv6 on Kubernetes is disabled by default in most clusters and can't be enabled on a per-pod basis, the default `values.yaml` disables it for the VPN as well. If you have a cluster with working IPv6, set `config: {}` in your `values.yaml` or specify a custom VPN-internal prefix under `config.vpn.cidrv6`.

If no admin password is set, the Chart generates a random one. You can retrieve it using `kubectl get secret ...` as prompted by helm after installing the Chart.

### Metadata & Metrics

- `config.enableMetadata`: Collect device metadata (last handshake, RX/TX). Required for "Last seen" in the web UI. Defaults to `false`.
- `config.enableDeviceMetrics`: Expose device-level Prometheus metrics on `/metrics`. Defaults to `true` and only has an effect when metadata collection is enabled.
- `config.metrics.basicAuth.username` / `config.metrics.basicAuth.passwordHash`: Protect the `/metrics` endpoint with HTTP Basic Auth (bcrypt hash). Leave empty to keep it public.

## Upgrading to 1.3.0 (wg-access-server v1.3.0)

- **Back up the database first.** The first start applies 15 schema migrations (`schema_migrations`). Once migrated, **a downgrade is refused**: v1.2.1 and older will not start on the database, so keep the backup (and for rollbacks restore it together with the older chart).
- **SQLite** (default): the `devices` table is rebuilt once on first start.
- **MySQL**: the missing unique index on `public_key` is created; if two devices share a key the server refuses to start and names the query to find them ([storage docs](https://github.com/freifunkMUC/wg-access-server/blob/v1.3.0/docs/storage.md)). `users.policies`, `users.totp_recovery` and `devices.routes` become `text`, which rewrites both tables once.
- **Replicas** on a shared database take turns migrating.
- **Everybody is signed out once**: sessions are now stored server-side.
- **Passkeys** (two-factor) are bound to `config.externalHost`. Set it to the name users type (the ingress host) before they register passkeys.
- Defaults keep the previous behaviour: `config.vpn.firewall` is `iptables`, API tokens and the device limit are off. `nftables` needs no extra capability (`NET_ADMIN` is enough). Access policies (`vpn.policies`) need `nftables`.
- `wireguard.preUp`/`postUp`/`preDown`/`postDown` are only run if the config file is writable by its owner alone; the ConfigMap mount is mode 0644, so they do not work through this chart.
- Settings not listed here (GitHub sign-in, TOTP, `policyMapping`, ...) go under `config.auth` / `secretConfig.config`, see the [auth docs](https://github.com/freifunkMUC/wg-access-server/blob/v1.3.0/docs/auth.md).

## Uninstalling the Chart

To uninstall/delete the `wireguard` deployment:

```
$ helm delete wireguard
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Example values.yaml

```
# wg-access-server config
web:
  config:
    adminUsername: "<Username for the admin user>"
    adminPassword: "<Password for the admin user>"
  service:
    type: LoadBalancer
    loadBalancerIP: "IP of the admin panel"

wireguard:
  config:
    privateKey: "<Private Key>"
  service:
    type: ClusterIP
    loadBalancerIP: "IP of the WireGuard service"

persistence:
  enabled: true
  size: "100Mi"
  accessModes:
    - ReadWriteOnce

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - vpn.example.com
  tls:
    - hosts:
        - vpn.example.com
      secretName: wg-access-server-tls
```

## All Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config | object | `{}` | inline wg-access-server config ([config.yaml](https://www.freie-netze.org/wg-access-server/2-configuration/#the-config-file-configyaml)) |
| config.enableMetadata | bool | `false` | Collect device metadata (last handshake, RX/TX). Required for "Last seen" in the web UI. |
| config.enableDeviceMetrics | bool | `true` | Expose device-level Prometheus metrics on `/metrics` (only effective when metadata is enabled). |
| config.metrics.basicAuth.username | string | `""` | Username required for accessing `/metrics`. Leave empty for no auth. |
| config.metrics.basicAuth.passwordHash | string | `""` | Bcrypt hash of the password required for `/metrics`. Must be set together with the username. |
| config.metrics.maxDeviceSeries | int | `1000` (server default) | Caps how many devices are exported as individual series on `/metrics`. Device names are user controlled, so an uncapped export lets any user inflate the scraping Prometheus' cardinality. Negative removes the cap, `0` exports aggregates only. |
| config.loglevel | string | `info` | The global log level. Note the all-lowercase key. |
| config.externalHost | string | unset | External origin of the server, e.g. `https://vpn.example.com`. Written into client config files as the `Endpoint`, so it must be reachable by clients. |
| config.trustedProxies | list | unset | Networks whose `X-Forwarded-For` is believed (e.g. the ingress controller). |
| config.maxDevicesPerUser | int | `0` | Maximum devices per user, `0` is no limit. |
| config.enableApiTokens | bool | `false` | Let users create API tokens for scripts. |
| config.apiTokenMaxLifetime | string | `0s` | Longest an API token works, e.g. `720h`. `0s` is no cap (a bare number is rejected). |
| config.httpEnabled | bool | server default `true` | Serve the web UI over plain HTTP too. If `false`, adjust the probes to HTTPS. |
| config.vpn.firewall | string | `iptables` | `iptables`, `nftables` or `none`. Access policies need `nftables`. |
| config.auth.sessionStore.maxAge | string | `720h` (server default) | Web session lifetime. |
| config.auth.sessionStore.secure | bool | `false` | Mark the session cookie `Secure` (HTTPS only). Added in wg-access-server v1.1.0. Breaks login if any user reaches the UI over plain HTTP. |
| secretConfig.config | object | `{}` | Secret config overlay merged on top of `config`. |
| secretConfig.existingSecret | string | `""` | Use an existing secret for secret config overlay. |
| secretConfig.secretRefKeys.config | string | `"secretConfig"` | Secret key containing secret config overlay content. |
| web.config.adminUsername | string | `"admin"` |  |
| web.config.adminPassword | string | `""` | If omitted a random password will be generated and stored in the secret |
| web.config.basicAuthEnabled | bool | `true` | Enable HTTP basic auth for the web UI. |
| web.config.existingSecret | string | `""` | Use an existing secret for web admin credentials. |
| web.service.annotations | object | `{}` |  |
| web.service.externalTrafficPolicy | string | `""` |  |
| web.service.type | string | `"ClusterIP"` |  |
| web.service.loadBalancerIP | string | `""` |  |
| wireguard.config.privateKey | string | `""` | REQUIRED - A wireguard private key. You can generate one using `$ wg genkey` |
| wireguard.config.existingSecret | string | `""` | Use an existing secret for the WireGuard private key. |
| wireguard.service.annotations | object | `{}` |  |
| wireguard.service.type | string | `"ClusterIP"` |  |
| wireguard.service.sessionAffinity | string | `"ClientIP"` |  |
| wireguard.service.externalTrafficPolicy | string | `""` |  |
| wireguard.service.ipFamilyPolicy | string | `"SingleStack"` |  |
| wireguard.service.loadBalancerIP | string | `""` |  |
| wireguard.service.port | int | `51820` |  |
| wireguard.service.nodePort | int | `""` | Use available port from range 30000-32768 |
| storage.enabled | bool | `false` |  |
| storage.uri | string | `""` | A storage backend connection string |
| storage.existingSecret | string | `""` | Use existing storage secret |
| storage.secretRefKeys.uri | string | `"storageUri"` | Secret key name containing storage uri |
| persistence.enabled | bool | `false` |  |
| persistence.existingClaim | string | `""` | Use existing PVC claim for persistence instead |
| persistence.annotations | object | `{}` |  |
| persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| persistence.storageClass | string | `""` |  |
| persistence.size | string | `"100Mi"` |  |
| ingress.enabled | bool | `false` |  |
| ingress.annotations | object | `{}` |  |
| ingress.ingressClassName | string | `""` |  |
| ingress.hosts | list | `[]` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` |  |
| fullnameOverride | string | `""` |  |
| kubeTargetVersionOverride | string | `""` | Override Kubernetes target version for ingress API selection logic. |
| hostNetwork | bool | `false` | Use host networking for the pod. |
| imagePullSecrets | list | `[]` |  |
| image.repository | string | `"ghcr.io/freifunkmuc/wg-access-server"` |  |
| image.tag | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| replicas | int | `1` | More than one replica needs the Postgres storage backend. With pgbouncer in front of Postgres, use session pooling mode. |
| strategy.type | string | `""` | `Recreate` if `persistence.enabled` true or `RollingUpdate` if false |
| podLabels | object | `{}` | Extra labels merged into the pod template, alongside the chart's own selector labels. |
| podAnnotations | object | `{}` | Extra annotations merged into the pod template, alongside the chart's own checksum annotations. |
| resources | object | `{}` | pod cpu/memory resource requests and limits |
| nodeSelector | object | `{}` |  |
| tolerations | list | `[]` |  |
| affinity | object | `{}` |  |
