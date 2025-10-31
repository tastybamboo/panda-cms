# Private Gem Server Strategy

Panda CMS Pro is distributed under a commercial license, so we need a private RubyGems-compatible server that we fully control. The easiest way to achieve this is to run [Gemstash](https://github.com/rubygems/gemstash) in our infrastructure.

## Why Gemstash?

- Battle‑tested Rack app maintained by RubyGems.org maintainers.
- Provides both a private gem index and a caching proxy for rubygems.org in case we want it later.
- Simple to run in Docker (Fly.io, Render, Heroku, ECS, etc.).

## Reference Deployment

```yaml
# docker-compose.gemstash.yml
version: "3.8"
services:
  gemstash:
    image: rubygems/gemstash:latest
    ports: ["9292:9292"]
    environment:
      GEMSTASH_AUTH_TOKEN: ${GEMSTASH_AUTH_TOKEN}
      GEMSTASH_FALLBACK_ALLOWED: "true"
      GEMSTASH_PRIVATE_KEY: ${GEMSTASH_PRIVATE_KEY}
    volumes:
      - gemstash-data:/var/lib/gemstash
volumes:
  gemstash-data:
```

1. Generate a long random `GEMSTASH_AUTH_TOKEN` and store it as a secret in the hosting platform.
2. Set up TLS (Fly/Railway render TLS automatically; for bare-metal use an Nginx proxy terminated with Let's Encrypt).
3. Restrict ingress with firewall + Basic Auth if the platform supports it.

## Publishing panda-cms-pro

```bash
cd panda-cms-pro
gem build panda-cms-pro.gemspec
curl -u "token:${GEMSTASH_AUTH_TOKEN}" \
  -F "gem=@panda-cms-pro-0.1.0.gem" \
  https://gems.pandacms.io/api/v1/gems
```

Automate this in CI (e.g., GitHub Actions) by storing `GEMSTASH_AUTH_TOKEN` + `GEM_HOST=https://gems.pandacms.io` secrets. Only publish from tagged releases.

## Consuming the Gem

In any Panda host application:

```ruby
source "https://gems.pandacms.io" do
  gem "panda-cms-pro"
end

gem "panda-cms"
```

Then configure Bundler to authenticate once per developer/CI runner:

```bash
bundle config set https://gems.pandacms.io token:${GEMSTASH_AUTH_TOKEN}
```

## Operational Notes

- Back up the `gemstash-data` volume regularly (daily snapshot is enough because gems are immutable).
- Monitor latency/availability; the Rack app is lightweight so a single `t3.small` or Fly `shared-cpu-1x` VM is adequate.
- Rotate the auth token periodically; Gemstash allows multiple tokens if we later wire an upstream proxy.
- Document the release cadence and versioning policy so customers can pin to specific versions.
