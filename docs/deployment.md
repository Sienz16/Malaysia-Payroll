# Deployment

Production runs behind a TLS reverse proxy. The proxy is the only public listener on ports 80 and 443. Bandit binds to `127.0.0.1`; do not expose its port through a firewall, load balancer, or container mapping.

The proxy must terminate TLS and set `X-Forwarded-Proto: https`. `force_ssl` relies on that header, so direct client access to Bandit is forbidden. Do not trust or forward client-supplied `X-Forwarded-For` into the application; IP rate limiting uses the proxy connection address until a verified client-IP propagation design exists.

## Release

Required environment:

```text
SECRET_KEY_BASE=<mix phx.gen.secret output>
PHX_HOST=payroll.dpnc.my
PHX_SERVER=true
```

Optional environment: `PORT` (default `4000`), `DNS_CLUSTER_QUERY`, and `PAYROLL_RATE_LIMIT` (default `1000` requests per rolling 30 days per observed IP).

Build and start:

```bash
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release
PHX_SERVER=true SECRET_KEY_BASE=... PHX_HOST=payroll.dpnc.my _build/prod/rel/payroll_api/bin/payroll_api start
```

Probe through proxy after deploy:

```bash
curl --fail https://payroll.dpnc.my/api/v1/health
curl --fail https://payroll.dpnc.my/api/v1/ready
```

Verify staging before each infrastructure change: HTTP redirects once to HTTPS, HSTS is present, and Bandit port is unreachable outside proxy host. Roll back by stopping current release, starting prior release with same environment, then re-running both probes.
