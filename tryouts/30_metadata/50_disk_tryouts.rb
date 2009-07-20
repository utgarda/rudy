rudy_lib_path = File.expand_path(File.join(GYMNASIUM_HOME, '..', 'lib'))
library :rudy, rudy_lib_path

group "Metadata"

test_domain = 'test_' #<< Rudy::Utils.strand
test_env = 'env_' << Rudy::Utils.strand

tryout "Disk API" do
  
  setup do
    Rudy.enable_debug
    Rudy::Huxtable.global.offline = true
    Rudy::Huxtable.update_config          # Read config files
    global = Rudy::Huxtable.global
    global.environment = test_env
    akey, skey, region = global.accesskey, global.secretkey, global.region
    Rudy::Metadata.connect akey, skey, region
  end
  
  clean do
    if Rudy.debug?
      puts $/, "Rudy Debugging:"
      Rudy::Huxtable.logger.rewind
      puts Rudy::Huxtable.logger.read
    end
  end
  
  xdrill "can create test domain (#{test_domain})" do
    Rudy::Metadata.create_domain test_domain
  end
  
  
  dream :class, Rudy::Disk
  dream :name do
    tmp  = [Rudy::Huxtable.global.zone, Rudy::Huxtable.global.environment]
    tmp += [Rudy::Huxtable.global.role, '01']
      # disk-us-east-1b-env_xxxxxx-app-01-rudy-disk
    ['disk', tmp].join(Rudy::DELIM)
  end
  drill "can create disk object for root path" do
    Rudy::Disk.new('/')
  end
  
  dream :name, do
    tmp  = [Rudy::Huxtable.global.zone, Rudy::Huxtable.global.environment]
    tmp += [Rudy::Huxtable.global.role, '01']
      # disk-us-east-1b-env_xxxxxx-app-01-any-path
    ['disk', tmp, 'any', 'path'].join(Rudy::DELIM)
  end
  drill "can create disk object for an arbitrary path" do
    Rudy::Disk.new('/any/path')
  end
  
  dream :size, 1
  dream :device, '/dev/sdh'
  dream :path, '/'
  drill "has a default size and device" do
    Rudy::Disk.new('/')
  end
  
  dream :exception, ArgumentError
  drill "will fail if given no path" do
    Rudy::Disk.new
  end
  
  xdrill "save disk metadata", true do
    Rudy::Disk.new('/any/path').save
  end
  
  dream :exception, Rudy::Metadata::DuplicateRecord
  xdrill "won't save over a disk with the same name" do
    Rudy::Disk.new('/any/path').save
  end
  
  xdrill "will save over a disk with the same name if forced", true do
    Rudy::Disk.new('/any/path').save(:replace)
  end
  
  dream :class, Rudy::Disk
  xdrill "get disk metadata" do
    Rudy::Disk.get '/any/path'
  end
  
  dream :class, Rudy::Disk
  dream :mounted, false
  xdrill "refresh disk metadata" do
    d = Rudy::Disk.new('/any/path')
    d.mounted = true
    d.refresh
    d
  end
  
  dream false
  xdrill "create disk instance with volume" do
    disk = Rudy::Disk.new '/sergeant/disk'
    disk.create
    stash :awsid, disk.awsid
    disk.awsid.nil?
  end
  
  xdrill "refresh disk" do
    disk = new_disk('/sergeant/disk', test_env)
    disk.refresh
    disk.awsid
  end
  
  xdrill "knows about the state of the volume" do
    disk = new_disk('/sergeant/disk', test_env)
    disk.refresh
    [disk.exists?, disk.attached?, disk.in_use?]
  end
  
  xdrill "destroy disk with volume" do
    disk = new_disk('/sergeant/disk', test_env)
    disk.update
    disk.destroy
  end
  
  xdrill "destroy a domain (#{test_domain})" do
    Rudy::Metadata.destroy_domain test_domain
  end
  
end


