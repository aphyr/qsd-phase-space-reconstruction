module QM
  class Plot
    AUTO_QUOTE = [
      :output,
      :title
    ]
    
    attr_accessor :data, :with, :width, :height, :term, :opts
    def initialize(data, opts = {})
      @data = data
      @with = opts.delete :with
      @width = opts.delete(:width) || 1600
      @height = opts.delete(:height) || 1200
      @term = opts.delete :term
      @term ||= 'png'
      @opts = opts
    end

    def method_missing(meth, *args)
      if meth.to_s[-1..-1] == '=' and args.size == 1
        # Assignment passed to opts
        @opts[meth.to_s[0..-2].to_sym] = args.first
      elsif args.empty?
        # Request passed to opts
        @opts[meth]
      else
        raise NoMethodError.new("No method \"#{meth}\"")
      end
    end

    # Plot this
    def plot
      Plotter.run(to_s)
    end

    def preamble(terminal = true)
      opts = @opts.clone

      # Quote some opts automatically
      AUTO_QUOTE.each do |key|
        if value = opts[key]
          opts[key] = Plotter.quote(value)
        end
      end
      
      str = ''

      if terminal
        # Construct option strings
        # Terminal height width
        str << "set term #{@term}"
        if @term =~ /(png)|(jpeg)/
          if height and width
            str << " size #{width},#{height}"
          end
        end
        str << "\n"
      else
        # Don't try to output when no terminal exists
        opts.delete :output
      end
          
      opts.each do |key, value|
        str << "set #{key} #{value}\n"
      end

      str
    end

    def to_s(terminal = true)
      if @data.nil? or @data.empty?
        raise RuntimeError.new("Nothing to plot!")
      end

      str = preamble(terminal)

      # Plot data
      str << "plot #{@data}"
      str << " with #{@with}" if @with
      str << "\n"

      str
    end
  end

  class MultiPlot < Plot
    # Yields a block with the row and column taken from the given matrix;
    # expects a Plot back.
    def self.build(rows, cols, opts = {})
      grid = Array.new(rows.size) do |e|
        Array.new(cols.size)
      end
      
      rows.each_with_index do |row, r|
        cols.each_with_index do |col, c|
          grid[r][c] = yield(row, col)
        end
      end

      new grid, opts
    end

    def to_s
      # Compute grid dimensions
      rows = @data.size
      cols = @data[0].size
      
      # Compute maximum row and column dimensions
      #row_heights = Array.new(rows, 0)
      #col_widths = Array.new(cols, 0)
      # 
      #0.upto(rows - 1) do |r|
      #  0.upto(cols - 1) do |c|
      #    plot = @data[r][c]
      #    if row_heights[r] < plot.height
      #      row_heights[r] = plot.height
      #    end
      #    if col_widths[c] < plot.width
      #      col_widths[c] = plot.width
      #    end
      #  end
      #end
      
      #puts "column widths: #{col_widths.inspect}"
      #puts "row heights: #{row_heights.inspect}"

      #width = col_widths.inject(0) do |sum, e|
      #  sum + e
      #end

      #height = row_heights.inject(0) do |sum, e| 
      #  sum + e
      #end

      # Plot preamble
      s = preamble
      s << "set multiplot layout #{rows},#{cols} rowsfirst downwards\n"

      # Add plots
      @data.each_with_index do |row, r|
        row.each_with_index do |plot, c|
          begin
            raise "Nil plot" if plot.nil?
            height = plot.height
            width = plot.width
            term = plot.term
            plot.height = nil
            plot.width = nil
            plot.term = nil
      
            s << plot.to_s(false)

          rescue RuntimeError => e
            # Plot failure
            puts "Failed plot message: #{e.message.inspect}"
            s << Plot.new('0', :title => e.message).to_s(false)
          ensure
            plot.height = height if height
            plot.width = width if width
            plot.term = term if term
          end
        end
      end
      s << "unset multiplot\n"

      s
    end
  end

  module Plotter
    # Single-quotes a string
    def self.quote(string)
      if string
        # This ought to handle escapes appropriately... haven't dug around in
        # the gnuplot source enough to check
        string.inspect
      else
        ''
      end
    end

    # Actually makes a plot.
    def self.run(command)
      puts "Running\n\n#{command}"
      IO::popen('gnuplot -persist', 'w') do |io|
        io.puts command
        io.close
      end
    end
  end
end
