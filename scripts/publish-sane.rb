#!/usr/bin/ruby

require 'dnssd'
require 'dbus'

class ScannerService
  attr_accessor :name, :device
    
  def initialize(name, device)
    @name = name
    @device = device
    
    @dns_service = nil
  end
  
  def announce!
    txt = DNSSD::TextRecord.new 'saned' => 'YES', 'ty' => @name, 'name' => @name, 'deviceName' => @device, 'txtvers' => 1
    
    puts "Announce '#{@name}' at '#{@device}'"
    @dns_service = DNSSD.register @name, "_sane-scanner._tcp", nil, 6566, txt
  end
  
  def unannounce!
    @dns_serivce.stop
  end
end

class SaneScannerPublisher
  attr_accessor :scanners

  def initialize
    @scanners = []
  end

  def refresh_scanners
    puts 'Refreshing scanners'
    output = `scanimage -f "%d\t%v %m%n"`
  
    @scanners.each do |s|
      s.unannounce!
    end
  
    @scanners = []
  
    output.each_line do |s|
      device, name = s.split(/\t/)
    
      s = ScannerService.new name.strip, device.strip
      s.announce!
    
      @scanners << s
    end
  end
end

publisher = SaneScannerPublisher.new
bus = DBus::SystemBus.instance

hal_service = bus.service "org.freedesktop.Hal"
manager = hal_service.object "/org/freedesktop/Hal/Manager"
manager.default_iface = 'org.freedesktop.Hal.Manager'
manager.introspect

manager.on_signal "DeviceAdded" do
  publisher.refresh_scanners
end

manager.on_signal "DeviceRemoved" do
  publisher.refresh_scanners
end

publisher.refresh_scanners
loop = DBus::Main.new
loop << bus
loop.run


