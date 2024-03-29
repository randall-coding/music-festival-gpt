# README
initialization:
* cp config/database.yml.example config/database.yml
* cp config/application.yml.example config/application.yml

Run Docker:

* docker-compose build

* docker-compose run app rake db:create
* docker-compose run app rake rails db:migrate
* docker-compose run app rake rails db:seed

* docker-compose up