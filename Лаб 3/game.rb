# frozen_string_literal: true

require_relative 'board'
require_relative 'player'
require_relative 'statistics'
require_relative 'errors'

module Battleship
  class Game
    attr_reader :human, :ai, :stats

    def initialize(stats = Statistics.new)
      @stats = stats
      @human = HumanPlayer.new('Гравець')
      @ai = AIPlayer.new("Комп'ютер")
    end

    def start
      puts "\n" + '=' * 50
      puts "        РОЗПОЧАТО НОВУ БИТВУ 'МОРСЬКИЙ БІЙ'!"
      puts '=' * 50

      # Розміщення флотів
      @human.setup_fleet!
      @ai.setup_fleet!
      @ai.reset_targets!

      puts "\nВаш флот та флот противника сформовано та розміщено на полях."
      puts "Введіть 'q' або 'exit' під час ходу, щоб достроково завершити бій."

      loop do
        # 1. Хід гравця
        display_boards
        break if human_turn

        # Перевірка на перемогу після ходу гравця
        if @ai.defeated?
          display_boards
          puts "\n🎉 ВІТАЄМО! Ви знищили весь флот комп'ютера і здобули ПЕРЕМОГУ!"
          @stats.record_win!
          break
        end

        # 2. Хід комп'ютера
        puts "\n" + '-' * 50
        puts "Хід супротивника (#{ai.name})..."
        ai_turn

        # Перевірка на поразку
        if @human.defeated?
          display_boards
          puts "\n💀 Всі ваші кораблі знищено! Комп'ютер здобув перемогу."
          @stats.record_loss!
          break
        end
      end

      puts "\nБій завершено. Повернення в головне меню...\n"
    end

    private

    # Повертає true якщо гравець вирішив вийти
    def human_turn
      loop do
        print "\nВаш постріл (наприклад, A5 або B10): "
        input = gets
        return true if input.nil? # EOF

        input = input.strip
        if %w[q quit exit вихід].include?(input.downcase)
          puts "\nВи капітулювали. Поразка зарахована."
          @stats.record_loss!
          return true
        end

        begin
          coord = Board.parse_coordinate(input)
          result, ship = @ai.board.receive_shot(coord)

          case result
          when :miss
            puts "\n🌊 ПРОМАХ! (#{Board.format_coordinate(*coord)})"
          when :hit
            puts "\n🔥 ВЛУЧАННЯ! Корабель противника пошкоджено на #{Board.format_coordinate(*coord)}!"
          when :sunk
            puts "\n💥 ЗНИЩЕНО! #{ship.size}-палубний корабель противника пішов на дно!"
          end

          # Якщо влучив або потопив - додатковий хід за класичними правилами чи перехід ходу?
          # Якщо промах — виходимо з циклу ходу людини
          # За класичними правилами гравець ходить знову при влучанні, якщо він не переміг
          if (result == :hit || result == :sunk) && !@ai.defeated?
            puts "Ви влучили, тому маєте право на додатковий постріл!"
            display_boards
            next
          end

          return false
        rescue GameError => e
          puts "⚠️  [Помилка] #{e.message}. Спробуйте ще раз."
        rescue Interrupt
          puts "\nПереривання гри..."
          return true
        end
      end
    end

    def ai_turn
      loop do
        target = @ai.choose_target(@human.board)
        unless target
          puts "Комп'ютер не має куди стріляти."
          return
        end

        coord_str = Board.format_coordinate(*target)
        result, ship = @human.board.receive_shot(target)
        @ai.register_shot_result(target, result, ship)

        case result
        when :miss
          puts "Супротивник вистрілив по #{coord_str} і ПРОМАХНУВСЯ. 🌊"
          return # Перехід ходу до гравця
        when :hit
          puts "⚠️  УВАГА! Супротивник влучив у ваш корабель на #{coord_str}! 🔥"
        when :sunk
          puts "💥 ЛИХО! Ваш #{ship.size}-палубний корабель на #{coord_str} було ЗНИЩЕНО!"
        end

        # Якщо комп'ютер влучив і гравець ще не програв — він стріляє знову!
        if @human.defeated?
          return
        else
          puts "Комп'ютер отримав додатковий постріл..."
        end
      end
    end

    def display_boards
      puts "\n" + '=' * 67
      player_title = "ВАШЕ ПОЛЕ (Живих: #{@human.board.live_ships_count})"
      ai_title     = "ПОЛЕ СУПРОТИВНИКА (Живих: #{@ai.board.live_ships_count})"
      
      # Формуємо заголовки шириною по 32 символи
      puts "  #{player_title.ljust(33)}   #{ai_title}"

      p_rows = @human.board.render_rows(hide_ships: false)
      ai_rows = @ai.board.render_rows(hide_ships: true)

      p_rows.each_with_index do |p_row, i|
        puts "#{p_row}    #{ai_rows[i]}"
      end
      puts "Позначення: ~ вода | ■ ваш корабель | • промах | ✕ поранення | 🕱 потоплений"
      puts '=' * 67
    end
  end
end
