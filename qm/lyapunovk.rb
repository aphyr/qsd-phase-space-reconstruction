module QM
  class Lyapunovk < Sequel::Model
    include Data
   
    set_schema do
      primary_key :id
      column :delay, :integer
      column :dimension, :integer
      column :theiler, :integer
      foreign_key :series_id, :table => :series
    end

    belongs_to :series

    # Remove data file on destruction
    after_destroy do
      if File.exists? path
        File.delete path
      else
        puts "#{path} already gone, not deleting."
      end
    end

    # Actually perform the computation.
    def run
      stddev = series.stddev
      QM.run('lyap_k',
        '-m', dimension, 
        '-M', dimension,
        '-d', delay,
        '-c', series.data_column,
        #'-r', stddev / 10000,
        #'-R', stddev / 1000,
        '-s', '300',
        '-o', path,
        '-t', theiler,
        series.path
      )
    end

    def to_s
      series.to_s + " lyapunov (k) d=#{delay} m=#{dimension} t=#{theiler}"
    end
  end
end
