require 'spec_helper'

describe Fstab do

  before :each do
    @fake_fstab =  "/tmp/fstab.#{Time.now.to_f}.fake"
    File.open @fake_fstab, 'w' do |f|
      f.puts ""
    end

    @real_fstab = "/tmp/fstab.#{Time.now.to_f}.real"
    File.open @real_fstab, 'w' do |f|
      f.puts File.read('/etc/fstab')
    end
  end

  after :each do
    File.delete @fake_fstab
    File.delete @real_fstab
    Dir["/tmp/fstab*.bak"].each do |f|
      File.delete f
    end
  end

  describe "#new" do
    it "accepts two optional arguments" do
      h = Fstab.new '/etc/fstab', {}
    end
    
    it "raises exception unless opts is not Hash" do
      lambda { Fstab.new(@real_fstab, false) }.should raise_error NoMethodError
    end

    it "accepts no arguments" do
      h = Fstab.new
    end

    it "raises exception if file does not exist" do
      lambda { Fstab.new('/tmp/lkjsdfouwoiue') }.should raise_exception(Errno::ENOENT)
    end
    
    it "reads custom #{@fake_fstab}" do
      h = Fstab.new @fake_fstab
      h.instance_variable_get(:@contents).strip.chomp.should be_empty 
    end

    it "has backups enabled by default" do
      h = Fstab.new @fake_fstab
      h.instance_variable_get(:@backup).should be_true
    end

  end

  describe "#parse" do
    it "should count lines" do
      count = File.read('/etc/fstab').lines.count
      f = Fstab.new(@real_fstab); f.parse
      f.line_count.should be count
    end

    it "should return empty Hash if empty" do
      Fstab.new(@fake_fstab).parse.should be_empty
    end
    it "should have 1 special FS" do
      File.open @fake_fstab, 'w+' do |f|
        f.puts 'proc            /proc           proc    nodev,noexec,nosuid 0       0'
        f.flush
        fstab = Fstab.new @fake_fstab
        devs = fstab.parse
        devs.count.should == 1
        # d[:special] == true
        devs.first.last[:special].should == true
      end
    end

    it "should detect special filesystems as valid" do
      File.open @fake_fstab, 'w+' do |f|
        f.puts 'proc            /proc           proc    nodev,noexec,nosuid 0       0'
        f.flush
        fstab = Fstab.new @fake_fstab
        devs = fstab.parse
        devs.count.should == 1
        devs.first.last[:invalid].should == false
      end
    end
    
    it "should detect invalid dump/pass columns" do
      File.open @fake_fstab, 'w+' do |f|
        f.puts 'proc            /proc           proc    nodev,noexec,nosuid a b'
        f.flush
        fstab = Fstab.new @fake_fstab
        devs = fstab.parse
        devs.count.should == 1
        devs.first.last[:invalid].should == true
      end
    end

    it "should detect invalid filesystems" do
      File.open @fake_fstab, 'w+' do |f|
        f.puts '/dev/foobar /tmp/bar           xfs    defaults 0       0'
        f.flush
        fstab = Fstab.new @fake_fstab
        devs = fstab.parse
        devs.count.should == 1
        devs.first.last[:invalid].should == true
        f.puts 'weird_entry foo bar'
        f.flush
        devs = fstab.parse
        devs.count.should == 2
        devs.each do |k,v|
          v[:invalid].should == true
        end
      end
    end
    
    it "should parse valid UUID entries" do
      pdev, uuid, label, type = get_first_blkid
      File.open @fake_fstab, 'w+' do |f|
        f.puts  "UUID=74bc785f-1024-4779-80a1-7a1e0619ad26 /srv/node/74bc785f-1024-4779-80a1-7a1e0619ad26 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0"
      end
      fstab = Fstab.new @fake_fstab
      fstab.parse.count.should == 1
    end
  end

  describe "#add_fs" do
    it "should raise an exception adding a non existing device" do
      f = Fstab.new(@real_fstab)
      lambda {f.add_fs '/dev/fff', '/foo/bar', 'xfs', 'defaults'}.should \
        raise_error /Invalid device path/
    end
    it "should raise an exception adding a non existing dev label" do
      f = Fstab.new(@real_fstab)
      lambda {f.add_fs 'my-foo-fs', '/foo/bar', 'xfs', 'defaults'}.should \
        raise_error /Unsupported filesystem/
    end
    it "should raise an exception adding a non existing dev uuid" do
      f = Fstab.new(@real_fstab)
      lambda {f.add_fs 'ca803c3f-32e6-423e-994a-52f648a0321d', '/foo/bar', 'xfs', 'defaults'}.should \
        raise_error /Invalid device UUID/
    end
    it "should raise an exception adding a non existing dev label" do
      f = Fstab.new(@real_fstab)
      lambda {f.add_fs 'my-foo-fs', '/foo/bar', 'xfs', 'defaults'}.should \
        raise_error /Unsupported filesystem/
    end

    it "should add invalid device when safe_mode=false" do
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup_dir => '/tmp')
      f.add_fs '/dev/foo_dev', '/foo/bar', 'xfs', 'defaults'
      f.invalid_entries.count.should == 1
    end

    it "should create a backup when backup=true (default)" do
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup_dir => '/tmp')
      f.add_fs '/dev/foo_dev', '/foo/bar', 'xfs', 'defaults'
      Dir["/tmp/fstab*.bak"].count.should == 1
    end
    
    it "should NOT create a backup when backup=false" do
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup => false, :backup_dir => '/tmp')
      f.add_fs '/dev/foo_dev', '/foo/bar', 'xfs', 'defaults'
      Dir["/tmp/fstab*.bak"].count.should == 0
    end

    it "should add a valid special FS entry" do
      f = Fstab.new(@fake_fstab, :backup => false, :backup_dir => '/tmp')
      prev_count = f.parse.count
      f.add_fs 'tmpfs', '/foo/bar', 'tmpfs', 'size=1024', '0', '0'
      f.parse.count.should == prev_count + 1
      File.read(@fake_fstab).should match /^tmpfs/m
    end
    
    it "should add a FS UUID" do
      f = Fstab.new(@fake_fstab, :safe_mode => true, :backup => false, :backup_dir => '/tmp')
      pdev, uuid, label, type = get_first_blkid
      f.add_fs uuid, '/foo/bar', type, 'defaults', '0', '0'
      File.read(@fake_fstab).should match /^UUID=#{uuid}/m
    end
    
    it "should add a FS UUID when using a blockdev" do
      f = Fstab.new(@fake_fstab, :safe_mode => true, :backup => false, :backup_dir => '/tmp')
      pdev, uuid, label, type = get_first_blkid
      f.add_fs pdev, '/foo/bar', type, 'defaults', '0', '0'
      File.read(@fake_fstab).should match /^UUID=#{uuid}/m
    end

    it "should raise error when adding duplicated entry and safe_mode=true" do
      f = Fstab.new(@fake_fstab, :backup => false, :backup_dir => '/tmp')
      pdev, uuid, label, type = get_first_blkid
      f.add_fs uuid, '/foo/bar', type, 'defaults', '0', '0'
      lambda {f.add_fs uuid, '/foo/bar', type, 'defaults', '0', '0'}.should raise_error /Duplicated entry found/
      lambda {f.add_fs pdev, '/foo/bar', type, 'defaults', '0', '0'}.should raise_error /Duplicated entry found/
    end
  end

  describe "#add_entry" do
    it "should raise an exception when missing mount_point/type/opts,dump,pass" do
      f = Fstab.new(@real_fstab)
      opts = {
        :dev => '/dev/sda',
        :mount_point => '/foo/bar',
        :type => 'xfs',
        :opts => 'defaults',
        :dump => 0,
        :pass => 0
      }
      [:mount_point, :type, :opts, :dump, :pass].each do |s|
        dup_opts = opts.dup; dup_opts.delete s
        lambda {f.add_entry dup_opts}.should \
          raise_error /Missing :mount_point, :type, :opts/
      end
    end

    it "should raise and exception when dev/uuid/label nil" do
      f = Fstab.new(@real_fstab)
      opts = {
        :mount_point => '/foo/bar',
        :type => 'xfs',
        :opts => 'defaults',
        :dump => 0,
        :pass => 0
      }
      lambda {f.add_entry opts}.should \
        raise_error /:dev key is required/
    end
  end
  
  describe "#invalid_entries" do
    it "should return one entry" do
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup => false, :backup_dir => '/tmp')
      f.add_fs '/dev/foo_dev', '/foo/bar', 'xfs', 'defaults'
      f.invalid_entries.count.should == 1
    end
  end
  
  describe "#valid_entries" do
    it "should only return valid entries" do
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup => false, :backup_dir => '/tmp')
      f.add_fs '/dev/foo_dev', '/foo/bar', 'xfs', 'defaults'
      lcount = File.read(@real_fstab).lines.find_all do |l| 
        (l.strip.chomp !~ /^#/) and !l.strip.chomp.empty?
      end.count
      f.valid_entries.count.should == lcount - 1
    end

    it "should match the number of devices" do
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup => false, :backup_dir => '/tmp')
      f.valid_entries.count.should == f.parse.count
    end
  end

  describe "#remove_invalid_entries" do
    it "should remove 1 entry" do
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup => false, :backup_dir => '/tmp')
      prev_count = f.parse.count
      f.add_fs '/dev/foo_dev', '/foo/bar', 'xfs', 'defaults'
      f.remove_invalid_entries.should == true
    end
  end

  describe "#find_device" do
    it "should return nil if device not found" do
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup => false, :backup_dir => '/tmp')
      f.find_device('/alksjdflkjsd').should be_nil
    end

    it "should return a valid device if device is defined" do
      pdev, uuid, label, type = get_first_blkid
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup => false, :backup_dir => '/tmp')
      f.add_fs pdev, '/foo/bar', type, 'defaults'
      f.find_device(pdev).should be_a Hash
      k, dev = f.find_device(pdev).first
      dev.should_not be_nil
      k.should match pdev
      dev[:mount_point].should match '/foo/bar'
    end
  end

  describe "#has_device?" do
    it "should return true if device is defined" do
      pdev, uuid, label, type = get_first_blkid
      f = Fstab.new(@fake_fstab, :safe_mode => false, :backup => false, :backup_dir => '/tmp')
      f.add_fs pdev, '/foo/bar', type, 'defaults'
      f.has_device?(pdev).should == true
      f.has_device?(uuid).should == true
    end
    it "should return true if device is defined" do
      pdev, uuid, label, type = get_first_blkid
      f = Fstab.new(@real_fstab, :safe_mode => false, :backup => false, :backup_dir => '/tmp')
      f.add_fs pdev, '/foo/bar', type, 'defaults'
      f.has_device?(pdev).should == true
    end
  end
  
  describe "get_label" do
    it "should raise exception for an invalid device" do
      lambda {Fstab.get_label('/akjsdfljaslkdj')}.should raise_error ArgumentError
    end

    it "should return a valid LABEL for device with a labeled FS" do
      pdev, uuid, label, type = get_first_blkid
      Fstab.get_label(pdev).should be_nil
      Fstab.get_uuid(pdev).should match uuid
      if label.nil?
        Fstab.get_label(pdev).should be_nil
      end
    end
  end

  describe "get_uuid" do
    it "should return a valid UUID for device with a FS" do
      pdev, uuid, label, type = get_first_blkid
      Fstab.get_uuid(pdev).should match uuid
    end
  end

end
