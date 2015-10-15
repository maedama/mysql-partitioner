require 'optparse'
require 'logger'
require 'yaml'
require 'mysql2'
require 'mysql/partitioner/strategy'
require 'mysql/partitioner/session'
require 'deep_hash_transform'

module Mysql
  module Partitioner
    class Cli
      def run()

        options = {
          :dry_run     => false,
          :debug       => false,
          :config      => nil,
        }
        begin
          ARGV.options do |opt|
            opt.on("-c", "--config CONFIG_NAME")         {    |v| options[:config] = v }
            opt.on("", "--cmd check or migrate")         {    |v| options[:cmd] = v  }
            opt.on('',   '--dry-run')                    {    |v| options[:dry_run]  = v }
            opt.on('-d',   '--debug')                    {    |v| options[:debug]  =  v }
            opt.parse!
          end
        rescue => e
          $stderr.puts e
          exit 1
        end
        config = nil
        begin
          config = YAML.load_file(options[:config])
        rescue => e
          puts "Failed to load yaml file #{options[:config]} #{e}"
          exit 1
        end

        logger = Logger.new(STDOUT)
        logger.level = options[:debug] ?  Logger::DEBUG : Logger::INFO
        config.deep_symbolize_keys!

        config.keys.each do|item|
          task = config[item]
          database = task[:database]
          cli =  Mysql2::Client.new(
            :host     => database[:host],
            :username => database[:username],
            :password => database[:password],
            :port     => database[:port],
            :database => database[:name],
          )
          session = Mysql::Partitioner::Session.new(cli, options[:dry_run], logger)
          strategy = Mysql::Partitioner::Strategy.build(session, task[:table], task[:strategy])
          case options[:cmd]
          when "check"
            logger.info("Running check on #{item}")
            strategy.check!
            logger.info("success")
          when "migrate"
            logger.info("Running migrate on #{item} dry_run=#{options[:dry_run]}")
            strategy.migrate
            logger.info("success")
          else
            raise "Unknown command"
          end
        end
      end
    end
  end
end
