require 'rubygems'
require 'bundler'

Bundler.require

require './heroku-aws-rds-test'
run Sinatra::Application
