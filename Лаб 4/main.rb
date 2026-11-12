# frozen_string_literal: true

require_relative 'game'

module Sudoku
  # Точка входу та текстове меню консольної гри «Судоку».
  class Menu
    DIFFICULTIES = {
      '1' => :easy,
      '2' => :medium,
      '3' => :hard
    }.freeze

    def run
      loop do
        print_main_menu
        choice = read_choice
        return if choice.nil?

        case choice
        when '1'
          start_game(4)
        when '2'
          start_game(9)
        when '3'
          print_rules
        when '0'
          puts 'До побачення!'
          return
        else
          puts 'Некоректний вибір. Спробуйте ще раз.'
        end
      end
    end

    private

    def print_main_menu
      puts "\n=============================="
      puts '       ГРА «СУДОКУ»'
      puts '=============================='
      puts '1. Нова гра 4×4 (блоки 2×2)'
      puts '2. Нова гра 9×9 (блоки 3×3)'
      puts '3. Правила гри'
      puts '0. Вихід'
      print 'Оберіть пункт меню: '
      $stdout.flush
    end

    def start_game(size)
      difficulty = choose_difficulty
      return if difficulty.nil?

      Game.new(size: size, difficulty: difficulty).play
    end

    def choose_difficulty
      loop do
        puts "\nОберіть рівень складності:"
        puts '1. Легкий'
        puts '2. Середній'
        puts '3. Складний'
        puts '0. Назад'
        print 'Ваш вибір: '
        $stdout.flush

        choice = read_choice
        return nil if choice.nil? || choice == '0'
        return DIFFICULTIES[choice] if DIFFICULTIES.key?(choice)

        puts 'Некоректний вибір. Оберіть 1, 2, 3 або 0.'
      end
    end

    def print_rules
      puts "\n--- Правила гри «Судоку» ---"
      puts '1. Поле 4×4 поділене на чотири блоки 2×2 (або 9×9 на блоки 3×3).'
      puts '2. У кожному рядку мають бути числа від 1 до N без повторень.'
      puts '3. У кожному стовпці числа не повинні повторюватися.'
      puts '4. У кожному блоці числа не повинні повторюватися.'
      puts '5. Початкові числа змінювати заборонено.'
      puts '6. Перемога настає після правильного заповнення всього поля.'
    end

    def read_choice
      line = $stdin.gets
      line&.strip
    end
  end
end

Sudoku::Menu.new.run if __FILE__ == $PROGRAM_NAME
