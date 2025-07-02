# Playvalve API Checker

This Rails API-only application provides a service to check the integrity status of users based on device and network conditions such as rooted devices, VPN/proxy usage, blacklists, and ban status. It integrates with Redis for caching and uses an external VPN API service for IP reputation checks.

---

## Features

- Check user status based on device and IP info
- Detect rooted devices, VPN, proxies, and Tor usage
- Use Redis to cache VPN API results and store blacklists
- Maintain user ban status in PostgreSQL
- Log integrity events for auditing
- Robust validation and error handling
- API endpoint to query ban status

---

## Architecture Overview

- **CheckStatusService**: Core service that validates input, checks Redis blacklists, calls VPN API, updates user ban status, and logs results.
- **VpnCheckService**: Handles IP reputation checking with caching using Redis and external VPN API.
- **IntegrityLoggerService**: Logs user integrity checks to the database (`IntegrityLog` model).
- **Redis**: Stores blacklist data (`country_blacklist`, `manual_banned_ips`) and caches VPN API responses.
- **External VPN API**: Third-party service to detect VPN, proxy, Tor usage based on IP.
- **PostgreSQL**: Stores user data, ban statuses, and logs.

---

## Environment Setup

### Required Environment Variables

| Variable       | Description                                  | Example                 |
|----------------|----------------------------------------------|-------------------------|
| `VPNAPI_KEY`   | API key to authenticate requests to VPN API | `your_vpn_api_key_here` |
| `REDIS_URL`    | Redis connection URL                         | `redis://localhost:6379`|

---

## Managing Blacklists in Redis

Redis is used to maintain blacklists for countries and manually banned IP addresses.

### Banning Countries

You can add country codes to the `country_blacklist` Redis set. For example, to ban United States (US), China (CN), and Russia (RU):

```bash
redis-cli sadd country_blacklist US CN RU

---

## API Documentation

The OpenAPI (Swagger) documentation is available at:

http://localhost:3000/api-docs/v1/swagger.yaml


