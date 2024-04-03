FROM ruby:2.7.7

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

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
COPY ./web/package.json /gpt/web/package.json
COPY ./web/yarn.lock /gpt/web/yarn.lock

WORKDIR /gpt/web
RUN bundle install
RUN yarn

# COPY ./web /gpt/web
COPY . /gpt

# Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
RUN apt-get -y update
RUN apt-get install -y google-chrome-stable

RUN pip install -r /gpt/requirements.txt
RUN curl https://get.gptscript.ai/install.sh | sh

EXPOSE 3000

COPY ./entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]