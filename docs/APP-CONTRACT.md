# Platform contract for containerized services

Any service deployed to the Green Pulse cluster must:

## 1. Port
Listen on a single fixed port, documented here.
- backend: 8080
- ai-service: 8001

## 2. Configuration
Read ALL config from environment variables. No .env files, no config
files baked into the image. Same image runs in every environment.

## 3. Health endpoint
## 3. Health endpoints

`GET /healthz` — liveness. Returns 200 if the process is running.
MUST NOT check databases, APIs, or any external dependency.
Cheap, no auth, no side effects.

`GET /readyz` — readiness. Returns 200 only when able to serve:
config valid, model loaded, required downstreams reachable.
Returns 503 otherwise.
The app must expose an HTTP endpoint (e.g., GET /health or GET /healthz) returning an HTTP 200 OK response. Kubernetes uses this for Liveness/Readiness probes to know when to restart or send traffic to a container.

## 4. Logging
Write to stdout/stderr only. Never to files inside the container.
The app must output logs directly to stdout / stderr (e.g., standard console.log() or print()). Kubernetes automatically captures stdout and routes it to logging tools like CloudWatch or Grafana Loki.


## 5. Shutdown
Handle SIGTERM: stop accepting new requests, finish in-flight ones, exit.

## 6. Image
Build for linux/amd64. Non-root user preferred.