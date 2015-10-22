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

  describe "find_empty_partitions" do

    subject(:strategy) {
      klass.new(
        operation, base_config.merge({ :desirable_empty_partitions => 2, :min_empty_partitions => 1 })
      )
    }
 
    context "When max val is nil" do
      let(:operation) {
        operation = base_operation
        allow(operation).to receive(:get_max_val).and_return(nil)
        operation
      }

      it "should return all partitiosn" do
        expect(strategy.find_empty_partitions(partitions)).to eq(partitions)
      end
    end

    

    context "When max val belongs to first partition" do

      let(:operation) {
        operation = base_operation
        allow(operation).to receive(:get_max_val).and_return(99)
        operation
      }

      it "should return partitions after first partition only" do
        expect(strategy.find_empty_partitions(partitions)).to eq(partitions[1..2])
      end
    end

    context "When max val belongs to second partition" do
      let(:operation) {
        operation = base_operation
        allow(operation).to receive(:get_max_val).and_return(100)
        operation
      }

      it "should partitions after second" do
        expect(strategy.find_empty_partitions(partitions)).to eq(partitions[2..2])
      end
    end

  end
end
