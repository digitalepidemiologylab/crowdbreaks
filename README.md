<img src="app/assets/images/logo-crowdbreaks.svg" alt="Crowdbreaks logo" width="400px"/>

This is the Rails application of Crowdbreaks. For a more general intro toCrowdbreaks please follow [this link](https://github.com/crowdbreaks/welcome).

[![Build Status](https://travis-ci.org/crowdbreaks/crowdbreaks.svg?branch=master)](https://travis-ci.org/crowdbreaks/crowdbreaks)

# Install
You may want to run the [crowdbreaks-streamer](https://github.com/crowdbreaks/crowdbreaks-streamer) for full functionality, but the Rails application works fine on its own.

## Development

### With docker
This setup was tested with docker version 20.10.0, and docker-compose version 1.27.4.

1. Install docker/docker-compose
2. Clone this repository and `cd` into project folder
3. Copy example secrets file `cp config/application.yml.example config/application.yml`
4. Run `docker-compose up`
5. Create, migrate, and seed the database
```bash
docker exec app bundle exec rails db:create db:migrate db:seed
```
This creates the database `crowdbreaks_development` and creates a new user `admin@example.com` with password `password`.

6. Go to `localhost:3000` :rainbow:

### Without docker
1. First, install ruby e.g. through [rbenv](https://github.com/rbenv/rbenv).
```bash
rbenv install 2.5.8
rbenv global 2.5.8
```
2. Install [Redis](https://redis.io/topics/quickstart), e.g. with `brew install redis && brew services start redis`
3. Install [Postgres](https://www.postgresql.org/), e.g. with `brew install postgresql && brew services start postgresql`
4. Install node and yarn, e.g. with `brew install node yarn`
5. Clone this repository and `cd` into project folder
```bash
git clone git@github.com:salathegroup/crowdbreaks.git && cd crowdbreaks
```
6. Copy example secrets file `cp config/application.yml.example config/application.yml`
7. Install dependencies
```bash
gem install bundler -v 2.1.4
bundle install
yarn install
```
8. Create, migrate, and seed the database
```bash
bundle exec rails db:create db:migrate db:seed
```
9. Run servers
```
# Rails development server
bin/rails s
# Webpack development server (in a separate tab)
bin/server
# Background jobs (in a separate tab)
bundle exec sidekiq -q default -q mailers
```

## Tests
### With docker
Run docker-compose up, and run tests via:
```bash
docker exec app bundle exec rspec
```

### Without docker
Currently js tests are not supported outside of docker. Everything else should still pass:
```bash
bundle exec rspec
```

# Documentation
You can find more information to specific topics on the [Crowdbreaks wiki](https://github.com/crowdbreaks/crowdbreaks/wiki).

# Contact
In case of questions feel free to write to [info@crowdbreaks.org](mailto:info@crowdbreaks.org).
