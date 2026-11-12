# frozen_string_literal: true

require 'set'
require_relative 'ship'
require_relative 'errors'

module Battleship
  class Board
    SIZE = 10
    LETTERS = ('A'..'J').to_a.freeze
    NUMBERS = (1..10).to_a.freeze

    # Символи для клітинок
    CELL_EMPTY  = '~' # Невідомо / вода
    CELL_MISS   = '•' # Промах
    CELL_HIT    = '✕' # Влучання / пошкодження
    CELL_SUNK   = '🕱' # Знищений корабель
    CELL_SHIP   = '■' # Власний непошкоджений корабель

    # Склад флоту за класичними правилами: 1x4, 2x3, 3x2, 4x1
    FLEET_SPEC = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1].freeze

    attr_reader :ships, :shots

    def initialize
      @ships = []
      @shots = {} # [row, col] => :hit | :miss
    end

    # Перевірка чи координати знаходяться в межах поля
    def self.valid_coordinate?(row, col)
      row.between?(0, SIZE - 1) && col.between?(0, SIZE - 1)
    end

    # Перетворення рядка вигляду 'A5', 'j10' на індекси [row, col]
    def self.parse_coordinate(input)
      raise InvalidCoordinateError, "Порожнє введення" if input.nil? || input.strip.empty?

      clean_input = input.strip.upcase
      match = clean_input.match(/\A([A-J])\s*([1-9]|10)\z/)
      unless match
        raise InvalidCoordinateError, "Некоректний формат координат '#{input}'. Приклад: A1, B5, J10"
      end

      letter = match[1]
      num = match[2].to_i

      row = LETTERS.index(letter)
      col = num - 1
      [row, col]
    end

    # Форматування [row, col] у читабельний вигляд, наприклад 'B5'
    def self.format_coordinate(row, col)
      "#{LETTERS[row]}#{col + 1}"
    end

    # Автоматичне розміщення повного флоту
    def place_ships_randomly!
      @ships.clear
      FLEET_SPEC.each do |ship_len|
        placed = false
        max_attempts = 1000
        attempts = 0

        until placed
          attempts += 1
          if attempts > max_attempts
            # Якщо випадкове розміщення зайшло в глухий кут, починаємо заново
            @ships.clear
            attempts = 0
            redo
          end

          orientation = %i[horizontal vertical].sample
          if orientation == :horizontal
            row = rand(0...SIZE)
            col = rand(0..(SIZE - ship_len))
            coords = (0...ship_len).map { |i| [row, col + i] }
          else
            row = rand(0..(SIZE - ship_len))
            col = rand(0...SIZE)
            coords = (0...ship_len).map { |i| [row + i, col] }
          end

          if can_place_ship?(coords)
            @ships << Ship.new(coords)
            placed = true
          end
        end
      end
    end

    # Перевірка, чи можна розмістити корабель (не перетинається і не торкається сусідів)
    def can_place_ship?(coords)
      coords.each do |r, c|
        return false unless self.class.valid_coordinate?(r, c)

        # Перевірка сусідніх клітинок по периметру (включно з діагоналями)
        (-1..1).each do |dr|
          (-1..1).each do |dc|
            nr = r + dr
            nc = c + dc
            next unless self.class.valid_coordinate?(nr, nc)
            return false if occupied_by_any_ship?([nr, nc])
          end
        end
      end
      true
    end

    def occupied_by_any_ship?(coord)
      @ships.any? { |ship| ship.occupies?(coord) }
    end

    def ship_at(coord)
      @ships.find { |ship| ship.occupies?(coord) }
    end

    # Обробка пострілу: повертає [result_symbol, hit_ship]
    # :hit, :sunk, :miss
    def receive_shot(coord)
      row, col = coord
      unless self.class.valid_coordinate?(row, col)
        raise InvalidCoordinateError, "Координата #{self.class.format_coordinate(row, col)} виходить за межі поля"
      end

      if @shots.key?(coord)
        raise CellAlreadyHitError, "У клітинку #{self.class.format_coordinate(row, col)} вже стріляли!"
      end

      ship = ship_at(coord)
      if ship
        ship.register_hit(coord)
        @shots[coord] = :hit
        if ship.sunk?
          mark_sunk_surroundings(ship)
          [:sunk, ship]
        else
          [:hit, ship]
        end
      else
        @shots[coord] = :miss
        [:miss, nil]
      end
    end

    # Позначити клітинки навколо потопленого корабля промахами (автоматичне маркування)
    def mark_sunk_surroundings(ship)
      ship.coordinates.each do |r, c|
        (-1..1).each do |dr|
          (-1..1).each do |dc|
            nr = r + dr
            nc = c + dc
            next unless self.class.valid_coordinate?(nr, nc)

            coord = [nr, nc]
            @shots[coord] = :miss unless @shots.key?(coord)
          end
        end
      end
    end

    # Чи всі кораблі знищені
    def all_sunk?
      @ships.all?(&:sunk?)
    end

    # Кількість живих кораблів
    def live_ships_count
      @ships.count { |s| !s.sunk? }
    end

    # Повертає масив рядків для відображення поля
    # hide_ships: true якщо це поле комп'ютера і непошкоджені кораблі треба ховати
    def render_rows(hide_ships: false)
      header = '   ' + NUMBERS.map { |n| n.to_s.rjust(2) }.join(' ')
      divider = '   ' + ('--' * SIZE + '-')

      rows = [header, divider]
      LETTERS.each_with_index do |letter, r|
        row_cells = (0...SIZE).map do |c|
          coord = [r, c]
          ship = ship_at(coord)

          if ship && ship.sunk?
            CELL_SUNK
          elsif @shots[coord] == :hit
            CELL_HIT
          elsif @shots[coord] == :miss
            CELL_MISS
          elsif ship && !hide_ships
            CELL_SHIP
          else
            CELL_EMPTY
          end
        end
        rows << "#{letter.ljust(2)}| #{row_cells.map { |cell| cell.center(2) }.join(' ')} |"
      end
      rows << divider
      rows
    end

    # Друк одного поля
    def print_board(title = nil, hide_ships: false)
      puts "=== #{title} ===" if title
      render_rows(hide_ships: hide_ships).each { |row| puts row }
    end
  end
end
