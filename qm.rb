#!/usr/bin/ruby

require 'rubygems'
require 'sequel'
require 'shell_utils'

module QM
  ROOT = File.dirname(__FILE__)
  DATA_ROOT = File.join ROOT, 'data'
  CACHE_ROOT = File.join ROOT, 'cache'
  PLOT_ROOT = File.join ROOT, 'plots'
  PROCS = 2
  
  INDEX = Sequel.connect("mysql://qm:qm@localhost/qm")

  def self.index
    INDEX
  end

  # Plot stuff
  def self.gnuplot(command)
    IO::popen('gnuplot -persist', 'w') do |io|
      io.puts command
      io.close
    end
  end

  # Reload from filenames
  def self.reload
    QM::Series.load_from_disk
    QM::Lyapunovr.load_from_disk
    QM::Lyapunovk.load_from_disk
    QM::Delay.load_from_disk
  end

  # Wrap system() with to_s for each arg, for convenience.
  def self.run(*args)
    #system *args.map { |a| a.to_s }
    ShellUtils.run *args.map { |a| a.to_s }
  end

  def self.setup
    # Ensure directories exist
    unless File.directory? DATA_ROOT
      Dir.mkdir DATA_ROOT
    end
  end


  require 'qm/enumerable'
  require 'qm/string'
  require 'qm/plotter'
  require 'qm/data'
  require 'qm/series'
  require 'qm/delay'
  require 'qm/lyapunovr'
  require 'qm/lyapunovk'
end

QM.setup
