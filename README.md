<img src="app/assets/images/logo-crowdbreaks.svg" alt="Crowdbreaks logo" width="400px"/>

This is the Rails application of Crowdbreaks.

# Install

## Development
1. First, install ruby and rails through rbenv [by following this tutorial](https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-16-04)
```
rbenv install 2.5.0
rbenv global 2.5.0
```
2. Install Redis, have it run locally on port 6379. 
3. Pull repo & install dependencies
```
git clone git@github.com:salathegroup/crowdbreaks.git && cd crowdbreaks
bundle install
```
4. Create Postgres using `rake db:setup`
5. Change config in `config/application.yml`
6. Run development server
```
# Rails development server
bin/rails s
# Webpack development server
bin/server
# Background jobs
bundle exec sidekiq -q default -q mailers 
```
7. Run tests using `rspec` or `bundle exec guard`.

You may need to run the [crowdbreaks-streamer](https://github.com/crowdbreaks/crowdbreaks-streamer) for full functionality, but in principle, the Rails application should run without errors on its own.


# Contact
In case of questions feel free to write to info@crowdbreaks.org or directly to Martin Müller (martin.muller@epfl.ch)
