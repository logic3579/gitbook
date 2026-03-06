FROM ubuntu:24.04

# Switch to root user
USER root

# Create non-root user
RUN groupadd -r app && useradd -r -g app app

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    net-tools \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Define working directory
ENV APP=/app

# Create and switch the work directory
RUN mkdir -p $APP && chown app:app $APP
WORKDIR $APP

# This directory is created by the build step in CICD workflow
COPY --chown=app:app . .

# Switch to non-root user
USER app

# Set environment variables
ENV PORT=80

# Expose port
EXPOSE 80

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["echo", "App started"]
