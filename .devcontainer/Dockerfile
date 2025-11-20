# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.7
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

# Install MySQL client libraries for mysql2 gem
USER root
RUN mkdir -p /var/lib/apt/lists/partial && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y libmariadb-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Switch back to vscode user (provided by base Rails devcontainer image)
USER vscode

# Ensure binding is always 0.0.0.0
# Binds the server to all IP addresses of the container, so it can be accessed from outside the container.
ENV BINDING="0.0.0.0"
