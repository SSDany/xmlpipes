require File.expand_path File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe XMLPipes::Source::Schema do

  before(:each) do
    @schema = XMLPipes::Source::Schema.new(:spec, :index)
  end

  describe '#indexes' do

    it 'defines a field' do
      @schema.indexes :summary
      @schema.indexes :content
      @schema.fields.size.should == 2
      @schema.fields[0].name.should == :summary
      @schema.fields[1].name.should == :content
    end

  end

  describe '#boolean' do

    it 'defines a boolean (bool) attribute' do
      @schema.boolean :deleted
      @schema.attrs.size.should == 1
      @schema.attrs.first.type.should == :bool
    end

    it 'allows to specify a default value' do
      @schema.boolean :deleted, :default => false
      @schema.boolean :present, :default => 'not false'
      @schema.attrs.first.default.should == 0
      @schema.attrs.last.default.should == 1
    end

  end

  describe '#float' do

    it 'defines a float attribute' do
      @schema.float :price
      @schema.attrs.size.should == 1
      @schema.attrs.first.type.should == :float
    end

    it 'allows to specify a default value' do
      @schema.float :price, :default => 42.00
      @schema.attrs.first.default.should == 42.00
    end

  end

  describe '#integer' do

    it 'defines an integer (int) attribute' do
      @schema.integer :hits
      @schema.attrs.size.should == 1
      @schema.attrs.first.type.should == :int
    end

    it 'allows to specify a default value' do
      @schema.integer :hits, :default => 42
      @schema.attrs.first.default.should == 42
    end

    it 'defaults bits to 32' do
      @schema.integer :hits
      @schema.attrs.first.bits.should == 32
    end

    it 'allows to specify a bits' do
      @schema.integer :hits, :bits => 16
      @schema.attrs.first.bits.should == 16
    end

    it 'raises a Source::InvalidAttributeError when bits are not in the valid interval' do
      lambda { @schema.integer :hits, :bits => 128 }.
      should raise_error XMLPipes::Source::InvalidAttributeError
    end

  end

  describe '#multi' do

    it 'defines an MVA (multi) attribute' do
      @schema.multi :genres
      @schema.attrs.size.should == 1
      @schema.attrs.first.type.should == :multi
    end

    it 'allows to specify a default value' do
      @schema.multi :genres, :default => %w(Hardcore Gabber)
      @schema.attrs.first.default.should == '3523896948,2066770622'
    end

  end

  describe '#ordinal' do

    it 'defines an ordinal (str2ordinal) attribute' do
      @schema.ordinal :author_name
      @schema.attrs.size.should == 1
      @schema.attrs.first.type.should == :str2ordinal
    end

    it 'allows to specify a default value' do
      @schema.ordinal :author_name, :default => 'Douglas Adams'
      @schema.attrs.first.default.should == 'Douglas Adams'
    end

  end

  describe '#timestamp' do

    it 'defines a timestamp attribute' do
      @schema.timestamp :created_at
      @schema.attrs.size.should == 1
      @schema.attrs.first.type.should == :timestamp
    end

    it 'allows to specify a default value (as a Time)' do
      @schema.timestamp :created_at, :default => Time.parse('Wed Oct 20 16:59:37 +0400 2010')
      @schema.attrs.first.default.should == 1287579577
    end

    it 'allows to specify a default value (as a DateTime)' do
      @schema.timestamp :created_at, :default => DateTime.parse('Wed Oct 20 16:59:37 +0400 2010')
      @schema.attrs.first.default.should == 1287579577
    end

    it 'allows to specify a default value (as a String)' do
      @schema.timestamp :created_at, :default => 'Wed Oct 20 16:59:37 +0400 2010'
      @schema.attrs.first.default.should == 1287579577
    end

    it 'allows to specify a default value (as an Integer)' do
      @schema.timestamp :created_at, :default => 1287579577
      @schema.attrs.first.default.should == 1287579577
    end

  end

end