FROM ruby:2.7.7

RUN apt-get update && apt-get install -y \
  python3-pip\
  build-essential \
  postgresql-client \
  nodejs \
  yarn

RUN mkdir /coachella-private
WORKDIR /coachella-private

COPY Gemfile /coachella-private/Gemfile
COPY Gemfile.lock /coachella-private/Gemfile.lock
RUN bundle install

COPY . /coachella-private
RUN pip install -r /coachella-private/lib/coachella-gpt-master/requirements.txt
RUN curl https://get.gptscript.ai/install.sh | sh

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]