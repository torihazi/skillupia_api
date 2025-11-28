FROM ruby:3.4.7-slim
  
WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    libyaml-dev \
    vim \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 8000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]