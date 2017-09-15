FROM ruby:2.3.1


RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
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
ENV PORT 3000
EXPOSE 3000
CMD ["ruby", "app.rb"]
