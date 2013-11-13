#################################################################################
# Description: This file provides a puppet package provider for homebrew on Mac
# Author: Patrick.Debois@jedi.be
# URL: http://jedi.be/blog
#################################################################################

# Information on how to embed a provider in a module : lib/puppet/provider/package/homebrew.rb
# http://blkperl.blogspot.com/2010/07/provider-errors.html

require 'puppet/provider/package'

Puppet::Type.type(:package).provide :homebrew, :parent => Puppet::Provider::Package do
  desc "Package management using homebrew on OS X."

  has_feature :install_options

  confine :operatingsystem => :darwin
  if Puppet::Util::Package.versioncmp(Puppet.version, '3.0') >= 0
    has_command(:brewcmd, "/usr/local/bin/brew") do
      environment({ 'HOME' => ENV['HOME'] })
    end
  else
    commands :brewcmd => "/usr/local/bin/brew"
  end

  def self.brewlist(hash)
    command = [command(:brewcmd), "list","--versions"]

    if name = hash[:justme]
      command << name
    end
    
   begin
       list = execute(command, :custom_environment => {'HOME'=>ENV['HOME']}).split("\n").collect do |set|
         if brewhash = brewsplit(set)
           brewhash[:provider] = :brew
           brewhash
         else
           nil
         end
       end.compact
     rescue Puppet::ExecutionFailure => detail
       raise Puppet::Error, "Could not list brews: #{detail}"
     end
     
     if hash[:justme]
       return list.shift
     else
       return list
     end

  end

  def install_options
    Array(resource[:install_options]).flatten.compact
  end

  def self.brewsplit(desc)
      split_desc=desc.split(/ /)
      name=split_desc[0]
      version=split_desc[split_desc.size-1]
      if (name.nil? || version.nil?)
           Puppet.warning "Could not match #{desc}"
           nil
      else
	      return {
          :name => name,
          :ensure => version
        }
      end 
  end

  def self.instances
    brewlist(:local => true).collect do |hash|
      new(hash)
    end
  end

  def install
    should = @resource.should(:ensure)

    if install_options.any?
      output = brewcmd "install", @resource[:name], *install_options
    else
      output = brewcmd "install", @resource[:name]
    end

    if output =~ /^Error: No available formula/
      raise Puppet::ExecutionFailure, "Could not find package #{@resource[:name]}"
    end
  end

  def query
    version = nil
    self.class.brewlist(:justme => resource[:name]) 
  end

  def latest
    info = brewcmd :info, "#{@resource[:name]}"

    if $CHILD_STATUS != 0 or info =~ /^Error/
      return nil
    end
    version=info.split("\n")[0].split(" ")[1]
    version
  end

  def uninstall
    brewcmd :remove,"--force", @resource[:name]
  end

  def update
    #when you reinstall you get the latest version
    install
  end
end

