require 'rubygems'
require 'bundler'

Bundler.require
Dotenv.load

require './heroku-aws-rds-test'
run HerokuAwsRdsTest::App
