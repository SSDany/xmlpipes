require File.expand_path File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe XMLPipes::Source::Attribute do

  describe 'instantiation' do

    it 'raises a Source::InvalidAttributeError when type is not valid' do
      lambda { XMLPipes::Source::Attribute.new(:spec, :bogus) }.
      should raise_error XMLPipes::Source::InvalidAttributeError
    end

  end

  describe '#to_hash' do

    before(:each) do
      @timestamp = Time.now.to_i
      @attribute = XMLPipes::Source::Attribute.new(:spec, :timestamp, :default => Time.at(@timestamp))
      @to_hash = @attribute.to_hash
    end

    it 'returns an instance of Hash' do
      @to_hash.should be_an_instance_of(Hash)
    end

    it 'includes only valid keys' do
      @to_hash.keys.size.should == 3
      @to_hash[:name].should == :spec
      @to_hash[:type].should == :timestamp
      @to_hash[:default].should == @timestamp
    end

  end

end

describe XMLPipes::Source::Int do

  describe '#to_hash' do

    before(:each) do
      @attribute = XMLPipes::Source::Int.new(:spec, :default => 42, :bits => 8)
      @to_hash = @attribute.to_hash
    end

    it 'returns an instance of Hash' do
      @to_hash.should be_an_instance_of(Hash)
    end

    it 'includes only valid keys' do
      @to_hash.keys.size.should == 4
      @to_hash[:name].should == :spec
      @to_hash[:type].should == :int
      @to_hash[:bits].should == 8
      @to_hash[:default].should == 42
    end

  end

end