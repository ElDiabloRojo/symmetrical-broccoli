# Stage 1: Install node_modules then transpile the TypeScript code to JavaScript
FROM node:12-alpine3.12 as builder

ARG PACKAGE_NAME
ARG SUB_PACKAGE_NAME
ARG SERVICE_DIR
ARG TYPE

ENV PATH "/www/node_modules/.bin:${PATH}"
ENV CI=true

WORKDIR /www

# Install Linux dependencies needed prior to running npm install
RUN apk --no-cache add \
    jq \
    python3 \
    make \
    g++ \
    gcc \
    pkgconfig \
    pixman-dev \
    cairo-dev \
    pango-dev \
    libjpeg-turbo-dev \
    giflib-dev

# Top level files
COPY lerna.json package.json package-lock.json \
    ./
# Package files
COPY packages/common/package-lock.json \
    packages/common/package.json \
    ./packages/common/
    
COPY packages/frontend-utils/package-lock.json \
    packages/frontend-utils/package.json \
    ./packages/frontend-utils/

COPY packages/bpk-components/package-lock.json \
    packages/bpk-components/package.json \
    ./packages/bpk-components/

COPY packages/email/package-lock.json \
    packages/email/package.json \
    ./packages/email/

COPY packages/ui-components/package-lock.json \
    packages/ui-components/package.json \
    ./packages/ui-components/

COPY packages/ui-components/package/package-lock.json \
    packages/ui-components/package/package.json \
    ./packages/ui-components/package/

COPY packages/sanitize-html/package-lock.json \
    packages/sanitize-html/package.json \
    ./packages/sanitize-html/

COPY packages/strings/package-lock.json \
    packages/strings/package.json \
    ./packages/strings/

COPY packages/fastify-server-startup/package-lock.json \
    packages/fastify-server-startup/package.json \
    ./packages/fastify-server-startup/

# Service files
COPY ${SERVICE_DIR}/package-lock.json \
    ${SERVICE_DIR}/package.json \
    ./${SERVICE_DIR}/
COPY ${SERVICE_DIR}/${TYPE}/package-lock.json \
    ${SERVICE_DIR}/${TYPE}/package.json \
    ./${SERVICE_DIR}/${TYPE}/

# Remove test-framework devDependency, so we don't have to include it in the build
RUN jq "del(.devDependencies.\"@ukri-tfs/test-framework\")" < ${SERVICE_DIR}/package.json > tmp_package.json && \
    mv tmp_package.json ${SERVICE_DIR}/package.json

# Bootstrap package deps
RUN npm i && \
    lerna bootstrap --include-dependencies --scope="{${PACKAGE_NAME},${SUB_PACKAGE_NAME}}"

# Copy build files and transpile the TypeScript code to JavaScript
COPY packages ./packages/
COPY types ./types/
COPY ${SERVICE_DIR} ./${SERVICE_DIR}/
RUN lerna run build --include-dependencies --scope=${SUB_PACKAGE_NAME}

# Prune devDeps, so we can copy node_modules in subsequent image (and avoid second install)
# npm prune always removes symlinks, so need to re-install
RUN lerna exec -- npm prune --production && \
    NODE_ENV=production lerna bootstrap --include-dependencies --scope="${SUB_PACKAGE_NAME}"

# We only build required deps and use a shared Dockerfile, but can't dynamically COPY in next stage, so ensure they exist
RUN mkdir -p \
        packages/bpk-components/dist \
        packages/frontend-utils/dist \
        packages/frontend-utils/node_modules \
        packages/email/dist \
        packages/email/node_modules \
        packages/ui-components/package/dist \
        packages/ui-components/package/node_modules \
        packages/sanitize-html/node_modules \
        packages/fastify-server-startup/dist \
        packages/fastify-server-startup/node_modules \
        ./${SERVICE_DIR}/${TYPE}/public/ \
        ./${SERVICE_DIR}/${TYPE}/dist/ \
        ./${SERVICE_DIR}/${TYPE}/.next/ && \
    touch ${SERVICE_DIR}/${TYPE}/next.config.js


# Stage 2: Copy artifacts from stage 1 image needed for running service
FROM node:12-alpine3.12

ARG PACKAGE_NAME
ARG SUB_PACKAGE_NAME
ARG SERVICE_DIR
ARG TYPE
ARG PORT
ARG HEALTH_CHECK_ENDPOINT
ARG START_FILE
ARG IS_RUNNING_SSL='true'
ARG START_CMD_OVERRIDE

ENV NODE_ENV=production
# Used in CMD and healthcheck, so must be env vars too
ENV TYPE=${TYPE}
ENV SERVICE_DIR=${SERVICE_DIR}
ENV START_FILE=${START_FILE}
ENV PORT=${PORT}
ENV HEALTH_CHECK_ENDPOINT=${HEALTH_CHECK_ENDPOINT}
ENV START_CMD_OVERRIDE=${START_CMD_OVERRIDE}
ENV IS_RUNNING_SSL=${IS_RUNNING_SSL}

