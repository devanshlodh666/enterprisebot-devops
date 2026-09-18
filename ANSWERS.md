# Answers

## Q1. Ingress-NGINX to Gateway API migration

- **1. First, understand what is running:** I would start by checking all ~40 Ingress objects and documenting their hosts, paths, TLS, annotations, rewrites, authentication, and any NGINX-specific settings. This helps identify anything that may not map cleanly to Gateway API.

- **2. Set up Gateway API without touching production traffic:** I would install the Gateway API resources and a supported Gateway API implementation alongside the existing ingress-nginx setup. I would create the Gateway and GatewayClass first, while keeping the current Ingress setup active.

- **3. Migrate a few applications first:** I would convert some lower-risk Ingress resources to `HTTPRoute` and test them properly. I would check normal HTTP/HTTPS traffic, TLS, redirects, authentication, rewrites, and backend connectivity. NGINX-specific annotations are one of the main areas I would expect issues.

- **4. Cut traffic over gradually:** Once the new routes are tested, I would move production traffic gradually rather than changing all 40 applications at once. I would monitor errors, latency, TLS issues, and application health, while keeping the old ingress available for rollback.

- **5. Remove ingress-nginx only after validation:** After all applications are migrated and stable, I would remove the old Ingress resources and ingress-nginx configuration. I would expect some cleanup around old annotations, rewrites, authentication, TLS settings, and other controller-specific behavior.
