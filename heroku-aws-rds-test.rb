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

    def create_table(connection)
      connection.exec("drop table if exists foo")
      connection.exec("create table foo (id integer)")
    end

    def select_1(connection)
      connection.exec("select 1")
    end

    def select_all(connection)
      connection.exec("select * from foo")
    end

    def insert(connection, value)
      connection.exec("insert into foo values(#{value})")
    end

    def truncate(connection)
      connection.exec("truncate foo")
    end

    get '/' do
      require 'benchmark'
      output = "<table>"
      output << Benchmark.bm do |x|
        x.report("RDS Connect") { HerokuAwsRdsTest.amazon_rds_connection }
        x.report("Heroku Connect") { HerokuAwsRdsTest.amazon_rds_connection }
      end.map {|report| report.format("<tr><td>%n:</td> <td>user: %u</td> <td>system: %y</td> <td>total: %t</td> <td>real: %r</td></tr>") }.join('')

      create_table(HerokuAwsRdsTest.amazon_rds_connection)
      create_table(HerokuAwsRdsTest.heroku_postgres_connection)

      output << Benchmark.bmbm do |x|
        x.report("RDS Query current time") { HerokuAwsRdsTest.amazon_rds_connection.exec('select NOW() AS current_time').first["current_time"] }
        x.report("Heroku Query current time") { HerokuAwsRdsTest.heroku_postgres_connection.exec('select NOW() AS current_time').first["current_time"] }
        x.report("RDS 1000x SELECT 1") { 1_000.times { select_1(HerokuAwsRdsTest.amazon_rds_connection) } }
        x.report("Heroku 1000x SELECT 1") { 1_000.times { select_1(HerokuAwsRdsTest.amazon_rds_connection) } }
        x.report("RDS 100x INSERT 1") { 100.times { insert(HerokuAwsRdsTest.amazon_rds_connection, 1) } }
        x.report("Heroku 100x INSERT 1") { 100.times { insert(HerokuAwsRdsTest.amazon_rds_connection, 1) } }
        x.report("RDS 100x SELECT *") { 100.times { select_all(HerokuAwsRdsTest.amazon_rds_connection) } }
        x.report("Heroku 100x SELECT *") { 100.times { select_all(HerokuAwsRdsTest.amazon_rds_connection) } }
        x.report("RDS Truncate") { truncate(HerokuAwsRdsTest.amazon_rds_connection)  }
        x.report("Heroku Truncate") { truncate(HerokuAwsRdsTest.amazon_rds_connection)  }
      end.map {|report| report.format("<tr><td>%n:</td> <td>user: %u</td> <td>system: %y</td> <td>total: %t</td> <td>real: %r</td></tr>") }.join('')
      output << "</table>"
      output
    end
  end
end
