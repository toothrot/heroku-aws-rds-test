class HerokuAwsRdsTest
  def self::pg_connection(uri)
    options = {
      host: uri.host,
      port: uri.port,
      user: uri.user,
      password: uri.password,
      dbname: uri.path[1..-1]
    }
    options.merge!(Hash[URI.decode_www_form( uri.query )]) if uri.query

    PG::Connection.new(options)
  end

  def self::amazon_rds_connection
    uri = URI.parse(ENV["AMAZON_RDS_POSTGRES_URL"])
    @amazon_rds_connection ||= pg_connection(uri)
  end

  def self::heroku_postgres_connection
    uri = URI.parse(ENV["HEROKU_POSTGRESQL_PURPLE_URL"])
    @heroku_postgres_connection ||= pg_connection(uri)
  end

  class App < Sinatra::Base
    get '/' do
      require 'benchmark'
      output = ""
      output << Benchmark.bm do |x|
        x.report("Query current time") { output << "#{HerokuAwsRdsTest.amazon_rds_connection.exec('select NOW() AS current_time').first["current_time"]}<br/>" }
      end.map {|report| report.format("%n: user: %u system: %y total: %t real: %r") }.join("<br/>")
      output
    end
  end
end
