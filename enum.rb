#!/usr/bin/ruby

require 'qm/enumerable'

[1,2,3,4,5,6,7,8].threaded_each do |i|
  puts "Computing #{i}"
  sleep 2
  puts "Done with #{i}"
end
