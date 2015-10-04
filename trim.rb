#!/usr/bin/ruby

# Trim a file to start at 450

require 'qm'

class String
  def num
    sub('p', '.').to_f
  end
end

File.open(ARGV[1], 'w') do |out|
  File.open(ARGV[0]).each do |line|
    if line.split(' ').first.to_f >= 450
      out.write line
    end
  end
end
