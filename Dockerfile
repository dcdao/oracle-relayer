# Use the latest foundry image
FROM ghcr.io/foundry-rs/foundry

RUN apk add --no-cache bash build-base jq curl
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install ethabi-cli

RUN apk add --no-cache ruby
RUN gem install bundler

# Copy our source code into the container
WORKDIR /app

# Build and test the source code
COPY . .

ENV BUNDLE_GEMFILE=./generator/Gemfile
RUN bundle install

ENTRYPOINT [ "./bin/docker-entrypoint.sh" ]
