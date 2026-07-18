###############################################################################
# GitHub Readme Stats
#
# Production Container Image
#
# Build Context:
#   Project repository root
#
# Application Source:
#   deployment/github-readme-stats
###############################################################################

FROM node:22-alpine AS dependencies

###############################################################################
# Application Directory
###############################################################################

WORKDIR /app

###############################################################################
# Install Application Dependencies
#
# The upstream application currently declares Express as a development
# dependency even though express.js requires it at runtime. Therefore all
# dependencies must be installed for the standalone Express deployment.
###############################################################################

COPY deployment/github-readme-stats/package.json ./
COPY deployment/github-readme-stats/package-lock.json ./

RUN npm ci

###############################################################################
# Production Runtime
###############################################################################

FROM node:22-alpine AS runtime

###############################################################################
# Runtime Dependencies
###############################################################################

RUN apk add --no-cache curl

###############################################################################
# Application Directory
###############################################################################

WORKDIR /app

###############################################################################
# Runtime Environment
###############################################################################

ENV NODE_ENV=production

###############################################################################
# Application Dependencies
###############################################################################

COPY --from=dependencies --chown=node:node \
    /app/node_modules \
    ./node_modules

###############################################################################
# Application Source
###############################################################################

COPY --chown=node:node \
    deployment/github-readme-stats/ \
    ./

###############################################################################
# Container Runtime Scripts
###############################################################################

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x \
    /usr/local/bin/entrypoint.sh \
    /usr/local/bin/healthcheck.sh

###############################################################################
# Runtime User
###############################################################################

USER node

###############################################################################
# Application Port
###############################################################################

EXPOSE 9000

###############################################################################
# Container Health Check
###############################################################################

HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=15s \
    --retries=3 \
    CMD ["/usr/local/bin/healthcheck.sh"]

###############################################################################
# Container Entrypoint
###############################################################################

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

###############################################################################
# Application Command
###############################################################################

CMD ["node", "express.js"]