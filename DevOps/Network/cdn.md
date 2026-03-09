---
description: CDN
---

# CDN

Content Delivery Network (CDN) is a distributed network of edge servers that caches and delivers content from the nearest node to users, reducing latency and offloading origin server traffic.

## How CDN Works

```
User Request → DNS Resolution → CDN Edge Node (cache hit?)
                                  ├── Hit  → Return cached content
                                  └── Miss → Fetch from Origin → Cache at edge → Return
```

1. User requests `https://example.com/style.css`
2. DNS resolves the domain to the nearest CDN edge node (via CNAME or Anycast)
3. Edge node checks local cache:
   - **Cache Hit**: Return content directly from edge, with header `X-Cache: HIT`
   - **Cache Miss**: Forward request to origin server, cache the response, then return to user

## Cache Rules

### Origin Cache-Control Headers

The origin server controls CDN caching behavior via `Cache-Control` response headers:

| Directive | Description |
|-----------|-------------|
| `public` | Response can be cached by CDN and browsers |
| `private` | Response can only be cached by browsers, not CDN |
| `max-age=<seconds>` | Cache TTL in seconds (e.g., `max-age=3600` = 1 hour) |
| `s-maxage=<seconds>` | CDN-specific TTL, overrides `max-age` for shared caches |
| `no-cache` | Must revalidate with origin before using cached copy |
| `no-store` | Do not cache at all (sensitive data) |
| `must-revalidate` | Once stale, must revalidate before use |
| `stale-while-revalidate=<s>` | Serve stale content while revalidating in background |

### Common Cache Strategies

```
# Static assets (CSS, JS, images, fonts) — long TTL + content hash in filename
Cache-Control: public, max-age=31536000, immutable

# HTML pages — always revalidate
Cache-Control: no-cache

# API responses — no caching
Cache-Control: no-store

# CDN-specific TTL different from browser TTL
Cache-Control: public, max-age=60, s-maxage=3600
```

### Cache Key

CDN uses a cache key to identify cached objects. The default key typically includes:
- Scheme (HTTP/HTTPS)
- Host
- URI path
- Query string

Some CDNs allow customizing cache keys to include/exclude query strings, headers, or cookies.

## Browser Cache

### Cache Loading Order

1. **Memory Cache** — Fastest. Stores resources in browser memory (tab process). Cleared when tab closes. Typically used for images, scripts loaded in the current page
2. **Disk Cache** — Persists on disk across sessions. Stores larger resources (CSS, JS, fonts). Survives tab/browser restarts
3. **Conditional Request (304)** — Browser sends `If-None-Match` (ETag) or `If-Modified-Since` to server. Server returns `304 Not Modified` if unchanged
4. **Full Request (200)** — No cache available, fetches the full response from server/CDN

### Validation Headers

| Request Header | Response Header | Description |
|----------------|-----------------|-------------|
| `If-None-Match` | `ETag` | Content hash comparison |
| `If-Modified-Since` | `Last-Modified` | Timestamp comparison |

```
# First request — server returns resource with validators
HTTP/1.1 200 OK
ETag: "abc123"
Last-Modified: Mon, 01 Jan 2026 00:00:00 GMT
Cache-Control: no-cache

# Subsequent request — browser sends conditional request
GET /style.css HTTP/1.1
If-None-Match: "abc123"
If-Modified-Since: Mon, 01 Jan 2026 00:00:00 GMT

# Server response if unchanged
HTTP/1.1 304 Not Modified
```

### Chrome DevTools Cache Behavior

| DevTools Option | Effect |
|-----------------|--------|
| `Disable cache` (checked) | Bypasses memory cache, disk cache, and sends `Cache-Control: no-cache` |
| Normal browsing | Uses full cache loading order |
| Hard Refresh (`Cmd+Shift+R`) | Bypasses cache, sends `Cache-Control: no-cache` |

## CDN Response Headers

Common CDN-specific response headers for debugging:

| Header | Description | Example |
|--------|-------------|---------|
| `X-Cache` | Cache status | `HIT`, `MISS`, `EXPIRED` |
| `CF-Cache-Status` | Cloudflare cache status | `HIT`, `MISS`, `DYNAMIC`, `BYPASS` |
| `X-Cache-Hits` | Number of times served from cache | `3` |
| `Age` | Time (seconds) object has been in CDN cache | `120` |
| `Via` | Intermediate proxies/CDN nodes | `1.1 varnish` |
| `X-Served-By` | CDN node that served the request | `cache-hkg123` |
| `CF-Ray` | Cloudflare request ID + datacenter | `abc123-HKG` |

## Debugging

### curl

```bash
# Check CDN cache status and response headers
curl -sI https://example.com/style.css

# Bypass CDN cache (force origin fetch)
curl -sI -H 'Cache-Control: no-cache' https://example.com/style.css

# Check compressed response
curl -sI -H 'Accept-Encoding: br, gzip, deflate' https://example.com/style.css
# Response: content-encoding: br

# Resolve to specific CDN node or origin IP
curl -sI https://example.com/style.css --resolve example.com:443:1.1.1.1

# Check response time breakdown
curl -o /dev/null -w "\
  DNS:        %{time_namelookup}s\n\
  Connect:    %{time_connect}s\n\
  TLS:        %{time_appconnect}s\n\
  TTFB:       %{time_starttransfer}s\n\
  Total:      %{time_total}s\n" \
  -s https://example.com/style.css
```

### dig / nslookup

```bash
# Verify CDN DNS resolution (CNAME to CDN)
dig example.com +short
# example.com.cdn.cloudflare.net.
# 104.21.x.x

# Check which CDN POP is serving
nslookup example.com
```

## Cache Purge

```bash
# Cloudflare — purge single file
curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache" \
  -H "Authorization: Bearer {api_token}" \
  -H "Content-Type: application/json" \
  --data '{"files":["https://example.com/style.css"]}'

# Cloudflare — purge everything
curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache" \
  -H "Authorization: Bearer {api_token}" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'

# AWS CloudFront — create invalidation
aws cloudfront create-invalidation \
  --distribution-id E1234567890 \
  --paths "/style.css" "/images/*"
```

> Reference:
>
> 1. [Cloudflare CDN](https://www.cloudflare.com/application-services/products/cdn/)
> 2. [AWS CloudFront](https://aws.amazon.com/cloudfront/)
> 3. [MDN Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
> 4. [MDN HTTP Caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching)
