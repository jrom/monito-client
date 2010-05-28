#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'net/http'
require 'uri'
require 'yaml'


@config = YAML.load(File.join(File.dirname(__FILE__), "config.yml"))

def os
  return "darwin" if RUBY_PLATFORM =~ /darwin/
  return "linux" if RUBY_PLATFORM =~ /linux/
  return "windows" if RUBY_PLATFORM =~ /mswin32/
end


def mem
  # Fetch mem
  if os == "darwin"
    cmd = "top -l 1 | grep PhysMem"
    ans = `#{cmd}`
    ans = ans.match(/(\d+)M wired, (\d+)M active, (\d+)M inactive, (\d+)M used, (\d+)M/).to_a
    # 1 = wired 2 = active 3 = inactive 4 = used = 1+2+3 5 = free
    [ans[1].to_i + ans[2].to_i, ans[5].to_i + ans[4].to_i]
  elsif os == "linux"
    cmd = "free -m"
    ans = `#{cmd}`
    ans = ans.split("\n")
    [ans[2].split(" ")[2].to_i, ans[1].split(" ")[1].to_i]
  else
    [0,0]
  end
end

def loadavg
  if os == "darwin"
    cmd = "uptime"
    ans = `#{cmd}`
    ans = ans.gsub(",",".").split(" ")
    [ans[-3].to_f, ans[-2].to_f, ans[-1].to_f]
  elsif os == "linux"
    cmd = "uptime"
    ans = `#{cmd}`
    ans = ans.gsub(",","").split(" ")
    [ans[-3].to_f, ans[-2].to_f, ans[-1].to_f]
  else
    [0.0,0.0,0.0]
  end
end

# Fetch Load avg

# Fetch Disk

# Fetch Networking

def fetch_data
  _mem = mem
  _loadavg = loadavg
  {
    :server => "#{@config["server"]}",
    :key => "#{@config["key"]}",
    :data => {
    :mem => _mem.to_json,
    :loadavg => _loadavg.to_json
  }}.to_json
end

# Send data to the server

begin
  res = Net::HTTP.post_form(URI.parse("http://#{@config["auth"]}#{@config["host"]}/data"),fetch_data)
  puts res.body
rescue Errno::ECONNREFUSED
  puts "No connection"
end
