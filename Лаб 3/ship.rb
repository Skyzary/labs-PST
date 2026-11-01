# frozen_string_literal: true

require 'set'

module Battleship
  class Ship
    attr_reader :size, :coordinates, :hits

    def initialize(coordinates)
      @coordinates = coordinates.dup.freeze
      @size = @coordinates.size
      @hits = Set.new
    end

    # Зафіксувати влучання в клітинку
    def register_hit(coord)
      @hits.add(coord) if @coordinates.include?(coord)
    end

    # Чи потоплений корабель
    def sunk?
      @hits.size >= @size
    end

    # Чи займає корабель дану координату
    def occupies?(coord)
      @coordinates.include?(coord)
    end
  end
end
