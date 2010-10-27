class Table
  class IDMaker
    def initialize
      @id = 1
    end

    def allocate_id
      id = @id
      @id += 1
      id
    end
  end
end
