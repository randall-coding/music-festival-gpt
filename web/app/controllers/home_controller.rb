class HomeController < ApplicationController
  def index
    @bands = Band.all
  end
end
