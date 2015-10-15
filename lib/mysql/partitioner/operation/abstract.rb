module Mysql
  module Partitioner
    module Operation
      class Abstract

        attr_reader :table, :session, :dry_run
        
        def initialize(table, session)
          @table = table
          @session = session
        end

        def database
          @database = @database || @session.query("SELECT DATABASE()").first.values[0] or raise "database not selected"
        end

        def get_partition_type()
          results = @session.query(<<SQL)
SELECT PARTITION_EXPRESSION, PARTITION_DESCRIPTION, PARTITION_ORDINAL_POSITION, PARTITION_METHOD, SUBPARTITION_EXPRESSION
FROM INFORMATION_SCHEMA.PARTITIONS WHERE TABLE_NAME="#{ self.table }" AND TABLE_SCHEMA="#{ database }" LIMIT 1
SQL
          row = results.first
          if row.nil? then
            raise "Table not found table=#{self.table} db=#{self.database}"
          end
          return row["PARTITION_METHOD"]
        end

        def partitionated?()
          get_partition_type() != nil
        end

        def empty?()
          @session.query("SELECT 1 FROM #{@table} LIMIT 1").first.nil?
        end
        
        def get_max_val(key)
          @session.query("SELECT MAX(#{key}) FROM #{@table}").first.values[0]
        end
        
        def of_max_val(key, field, partition)
          @session.query("SELECT MAX(#{key}), #{field} FROM #{@table} PARTITION(#{partition})").first.values[1]
        end

      end
    end
  end
end
