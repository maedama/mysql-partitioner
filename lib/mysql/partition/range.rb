module Mysql
  module Partition
    class Range
      attr_accessor :table_name :database_name :dsn :partition_key
      
      def initialize()
        @client = Mysql2::Client.new(dsn)
      end

      def load_partitions():
        results = @client.query(<<SQL)
            SELECT PARTITION_EXPRESSION, PARTITION_DESCRIPTION, PARTITION_ORDINAL_POSITION, PARTITION_METHOD, SUBPARTITION_EXPRESSION
            FROM INFORMATION_SCHEMA.PARTITIONS WHERE TABLE_NAME="#{self.table_name}" AND TABLE_SCHEMA="#{self.database_name}"
SQL
        row = results.first
        if row.nil? then
          raise "Table schema not found"
        end

        if row["PARTITION_METHOD"] != "RANGE" then
          raise "Not a range partition"
        end

        @partitions = results.map {|item|
          { name: item[:partition_description], less_than: item[:PARTITION_ORDINAL_POSITION] }
        }
      end
    end

    def get_next_partitions():
      next_partition = @partitions.dup
      next_partition = next_partition - find_old_partitions
      next_partition = next_partition + build_old_partitions
    end

    def find_old_partitions
      @partitions.grep {|item|
        find_most_recent_item(item) <= config[:target_date]
      }
    end

    def build_new_partitions
    end 

  end
end
