module Mysql
  module Partitioner
    class Session
      
      def initialize(client, dry_run, logger)
        @client = client
        @dry_run = dry_run
        @alters = []
        @logger = logger
      end

      def query(query)
        raise "Use do_alter for alter query" if query.match(/ALTER/i)
        @logger.debug(query)
        @client.query(query)
      end

      def alter(query)
        @alters.push(query)
        @logger.info(query)
        @client.query(query) if @dry_run == false
        true
      end
    end
  end
end
