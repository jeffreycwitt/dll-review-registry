FROM ruby:2.3.1

USER root

ENV IPFS_DIST_URL=https://dist.ipfs.io/go-ipfs/v0.4.10/go-ipfs_v0.4.10_linux-amd64.tar.gz \
    IPFS_PATH=/data/ipfs

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

RUN mkdir -p ~/tmp ;\
wget -qO- ${IPFS_DIST_URL} | tar xz -C ~/tmp/ ;\
mv ~/tmp/go-ipfs/ipfs /usr/local/bin/ ; rm -rf ~/tmp/*

RUN ipfs --version
RUN mkdir -p /data/ipfs
RUN ipfs init
EXPOSE 4001
EXPOSE 8080

RUN mkdir /dll-review-registry
WORKDIR /dll-review-registry

# Copy the Gemfiles and install gems. We copy only these files first so that
# Docker can still use the cached bundle install step, even when other source
# files are changing.
ADD Gemfile /dll-review-registry/Gemfile
ADD Gemfile.lock /dll-review-registry/Gemfile.lock
RUN bundle install

# Now add the rest of the files
ADD . /dll-review-registry

#Set Environemnet Variable
ENV RACK_ENV=docker

# Start server
ENV PORT 4567
EXPOSE 4567
CMD ["ruby", "app.rb"]
