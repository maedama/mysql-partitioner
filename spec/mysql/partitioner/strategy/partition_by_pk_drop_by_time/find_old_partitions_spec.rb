require 'spec_helper'
describe Mysql::Partitioner::Strategy::PartitionByPkDropByTime do

  let(:partition) { Mysql::Partitioner::Partition::Range }
  let(:klass) { Mysql::Partitioner::Strategy::PartitionByPkDropByTime }
  let(:base_config) {
    { 
      :key      =>  "id",
      :time_key => "created_at",
      :ttl      =>  86400,
      :range    =>  100,
      :min_empty_partitions       => 3,
      :desirable_empty_partitions => 5,
    }
  }

  let(:partitions) {
    [ partition.new(100), partition.new(200), partition.new(300) ]
  }

  let(:base_operation) {
    operation = Mysql::Partitioner::Operation::Range.new(nil, nil)
    allow(operation).to receive(:check!).and_return(true)
    allow(operation).to receive(:partitionated?).and_return(true)
    allow(operation).to receive(:get_max_val).and_return(nil)
    operation
  }


  describe "find_old_partitions" do

    subject(:strategy) {
      klass.new(
        operation, base_config.merge({ :desirable_empty_partitions => 2, :min_empty_partitions => 1 })
      )
    }
 
    context "When partition is empty" do
      let(:operation) {
        operation = base_operation
        allow(operation).to receive(:get_max_val).and_return(nil)
        operation
      }
      
      it "should return empty" do
        expect(strategy.find_old_partitions(partitions)).to eq([])
      end
    end

    context "When none is old" do
      let(:operation) {
        operation = base_operation 
        allow(operation).to receive(:get_max_val).and_return(200)
        allow(operation).to receive(:of_max_val).with("id", "created_at", "p100").and_return(Time.now - 80000)
        allow(operation).to receive(:of_max_val).with("id", "created_at", "p200").and_return(Time.now - 70000)
        allow(operation).to receive(:of_max_val).with("id", "created_at", "p300").and_return(Time.now - 60000)
        operation
      }

      it "should return empty  partition" do
        expect(strategy.find_old_partitions(partitions)).to eq([])
      end
    end



    context "When first partition is old" do
      let(:operation) {
        operation = base_operation 
        allow(operation).to receive(:get_max_val).and_return(200)
        allow(operation).to receive(:of_max_val).with("id", "created_at", "p100").and_return(Time.now - 90000)
        allow(operation).to receive(:of_max_val).with("id", "created_at", "p200").and_return(Time.now - 70000)
        allow(operation).to receive(:of_max_val).with("id", "created_at", "p300").and_return(Time.now - 60000)
        operation
      }

      it "should return first partition" do
        expect(strategy.find_old_partitions(partitions)).to eq(partitions[0..0])
      end
    end

    context "When first partition is old but is stil active" do
      let(:operation) {
        operation = base_operation 
        allow(operation).to receive(:get_max_val).and_return(50)
        allow(operation).to receive(:of_max_val).with("id", "created_at", "p100").and_return(Time.now - 90000)
        allow(operation).to receive(:of_max_val).with("id", "created_at", "p200").and_return(Time.now - 70000)
        allow(operation).to receive(:of_max_val).with("id", "created_at", "p300").and_return(Time.now - 60000)
        operation
      }

      it "should return first partition" do
        expect(strategy.find_old_partitions(partitions)).to eq([])
      end
    end 
  end
end
