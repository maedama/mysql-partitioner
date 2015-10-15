require 'spec_helper'

describe Mysql::Partitioner::Partition::Range do
  it 'name is p\d\d form' do
    expect(Mysql::Partitioner::Partition::Range.new(100).name).to eq("p100")
  end

  let(:a) { Mysql::Partitioner::Partition::Range.new(100) }
  let(:b) { Mysql::Partitioner::Partition::Range.new(100) }
  let(:c) { Mysql::Partitioner::Partition::Range.new(101) }

  it 'is equivalent when less_than is equal' do
    expect(a == b).to be(true)
    expect(a.eql?(b)).to be(true)
  end

  it 'is not equivalent when less_than is not equal' do
    expect(a == c).to be(false)
  end

  it 'is not identical when less than is equal' do
    expect(a.equal?(b)).to be(false)
  end

  it "Should output partition description" do
    expect(a.to_partition_def).to eq("PARTITION p100 VALUES LESS THAN (100)")
  end
end
