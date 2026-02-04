FROM ubuntu:latest

# Switch to root user
USER root

# Do something as root
RUN apt-get install -y net-tools \
    curl \
    wget

# This directory is created by the build step in CICD workflow
COPY --chown=app:app . .

# Create and switch the work directory
RUN mkdir $APP
WORKDIR $APP

# Switch to non-root user
USER app

# Set environment variables
ENV PORT=80

# Expose port
EXPOSE 80

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["echo", "App started"]
