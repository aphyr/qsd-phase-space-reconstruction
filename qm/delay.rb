module QM
  class Delay < Sequel::Model
    include Data
   
    set_schema do
      primary_key :id
      column :delay, :integer
      column :dimension, :integer
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
      QM.run('delay', 
        '-m', dimension, 
        '-d', delay,
        '-c', series.data_column,
        '-o', path,
        series.path
      )
    end

    def to_s
      series.to_s + " delay embedding d=#{delay} m=#{dimension}"
    end
  end
end
