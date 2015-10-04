#!/usr/bin/ruby

# Generate delay embeddings for all series.

require File.dirname(__FILE__) + '/qm'

include QM

Series.interesting.each do |series|
  series.delays_dataset.filter(:dimension => 2).each do |delay|
    puts "Plotting #{delay}"
    delay.plot
  end
end
