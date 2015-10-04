module QM
  class Series < Sequel::Model
    include Data

    # Indexing attributes
    set_schema do
      primary_key :id
      column :gamma, :double
      column :beta, :double
      column :observable, :varchar
      column :mod, :integer
      column :ti, :double
      column :tf, :double
      column :smooth, :boolean, :null => true, :default => nil
      column :smooth_window, :integer
    end

    has_many :delays
    has_many :lyapunovrs
    has_many :lyapunovks

    # Remove associated data before destruction
    before_destroy do
      delays.each     do |delay| delay.destroy end
      lyapunovrs.each do |lyap| lyap.destroy end
      lyapunovks.each do |lyap| lyap.destroy end
    end

    # Remove data file on destruction
    after_destroy do
      if File.exists? path
        File.delete path
      else
        puts "#{path} already gone, not deleting."
      end 
    end

    # Subsets
    subset(:interesting, :beta => [0.01, 0.1, 0.3, 0.7, 1])
#    subset(:interesting, :beta => [0.01, 0.3, 1])
#    subset :interesting, :id
    subset(:smooth, :smooth => true)
    subset(:raw, '`smooth` is unknown or smooth is false')
    subset(:flow, :mod => 1)
    subset(:strobe, :mod > 1)

    attr_accessor :lock

    # Returns the column to analyze
    def data_column
      columns = nil
      #puts "Checking columns for #{self}"
      File.open(path) do |f|
        columns = f.gets.split(/\s/)
      end

      if columns.size == 1
        1
      else
        2
      end
    end

    # Compute or look up a specific delay. If more than one delay for opts is
    # available, returns the first available.
    def delay(opts = {})
      if existing = Delay.filter(:series_id => id).filter(opts).first
        # We have an existing delay for these parameters
        existing
      else
        # Create a new delay
        delay = Delay.create(opts)
        add_delay delay
        
        # Run the computation
        delay.run
      
        delay
      end
    end

    # Gives the average difference between two points in time.
    def interval
      if data_column == 1
        1
      else
        t0 = nil
        lines = 0
        line = ''
        File.open(path).each do |line|
          t0 ||= line.split(/\s/).first.to_f
          lines += 1
        end
        dt = line.split(/\s/).first.to_f - t0
        dt / lines
      end
    end

    # Compute or look up a specific lyapunov_r. If more than one delay for opts
    # is available, returns the first available.
    def lyapunovr(opts = {})
      if existing = Lyapunovr.filter(:series_id => id).filter(opts).first
        # We have an existing delay for these parameters
        existing
      else
        # Create a new delay
        lyapunovr = Lyapunovr.create(opts)
        add_lyapunovr lyapunovr
        
        # Run the computation
        lyapunovr.run
      
        lyapunovr
      end
    end

    # Compute or look up a specific lyapunov_k. If more than one delay for opts
    # is available, returns the first available.
    def lyapunovk(opts = {})
      if existing = Lyapunovk.filter(:series_id => id).filter(opts).first
        # We have an existing delay for these parameters
        existing
      else
        # Create a new delay
        lyapunovk = Lyapunovk.create(opts)
        add_lyapunovk lyapunovk
        
        # Run the computation
        lyapunovk.run
      
        lyapunovk
      end
    end

    def lyap_spec(dim, iter)
      QM.run('lyap_spec', '-m1,' + dim.to_s, '-c2', '-n', iter, path)
    end

    def lyapunov_plot(filter = {})
      sets = lyapunovks_dataset
      sets = sets.filter(filter) unless filter.empty?
      sets = sets.order(:delay, :dimension)
      i = 0
      sets = sets.all.map { |l|
        i += 1
        "#{Plotter.quote(l.path)} using ($1*#{interval}):2 title #{Plotter.quote('m=' + l.dimension.to_s)} with lines lt 1 lc #{i}";
      }.join(", ")

      Plot.new(sets,
        :yrange => '[-6:0]',
        :title => "({/Symbol G}=#{gamma}, {/Symbol b}=#{beta})",
        :xlabel => "'t'",
        :ylabel => "'S({/Symbol e}, m, t)'",
        :key => 'right bottom',
        :output => File.join(PLOT_ROOT, filename + ' ' + filter.inspect + '.png')
      )
    end

    def resample(mod, ti, precision = 0.01)
      opts = @values.merge({:mod => mod, :ti => ti})
      opts.delete :id

      if existing = Series.filter(opts).first
        # Already exists
        return existing
      else
        # Create a resampled copy
        sampled = Series.create(opts)

        data_column = self.data_column
        time_column = self.data_column - 1

        time_column = 0

        puts "Sampling #{self}"
        File.open(sampled.path, 'w') do |outfile|
          File.open(path) do |infile|
            if time_column == 0
              i = 0
              # Time is implicitly in steps
              while line = infile.gets
                if (i - ti) % mod < precision
                  outfile << line
                end
                i += 1
              end
            else
              # Time is explicitly labeled
              while line = infile.gets
                time = line.split(/\s/).first.to_f
                if (time - ti) % mod == 0
                  outfile << line
                end
              end
            end
          end
        end
      end

      sampled
    end

    def smooth?
      if self[:smooth]
        true
      else
        false
      end
    end

    def smooth(opts = {})
      opts = @values.merge opts
      opts[:smooth] = true
      opts[:smooth_window] ||= 20
      opts.delete :id

      if existing = Series.filter(opts).first
        # We have an existing smoothed series
        return existing
      else
        # Create a smooth copy.
        new_series = Series.create(opts)

        cmd = ['sav_gol']
        if win = new_series.smooth_window
          cmd += ['-n', "#{win},#{win}"]
        end
        cmd += [
          '-c', data_column, 
          '-m', 1,
          '-o', new_series.path + '.tmp',
          path
        ]

        QM.run *cmd

        if data_column > 1
          # Copy coordinates
          puts "Copying times"
          File.open(path) do |old|
            File.open(new_series.path + '.tmp') do |smooth|
              File.open(new_series.path, 'w') do |out|
                while new_line = smooth.gets
                  old.gets =~ /([^\s]+)\s/
                  out.puts "#{$1} #{new_line}"
                end
              end
            end
          end
        end

        # Delete tmpfile
        File.delete new_series.path + '.tmp'

        return new_series
      end
    end

    def stddev
      # ARRRGH HACK cuz fortran doesn't like spaces
      if @my_cached_stddev
        @my_cached_stddev
      else
        f = File.join('/tmp', 'qm' + '-' + Process.pid.to_s + '-' + hash.to_s + '-' + rand(10000).to_s)
        QM.run('ln', '-s', File.expand_path(path), f)
        out = QM.run('rms', '-c', data_column, f)

        @my_cached_stddev = out.split("\n").last.strip.split(/\s+/)[1].to_f
      end
    end

    def to_s
      s = "#{observable} g=#{gamma} b=#{beta}"
      if smooth?
        s << " (smooth win=#{smooth_window})"
      end
      s
    end
  end
end
