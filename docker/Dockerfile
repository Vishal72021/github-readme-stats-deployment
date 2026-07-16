# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=ghcr.io/anuraghazra/github-readme-stats:latest

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="GitHub Stats Platform"
LABEL org.opencontainers.image.description="Production-grade deployment for GitHub Readme Stats."
LABEL org.opencontainers.image.vendor="Vishal Tripathy"
LABEL org.opencontainers.image.source="https://github.com/Vishal72021/github-stats-platform"
LABEL org.opencontainers.image.licenses="MIT"

ENV NODE_ENV=production

EXPOSE 9000

HEALTHCHECK --interval=30s \
           --timeout=5s \
           --start-period=30s \
           --retries=3 \
CMD wget --spider -q http://localhost:9000/ || exit 1