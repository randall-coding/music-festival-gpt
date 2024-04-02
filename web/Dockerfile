FROM ruby:2.7.7

RUN apt-get update && apt-get install -y \
  python3-pip\
  build-essential \
  postgresql-client \
  nodejs \
  yarn

RUN mkdir /web
RUN mkdir /gpt

COPY Gemfile /web/Gemfile
COPY Gemfile.lock /web/Gemfile.lock

WORKDIR /web
RUN bundle install

COPY . /web
COPY ../ /gpt

RUN pip install -r /gpt/requirements.txt
RUN curl https://get.gptscript.ai/install.sh | sh

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]