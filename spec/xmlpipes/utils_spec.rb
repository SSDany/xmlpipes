require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Utils do

  describe '.bool' do

    it 'typecasts nil to 0 (false)' do
      XMLPipes::Utils.bool(nil).should == 0
    end

    it 'typecasts false to 0 (false)' do
      XMLPipes::Utils.bool(false).should == 0
    end

    it 'typecasts 0 to 0 (false)' do
      XMLPipes::Utils.bool(0).should == 0
    end

    it 'typecasts true to 1 (true)' do
      XMLPipes::Utils.bool(true).should == 1
    end

    it 'typecasts "not false" (String) to 1 (true)' do
      XMLPipes::Utils.bool('not false').should == 1
    end

    it 'typecasts 1 to 1 (true)' do
      XMLPipes::Utils.bool(1).should == 1
    end

  end

  describe '.float' do

    it 'typecasts nil to 0.00' do
      XMLPipes::Utils.float(nil).should == 0.00
    end

    it 'typecasts "42.00" to 42.00' do
      XMLPipes::Utils.float('42.00').should == 42.00
    end

    it 'typecasts 42.00 to 42.00' do
      XMLPipes::Utils.float(42.00).should == 42.00
    end

  end

  describe '.timestamp' do

    it 'typecasts an instance of the Time to the UNIX timestamp' do
      XMLPipes::Utils.timestamp(Time.at(1287579577)).
      should == 1287579577
    end

    it 'attempts to typecast an instance of the DateTime to the UNIX timestamp' do
      XMLPipes::Utils.timestamp(DateTime.parse('Wed Oct 20 16:59:37 +0400 2010')).
      should == 1287579577
    end

    it 'attempts to typecast a ~to_time object to the UNIX timestamp' do
      XMLPipes::Utils.timestamp(mock(:to_time, :to_time => Time.at(1287579577))).
      should == 1287579577
    end

    it 'attempts to typecast an instance of the String to the UNIX timestamp' do
      XMLPipes::Utils.timestamp('Wed Oct 20 16:59:37 +0400 2010').
      should == 1287579577
    end

    it 'attempts to typecast an Integer to the UNIX timestamp' do
      XMLPipes::Utils.timestamp(1287579577).
      should == 1287579577
    end

    it 'attempts to typecast a Float to the UNIX timestamp' do
      XMLPipes::Utils.timestamp(1287579577.99999999).
      should == 1287579578
    end

  end

  describe '.multi' do

    it 'typecasts nil to "0"' do
      XMLPipes::Utils.multi(nil).should == '0'
    end

    it 'typecasts false to "0"' do
      XMLPipes::Utils.multi(false).should == '0'
    end

    it 'typecasts true to "1"' do
      XMLPipes::Utils.multi([true]).should == '1'
    end

    it 'typecasts "query" to "616412651" (CRC32)' do
      XMLPipes::Utils.multi('query').should == '616412651'
    end

    it 'typecasts 42 to "42"' do
      XMLPipes::Utils.multi([42]).should == '42'
    end

    it 'typecasts an instance of Time to the stringified integer' do
      now = Time.now
      XMLPipes::Utils.multi(now).should == now.to_i.to_s
    end

    it 'is able to handle an Array (and typecast each value)' do
      XMLPipes::Utils.multi(%w(an array of values)).
      should == '2536834118,2701979319,124625402,984042726'
      XMLPipes::Utils.multi([2536834118,2701979319,124625402,984042726]).
      should == '2536834118,2701979319,124625402,984042726'
    end

  end

  describe '.int' do

    it 'raises a RangeError when called with check_bits = true and value is greater than allowed' do
      lambda { XMLPipes::Utils.int(42, 2, true) }.should raise_error RangeError
      lambda { XMLPipes::Utils.int(2**32, 32, true) }.should raise_error RangeError
    end

  end

  describe '.str2ordinal'

end