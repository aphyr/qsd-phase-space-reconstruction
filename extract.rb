#!/usr/bin/ruby

require 'qm'

class String
  def num
    sub('p', '.').to_f
  end
end

gammas = [0.125, 0.2, 0.21, 0.22, 0.3]
gammas.each do |gamma|
  dir = "gamma_#{gamma}"
  Dir.entries(dir).each do |file|
    if file =~ /beta_([\dp]+)/
      path = File.join(dir, file)
      puts path

      beta = $1.num

      observable = 'X'

      if File.exist?('X.out')
        puts "Hey, we're going to overwrite a file here called X.out. Hit ctrl-c to cancel!"
        $stdin.gets
      end

      `tar xvfj #{path} X.out`
      last_time = `tail -n 1 X.out`.split(/\s/).first.num
  
      time = 450..last_time

      mod = 1
  
      dest = QM::Series.create(
        :gamma => gamma,
        :beta => beta,
        :observable => observable,
        :ti => time.min,
        :tf => time.max,
        :mod => mod
      ).path

      File.open(dest, 'w') do |out|
        File.open('X.out').each do |line|
          if line.split(' ').first.to_f >= 450
            out.write line
          end
        end
      end

      File.delete 'X.out'
    end
  end
end
