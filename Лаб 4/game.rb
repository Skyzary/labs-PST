# frozen_string_literal: true

require_relative 'board'
require_relative 'puzzles'

module Sudoku
  # Керує ігровим процесом, введенням користувача, історією ходів та статистикою.
  class Game
    def initialize(size: 4, difficulty: :easy)
      @puzzle_data = Puzzles.get(size, difficulty)
      @board = Board.new(@puzzle_data)
      @history = []
      @stats = { moves: 0, errors: 0, hints: 0, undos: 0 }
      @start_time = Time.now
      @running = true
    end

    def play
      puts "\n=== Судоку #{@board.size}×#{@board.size} | Рівень: #{@puzzle_data[:name]} ==="
      print_controls

      while @running
        @board.render
        print_status

        input = prompt_input
        if input.nil?
          puts "\nВведення завершено. Достроковий вихід із гри."
          break
        end

        process_input(input.strip)
        check_victory
      end

      print_summary
    end

    private

    def print_controls
      puts 'Команди:'
      puts "  <рядок> <стовпець> <число>  — поставити число (1..#{@board.size}) або 0 для очищення"
      puts '  u / undo                    — скасувати останній хід'
      puts '  h / hint                    — отримати підказку'
      puts '  q / quit                    — достроково завершити гру'
    end

    def print_status
      puts "Ходів: #{@stats[:moves]} | Помилок: #{@stats[:errors]} | Підказок: #{@stats[:hints]}"
    end

    def prompt_input
      print "\nВаш хід (або команда): "
      $stdout.flush
      $stdin.gets
    end

    def process_input(input)
      return if input.empty?

      case input.downcase
      when 'q', 'quit', 'exit'
        @running = false
        puts 'Гру завершено достроково.'
      when 'u', 'undo'
        handle_undo
      when 'h', 'hint'
        handle_hint
      else
        handle_move(input)
      end
    end

    def handle_move(input)
      parts = input.split(/[\s,]+/)
      unless parts.length == 3 && parts.all? { |p| p.match?(/\A-?\d+\z/) }
        record_error("Некоректний формат. Введіть 3 числа: рядок, стовпець і значення (наприклад: 1 2 3).")
        return
      end

      row, col, num = parts.map(&:to_i)
      size = @board.size

      unless (1..size).cover?(row) && (1..size).cover?(col)
        record_error("Координати мають бути в межах від 1 до #{size}.")
        return
      end

      unless (0..size).cover?(num)
        record_error("Число має бути від 1 до #{size} (або 0 для очищення клітинки).")
        return
      end

      r = row - 1
      c = col - 1

      if @board.initial_cell?(r, c)
        record_error("Клітинка (#{row}, #{col}) є початковою — її змінювати заборонено!")
        return
      end

      if num.zero?
        clear_player_cell(r, c, row, col)
        return
      end

      valid, reason = @board.valid_move?(r, c, num)
      unless valid
        record_error("Порушення правил: #{reason}")
        return
      end

      apply_move(r, c, num)
      puts "Хід прийнято: (#{row}, #{col}) = #{num}."
    end

    def clear_player_cell(r, c, row, col)
      prev = @board.cell_value(r, c)
      if prev.zero?
        puts "Клітинка (#{row}, #{col}) вже порожня."
        return
      end

      @history.push(row: r, col: c, prev: prev, next_val: 0)
      @board.set_cell(r, c, 0)
      @stats[:moves] += 1
      puts "Клітинку (#{row}, #{col}) очищено."
    end

    def apply_move(r, c, num)
      prev = @board.cell_value(r, c)
      @history.push(row: r, col: c, prev: prev, next_val: num)
      @board.set_cell(r, c, num)
      @stats[:moves] += 1
    end

    def handle_undo
      if @history.empty?
        puts 'Немає ходів для скасування.'
        return
      end

      last = @history.pop
      @board.set_cell(last[:row], last[:col], last[:prev])
      @stats[:undos] += 1
      puts "Скасовано хід у клітинці (#{last[:row] + 1}, #{last[:col] + 1})."
    end

    def handle_hint
      hint = @board.next_hint
      if hint.nil?
        puts 'Усі клітинки вже заповнені.'
        return
      end

      r, c, val = hint
      @history.push(row: r, col: c, prev: @board.cell_value(r, c), next_val: val)
      @board.set_cell(r, c, val)
      @stats[:hints] += 1
      puts "Підказка: у клітинку (#{r + 1}, #{c + 1}) поставлено число #{val}."
    end

    def check_victory
      return unless @running && @board.solved?

      @board.render
      puts 'Вітаємо! Ви успішно розв’язали Судоку!'
      @running = false
    end

    def record_error(message)
      @stats[:errors] += 1
      puts "Помилка: #{message}"
    end

    def print_summary
      elapsed = (Time.now - @start_time).round(1)
      puts "\n--- Статистика гри ---"
      puts "Зроблено ходів: #{@stats[:moves]}"
      puts "Помилок: #{@stats[:errors]}"
      puts "Використано підказок: #{@stats[:hints]}"
      puts "Скасувань ходів: #{@stats[:undos]}"
      puts "Час гри: #{elapsed} сек."
    end
  end
end
