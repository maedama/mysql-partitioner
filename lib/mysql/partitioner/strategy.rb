require 'mysql/partitioner/strategy/partition_by_pk_drop_by_time'
require 'mysql/partitioner/operation'

module Mysql
  module Partitioner
    module Strategy
      def self.build(session, table, config)
        case config[:name]
        when "partition_by_pk_drop_by_time" then
          PartitionByPkDropByTime.new(Mysql::Partitioner::Operation::Range.new(table, session), config)
        else raise "Unknown strategy error"
        end
      end
    end
  end
end