WORKDIR /www

# Copy transpiled JS files from packages in stage 1 image
COPY --from=builder /www/packages/common/package.json \
                    /www/packages/common/package-lock.json \
                    ./packages/common/
COPY --from=builder /www/packages/common/dist         ./packages/common/dist/
COPY --from=builder /www/packages/common/node_modules ./packages/common/node_modules/

COPY --from=builder /www/packages/bpk-components/package.json \
                    /www/packages/bpk-components/package-lock.json \
                    ./packages/bpk-components/
COPY --from=builder /www/packages/bpk-components/dist         ./packages/bpk-components/dist/

COPY --from=builder /www/packages/frontend-utils/package.json \
                    /www/packages/frontend-utils/package-lock.json \
                    ./packages/frontend-utils/
COPY --from=builder /www/packages/frontend-utils/dist         ./packages/frontend-utils/dist/
COPY --from=builder /www/packages/frontend-utils/node_modules ./packages/frontend-utils/node_modules/

COPY --from=builder /www/packages/email/package.json \
                    /www/packages/email/package-lock.json \
                    ./packages/email/
COPY --from=builder /www/packages/email/dist         ./packages/email/dist/
COPY --from=builder /www/packages/email/node_modules ./packages/email/node_modules/

COPY --from=builder /www/packages/ui-components/package/package.json \
                    /www/packages/ui-components/package/package-lock.json \
                    /www/packages/ui-components/package.json \
                    /www/packages/ui-components/package-lock.json \
                    ./packages/ui-components/package/
COPY --from=builder /www/packages/ui-components/package/dist         ./packages/ui-components/package/dist/
COPY --from=builder /www/packages/ui-components/package/node_modules ./packages/ui-components/package/node_modules/

COPY --from=builder /www/packages/strings/package.json \
                    /www/packages/strings/package-lock.json \
                    ./packages/strings/
COPY --from=builder /www/packages/strings/dist         ./packages/strings/dist/
COPY --from=builder /www/packages/strings/node_modules ./packages/strings/node_modules/

COPY --from=builder /www/packages/sanitize-html/package.json \
                    /www/packages/sanitize-html/package-lock.json \
                    ./packages/sanitize-html/
COPY --from=builder /www/packages/sanitize-html/src         ./packages/sanitize-html/src/
COPY --from=builder /www/packages/sanitize-html/node_modules ./packages/sanitize-html/node_modules/

COPY --from=builder /www/packages/fastify-server-startup/package.json \
                    /www/packages/fastify-server-startup/package-lock.json \
                    ./packages/fastify-server-startup/
COPY --from=builder /www/packages/fastify-server-startup/dist         ./packages/fastify-server-startup/dist/
COPY --from=builder /www/packages/fastify-server-startup/node_modules ./packages/fastify-server-startup/node_modules/

# Copy transpiled JS files from service in stage 1 image 
COPY --from=builder /www/${SERVICE_DIR}/${TYPE}/dist          ./${SERVICE_DIR}/${TYPE}/dist/
COPY --from=builder /www/${SERVICE_DIR}/${TYPE}/public        ./${SERVICE_DIR}/${TYPE}/public/
COPY --from=builder /www/${SERVICE_DIR}/${TYPE}/.next         ./${SERVICE_DIR}/${TYPE}/.next/
COPY --from=builder /www/${SERVICE_DIR}/${TYPE}/node_modules  ./${SERVICE_DIR}/${TYPE}/node_modules/

# Copy service conf and package.json files
COPY --from=builder /www/${SERVICE_DIR}/package-lock.json \
                    /www/${SERVICE_DIR}/package.json \
                    ./${SERVICE_DIR}/
COPY --from=builder /www/${SERVICE_DIR}/${TYPE}/.env \
                    /www/${SERVICE_DIR}/${TYPE}/package-lock.json \
                    /www/${SERVICE_DIR}/${TYPE}/package.json \
                    /www/${SERVICE_DIR}/${TYPE}/next.config.js \
                    ./${SERVICE_DIR}/${TYPE}/

# Copy entrypoint and healthcheck files
COPY utils/docker/service/docker-entrypoint.sh ./
COPY utils/docker/service/docker-healthcheck.js ./
COPY utils/docker/service/newrelic.js ./${SERVICE_DIR}/${TYPE}/

# Install linux dependencies needed prior to running docker-entrypoint.sh script
RUN apk --no-cache add \
    bash \
    py-pip \
    openssl \
    ca-certificates && \
    pip install --no-cache-dir --upgrade awscli

# Expose port for application
EXPOSE ${PORT}

HEALTHCHECK --start-period=5s --timeout=3s \
    CMD node docker-healthcheck.js

ENTRYPOINT ["./docker-entrypoint.sh"]
