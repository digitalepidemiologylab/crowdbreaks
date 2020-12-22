FROM ruby:2.5.8

# Install nodejs
RUN apt-get update -qq && apt-get install -y nodejs

# Add Yarn repository
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Update
RUN apt-get update -y

# Install Yarn
RUN apt-get install yarn -y

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.1.4
RUN bundle install

# install js packages
COPY package.json yarn.lock ./
RUN yarn install --check-files

# Copy all other files
COPY . ./

EXPOSE 3000

CMD ["bin/rails", "s", "-p", "3000", "-b", "0.0.0.0"]

