require File.expand_path File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

# source: ActiveSupport

describe File, '.atomic_write' do

  before(:all) do
    @atomic = 'atomic.file'
  end

  after(:each) do
    File.unlink(@atomic) rescue nil
  end

  it 'writes without errors' do
    contents = 'Atomic Text'
    File.atomic_write(@atomic, Dir.pwd) do |file|
      file.write(contents)
      File.should_not exist(@atomic)
    end
    File.should exist(@atomic)
    File.read(@atomic).should == contents
  end

  it 'does not write when block raises' do
    begin
      File.atomic_write(@atomic) do |file|
        file.write('testing')
        raise 'something bad'
      end
    rescue Exception => exception
      exception.message.should == 'something bad'
      File.should_not exist(@atomic)
    end
  end

  it 'preservers file permissions' do
    contents = "Atomic Text"
    File.open(@atomic, "w", 0755) do |file|
      file.write(contents)
      File.should exist(@atomic)
    end
    File.should exist(@atomic)
    File.stat(@atomic).mode.should == 0100755
    File.read(@atomic).should == contents

    File.atomic_write(@atomic, Dir.pwd) do |file|
      file.write(contents)
      File.should exist(@atomic)
    end
    File.should exist(@atomic)
    File.stat(@atomic).mode.should == 0100755
    File.read(@atomic).should == contents
  end

  it 'preserves default file permissions' do
    contents = "Atomic Text"
    File.atomic_write(@atomic, Dir.pwd) do |file|
      file.write(contents)
      File.should_not exist(@atomic)
    end
    File.should exist(@atomic)
    File.stat(@atomic).mode.should == 0100666 ^ File.umask
    File.read(@atomic).should == contents
  end

end