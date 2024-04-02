FROM ruby:2.7.7

RUN apt-get update && apt-get install -y \
  python3-pip\
  build-essential \
  postgresql-client \
  nodejs \
  yarn

RUN mkdir /gpt
RUN mkdir /gpt/web

COPY ./web/Gemfile /gpt/web/Gemfile
COPY ./web/Gemfile.lock /gpt/web/Gemfile.lock

WORKDIR /gpt/web
RUN bundle install

# COPY ./web /gpt/web
COPY . /gpt

RUN pip install -r /gpt/requirements.txt
RUN curl https://get.gptscript.ai/install.sh | sh

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]