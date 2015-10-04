module QM
  class Poincare < Sequel::Model
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
      File.delete path
    end

    # Actually perform the computation.
    def run
      QM.run('lyap_r',
        '-m', dimension, 
        '-d', delay,
        '-c', 2,
        '-o', path,
        series.path
      )
    end

    def to_s
      series.to_s + " lyapunov (r) d=#{delay} m=#{dimension}"
    end
  end
end
