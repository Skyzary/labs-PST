# frozen_string_literal: true

require 'set'
require_relative 'board'
require_relative 'ship'

module Battleship
  class Player
    attr_reader :name, :board

    def initialize(name)
      @name = name
      @board = Board.new
    end

    def setup_fleet!
      @board.place_ships_randomly!
    end

    def defeated?
      @board.all_sunk?
    end
  end

  class HumanPlayer < Player
    # Людина вводить координати через консоль, валідація відбувається в Game або тут
  end

  class AIPlayer < Player
    def initialize(name = "Комп'ютер")
      super(name)
      @available_targets = []
      reset_targets!
      @pending_targets = [] # Клітинки для добивання пораненого корабля
      @current_hits = []    # Поточні влучання у ще не добитий корабель
    end

    def reset_targets!
      @available_targets = []
      (0...Board::SIZE).each do |r|
        (0...Board::SIZE).each do |c|
          @available_targets << [r, c]
        end
      end
      @available_targets.shuffle!
    end

    # Вибір координат для наступного пострілу
    def choose_target(opponent_board)
      # Відфільтрувати доступні цілі від уже вистріляних
      @available_targets.reject! { |coord| opponent_board.shots.key?(coord) }
      @pending_targets.reject! { |coord| opponent_board.shots.key?(coord) }

      target = nil

      # Якщо є цілі для добивання (поранений корабель)
      while !@pending_targets.empty? && target.nil?
        cand = @pending_targets.shift
        target = cand unless opponent_board.shots.key?(cand)
      end

      # Якщо черги добивання немає — вибираємо випадкову клітинку серед доступних
      if target.nil?
        target = @available_targets.sample
      end

      @available_targets.delete(target)
      target
    end

    # Реєстрація результату пострілу комп'ютера для покращення тактики (добивання)
    def register_shot_result(coord, result, ship = nil)
      r, c = coord
      case result
      when :hit
        @current_hits << coord
        # Додаємо сусідів по хресту до пріоритетних цілей
        neighbors = [
          [r - 1, c],
          [r + 1, c],
          [r, c - 1],
          [r, c + 1]
        ].select { |nr, nc| Board.valid_coordinate?(nr, nc) }

        # Якщо вже є 2 або більше влучання, визначаємо лінію (горизонтальна чи вертикальна)
        if @current_hits.size >= 2
          rows = @current_hits.map(&:first).uniq
          cols = @current_hits.map(&:last).uniq

          if rows.size == 1 # Горизонтальний корабель
            row = rows.first
            min_c = cols.min
            max_c = cols.max
            line_targets = [[row, min_c - 1], [row, max_c + 1]].select do |nr, nc|
              Board.valid_coordinate?(nr, nc)
            end
            @pending_targets = line_targets + (@pending_targets - line_targets)
          elsif cols.size == 1 # Вертикальний корабель
            col = cols.first
            min_r = rows.min
            max_r = rows.max
            line_targets = [[min_r - 1, col], [max_r + 1, col]].select do |nr, nc|
              Board.valid_coordinate?(nr, nc)
            end
            @pending_targets = line_targets + (@pending_targets - line_targets)
          end
        else
          # Перше влучання: додаємо сусідів
          neighbors.each do |n|
            @pending_targets.unshift(n) unless @pending_targets.include?(n)
          end
        end

      when :sunk
        # Корабель знищено — очищуємо чергу добивання цього корабля
        @current_hits.clear
        @pending_targets.clear
      when :miss
        # Нічого специфічного
      end
    end
  end
end
