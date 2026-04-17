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
| replicas | int | `1` |  |
| strategy.type | string | `""` | `Recreate` if `persistence.enabled` true or `RollingUpdate` if false |
| resources | object | `{}` | pod cpu/memory resource requests and limits |
| nodeSelector | object | `{}` |  |
| tolerations | list | `[]` |  |
| affinity | object | `{}` |  |
