# frozen_string_literal: true

require 'date'
require_relative 'expense'
require_relative 'storage'
require_relative 'tracker'
require_relative 'validator'

module ExpenseTracker
  # Консольний інтерфейс користувача для ExpenseTracker.
  class CLI
    DEFAULT_DATA_FILE = File.join(__dir__, 'expenses.json')

    def initialize(data_file: DEFAULT_DATA_FILE)
      @storage = Storage.new(data_file)
      @tracker = Tracker.new(@storage)
    end

    def run
      loop do
        print_menu
        choice = read_line
        return if choice.nil?

        case choice
        when '1' then handle_add
        when '2' then handle_list_all
        when '3' then handle_filter
        when '4' then handle_delete
        when '5' then handle_statistics
        when '6' then handle_import
        when '7', '0'
          puts 'До побачення!'
          return
        else
          puts 'Помилка: невідома команда. Оберіть пункт меню від 1 до 7.'
        end
      end
    end

    private

    def print_menu
      puts "\n========================================"
      puts '           EXPENSE TRACKER'
      puts '========================================'
      puts '1. Додавання витрати'
      puts '2. Перегляд усіх витрат'
      puts '3. Фільтрація за категорією та періодом'
      puts '4. Видалення витрати за ID'
      puts '5. Перегляд статистики'
      puts '6. Імпорт витрат із JSON-файла'
      puts '7. Завершення роботи'
      print 'Оберіть дію (1-7): '
      $stdout.flush
    end

    def handle_add
      puts "\n--- Додавання витрати (введіть 0 для скасування) ---"
      date = prompt_date(allow_empty_today: true)
      return if date.nil?

      amount = prompt_amount
      return if amount.nil?

      category = prompt_category(allow_empty: false)
      return if category.nil?

      description = prompt_description
      return if description.nil?

      expense = @tracker.add_expense(
        date: date,
        amount_in_kopecks: amount,
        category: category,
        description: description
      )
      puts "Витрату успішно додано (ID: #{expense.id}, сума: #{expense.formatted_amount})."
    rescue StorageSaveError => e
      puts "Помилка збереження: #{e.message}"
      puts 'Зміни скасовано, попередній стан у пам’яті відновлено.'
    end

    def handle_list_all
      puts "\n--- Усі витрати ---"
      render_expenses_table(@tracker.expenses)
    end

    def handle_filter
      puts "\n--- Фільтрація витрат (Enter — пропустити критерій) ---"
      category = prompt_category(allow_empty: true)
      return if category == :cancel

      from_date = prompt_optional_date('Початкова дата (YYYY-MM-DD, Enter — без обмеження): ')
      return if from_date == :cancel

      to_date = prompt_optional_date('Кінцева дата (YYYY-MM-DD, Enter — без обмеження): ')
      return if to_date == :cancel

      if from_date && to_date && from_date > to_date
        puts 'Помилка: початкова дата не може бути пізнішою за кінцеву.'
        return
      end

      results = @tracker.filter(category: category, from_date: from_date, to_date: to_date)
      puts "\nРезультати фільтрації:"
      render_expenses_table(results)
    end

    def handle_delete
      puts "\n--- Видалення витрати ---"
      print 'Введіть ID витрати (або 0 для скасування): '
      $stdout.flush
      raw = read_line
      return if raw.nil? || raw == '0'

      id = Validator.parse_positive_int(raw)
      unless id
        puts 'Помилка: ID має бути додатним цілим числом.'
        return
      end

      expense = @tracker.find_by_id(id)
      unless expense
        puts "Витрату з ID=#{id} не знайдено."
        return
      end

      puts "Знайдено запис: [#{expense.id}] #{expense.date} | #{expense.category} | #{expense.formatted_amount} | #{expense.description}"
      print 'Підтвердити видалення? (y/n): '
      $stdout.flush
      confirm = read_line&.downcase
      unless %w[y yes т так].include?(confirm)
        puts 'Видалення скасовано.'
        return
      end

      @tracker.delete_expense(id)
      puts "Витрату з ID=#{id} успішно видалено."
    rescue StorageSaveError => e
      puts "Помилка збереження: #{e.message}"
      puts 'Зміни скасовано, попередній стан у пам’яті відновлено.'
    end

    def handle_statistics
      puts "\n--- Статистика витрат ---"
      stats = @tracker.statistics
      if stats[:count].zero?
        puts 'Немає записів для підрахунку статистики.'
        return
      end

      puts "Кількість записів: #{stats[:count]}"
      puts "Загальна сума:     #{Expense.format_kopecks(stats[:total_kopecks])}"
      puts "Середня витрата:   #{Expense.format_kopecks(stats[:average_kopecks])}"
      puts "Найбільша витрата: #{stats[:max_expense].formatted_amount} (#{stats[:max_expense].description})"
      puts "Найменша витрата:  #{stats[:min_expense].formatted_amount} (#{stats[:min_expense].description})"

      puts "\nРозподіл за категоріями:"
      puts format('%-15s | %-9s | %-14s | %s', 'Категорія', 'Кількість', 'Сума', 'Частка')
      puts '-' * 56
      stats[:by_category].each do |row|
        puts format(
          '%-15s | %-9d | %-14s | %.1f%%',
          row[:category],
          row[:count],
          Expense.format_kopecks(row[:total_kopecks]),
          row[:percentage]
        )
      end
    end

    def handle_import
      puts "\n--- Імпорт витрат із JSON-файла ---"
      print 'Введіть шлях до JSON-файла (або 0 для скасування): '
      $stdout.flush
      path = read_line
      return if path.nil? || path == '0'

      if path.empty?
        puts 'Помилка: шлях до файла не може бути порожнім.'
        return
      end

      result = @tracker.import_from_json(path)
      puts "Імпортовано записів: #{result[:imported_count]}"
      if result[:reassigned_ids_count].positive?
        puts "Перепризначено ID для уникнення конфліктів: #{result[:reassigned_ids_count]}"
      end

      unless result[:skipped].empty?
        puts "Пропущено некоректних записів: #{result[:skipped].length}"
        result[:skipped].each do |err|
          puts "  - Запис №#{err[:index]}: #{err[:reasons].join(' ')}"
        end
      end
    rescue ImportError => e
      puts "Помилка імпорту: #{e.message}"
    rescue StorageSaveError => e
      puts "Помилка збереження після імпорту: #{e.message}"
      puts 'Імпортовані дані не збережено; попередній стан у пам’яті відновлено.'
    end

    def render_expenses_table(expenses)
      if expenses.empty?
        puts 'Список витрат порожній.'
        return
      end

      sorted = expenses.sort_by { |e| [e.date, e.id] }
      puts format('%-4s | %-10s | %-13s | %-13s | %s', 'ID', 'Дата', 'Категорія', 'Сума', 'Опис')
      puts '-' * 75
      sorted.each do |e|
        puts format('%-4d | %-10s | %-13s | %-13s | %s', e.id, e.date, e.category, e.formatted_amount, e.description)
      end
      puts '-' * 75
      total = sorted.sum(&:amount_in_kopecks)
      puts "Усього записів: #{sorted.length} | Загальна сума: #{Expense.format_kopecks(total)}"
    end

    def prompt_date(allow_empty_today:)
      today = Date.today.iso8601
      loop do
        prompt = allow_empty_today ? "Дата (YYYY-MM-DD, Enter = #{today}): " : 'Дата (YYYY-MM-DD): '
        print prompt
        $stdout.flush
        raw = read_line
        return nil if raw.nil? || raw == '0'
        return today if allow_empty_today && raw.empty?
        return raw if Validator.valid_date?(raw)

        puts 'Помилка: введіть реальну календарну дату у форматі YYYY-MM-DD.'
      end
    end

    def prompt_optional_date(prompt_text)
      loop do
        print prompt_text
        $stdout.flush
        raw = read_line
        return :cancel if raw.nil? || raw == '0'
        return nil if raw.empty?
        return raw if Validator.valid_date?(raw)

        puts 'Помилка: введіть реальну календарну дату у форматі YYYY-MM-DD або натисніть Enter.'
      end
    end

    def prompt_amount
      loop do
        print 'Сума в копійках (наприклад, 12550 для 125.50 грн): '
        $stdout.flush
        raw = read_line
        return nil if raw.nil? || raw == '0'

        amount = Validator.parse_positive_int(raw)
        return amount if amount

        puts 'Помилка: сума має бути додатним цілим числом копійок (наприклад, 12550).'
      end
    end

    def prompt_category(allow_empty:)
      categories = Validator::CATEGORIES
      puts "Доступні категорії: #{categories.each_with_index.map { |c, i| "#{i + 1}. #{c}" }.join(', ')}"
      loop do
        print(allow_empty ? 'Категорія (назва або номер, Enter — усі): ' : 'Категорія (назва або номер): ')
        $stdout.flush
        raw = read_line
        return(allow_empty ? :cancel : nil) if raw.nil? || raw == '0'
        return nil if allow_empty && raw.empty?

        if raw.match?(/\A\d+\z/)
          idx = raw.to_i - 1
          return categories[idx] if idx >= 0 && idx < categories.length
        end

        normalized = raw.downcase
        return normalized if Validator.valid_category?(normalized)

        puts "Помилка: оберіть одну з категорій (#{categories.join(', ')}) або її номер."
      end
    end

    def prompt_description
      loop do
        print "Опис (до #{Validator::MAX_DESCRIPTION_LENGTH} символів): "
        $stdout.flush
        raw = read_line
        return nil if raw.nil? || raw == '0'

        normalized = Validator.normalize_description(raw)
        return normalized if Validator.valid_description?(normalized)

        puts "Помилка: опис має бути непорожнім і містити до #{Validator::MAX_DESCRIPTION_LENGTH} символів."
      end
    end

    def read_line
      line = $stdin.gets
      line&.strip
    end
  end
end
