# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=22-bookworm-slim

FROM node:${NODE_VERSION}

LABEL org.opencontainers.image.title="GitHub Readme Stats Deployment"
LABEL org.opencontainers.image.description="Production deployment for GitHub Readme Stats"
LABEL org.opencontainers.image.vendor="Vishal Tripathy"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /opt/github-readme-stats

# Upstream source configuration
ARG GRS_REPOSITORY=https://github.com/anuraghazra/github-readme-stats.git
ARG GRS_REF=master

# Clone and build steps will be added after upstream validation

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]