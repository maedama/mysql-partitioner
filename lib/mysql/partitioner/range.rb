module Mysql
  module Partition
    class Range
      
      def initialize(cli, partition)
        @client = cli
        @partition = partition
        load_partitions
      end

      def load_partitions()
        @database = @client.query("SELECT DATABASE()").first.values[0]
        results = @client.query(<<SQL)
            SELECT PARTITION_EXPRESSION, PARTITION_DESCRIPTION, PARTITION_ORDINAL_POSITION, PARTITION_METHOD, SUBPARTITION_EXPRESSION
            FROM INFORMATION_SCHEMA.PARTITIONS WHERE TABLE_NAME="#{@partition["table"]}" AND TABLE_SCHEMA="#{@database}"
SQL
        row = results.first
        if row.nil? then
          raise "Table schema not found"
        end

        if row["PARTITION_METHOD"] != "RANGE" and !row["PARTITION_METHOD"].nil? then
          raise "Not a range partition"
        end

        @partitions = results.select{|item| !item[:PARTITION_METHOD].nil? }.map {|item|
          { name: item[:partition_description], less_than: item[:PARTITION_ORDINAL_POSITION] }
        }
      end

      def get_next_partitions()
        next_partition = @partitions.dup
        next_partition = next_partition - find_old_partitions()
        next_partition = next_partition + build_new_partitions()
      end

      def find_old_partitions()
        @partitions.select {|item|
          find_most_recent_item(item) <= config[:target_date]
        }
      end

      def build_new_partitions() 
        max_val = select_max_val()
        partitioned_upto = @partitions.last ? @partitions.last["less_than"] : 0
        open_partitions = @partitions.select { |item| item[:less_than] > max_val }.size
        buildable = @partition["prepared"] - open_partitions
        result = []
        for i in (1 .. buildable) do
          new_less_than = partitioned_upto + @partition["interval"]
          result.push({ less_than: new_less_than, name: "p" + new_less_than.to_s })
          partitioned_upto = new_less_than
        end
        result
      end 

      def select_max_val()
        @client.query("SELECT MAX(#{@partition["key"]}) FROM #{@partition["table"]}").first.values[0] or 0
      end

    end
  end
end
