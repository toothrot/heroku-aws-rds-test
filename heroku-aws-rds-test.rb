class HerokuAwsRdsTest
  def self::pg_connection
    uri = URI.parse(ENV["DATABASE_URL"])
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

  class App < Sinatra::Base
    get '/' do
      require 'benchmark'
      output = ""
      output << Benchmark.bm do |x|
        x.report("Query current time") { output << "#{HerokuAwsRdsTest.pg_connection.exec('select NOW() AS current_time').first["current_time"]}<br/>" }
      end.first.format("%n: user: %u system: %y total: %t real: %r")
      output
    end
  end
end
