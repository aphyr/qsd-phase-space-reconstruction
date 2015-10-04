module QM
  module Data
    def self.included(base)
      base.class_eval do
        unrestrict_primary_key

        # Load all series from disk 
        def self.load_from_disk
          # Wipe DB
          create_table!
          
          Dir.entries(QM::DATA_ROOT).each do |file| 
            if file =~ /\.#{self.to_s.demodulize.downcase}$/
              from_path(file).save 
            end 
          end

          true 
        end

        def self.from_path(path)
          params = {}
          
          if path =~ /\.#{self.to_s.demodulize.downcase}$/
            path.gsub!(/\.#{self.to_s.demodulize.downcase}$/, '')
          else
            raise RuntimeError.new("#{path} is not a #{self.class}.")
          end

          fragments = File.split(path).last.split(' ')

          fragments.each do |fragment|
            key, value = fragment.split(':')
            params[key.intern] = YAML::load(value)
          end

          data = self.new params
          data
        end
      end
    end 

    # Returns a filename for this series, unique in the parameter space.
    def filename
      parts = []
      columns.each do |key|
        unless (value = self[key]).nil?
          case value
          when BigDecimal
            value = value.to_s('F')
          else
            value = YAML::dump(value).gsub(/^---\s*/, '').strip
          end
          parts << key.to_s + ':' + value
        end
      end
      parts.join(' ') + '.' + self.class.to_s.demodulize.downcase
    end

    # Returns the full path to the file for this series
    def path
      File.join(QM::DATA_ROOT, filename)
    end

    # Plot with gnuplot
    def plot(opts = {})
      defaults = {
        :output => File.join(PLOT_ROOT, filename + '.png'),
        :title => to_s,
        :with => 'dots'
      }
      opts = defaults.merge(opts)

      Plot.new(Plotter.quote(path), opts) 
    end
  end
end
