FROM ruby:latest

# Install common development tools
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install git build-essential libssl-dev \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install bundler
RUN gem install bundler

# Set working directory
WORKDIR /workspace

# Install project dependencies when the Gemfile changes
COPY Gemfile* *.gemspec ./
RUN bundle install

# Set the default shell to bash
ENV SHELL=/bin/bash
