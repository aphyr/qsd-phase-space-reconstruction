#!/usr/bin/ruby

require 'qm'

class String
  def num
    sub('p', '.').to_f
  end
end

ARGV.each do |file|
  file =~ /gamma_([p\d]+)/
  gamma = $1.num

  file =~ /beta_([p\d]+)/
  beta = $1.num

  observable = 'X' if file['_X_']
  observable = 'P' if file['_P_']
  
  file =~ /_t(\d+)_t(\d+)/
  time = $1.to_i .. $2.to_i

  file =~ /mod(\d+)/
  mod = $1.to_i

  File.rename file, QM::Series.create(
    :gamma => gamma,
    :beta => beta,
    :observable => observable,
    :ti => time.min,
    :tf => time.max,
    :mod => mod
  ).path
end
