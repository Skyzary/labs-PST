# frozen_string_literal: true

require 'json'
require 'set'
require_relative 'expense'
require_relative 'validator'

module ExpenseTracker
  class StorageError < StandardError; end
  class StorageLoadError < StorageError; end
  class StorageSaveError < StorageError; end

  # Відповідає за читання та збереження витрат у локальному JSON-файлі.
  class Storage
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def load
      return [] unless File.exist?(@path)

      content = File.read(@path, encoding: 'UTF-8')
      raise StorageLoadError, "Файл даних «#{@path}» порожній." if content.strip.empty?

      data = parse_json(content)
      raise StorageLoadError, "Файл даних «#{@path}» повинен містити JSON-масив." unless data.is_a?(Array)

      validate_and_build_expenses(data)
    rescue SystemCallError, IOError => e
      raise StorageLoadError, "Не вдалося прочитати файл «#{@path}»: #{e.message}"
    end

    def save(expenses)
      payload = JSON.pretty_generate(expenses.map(&:to_h))
      File.write(@path, "#{payload}\n", encoding: 'UTF-8')
    rescue SystemCallError, IOError => e
      raise StorageSaveError, "Не вдалося зберегти дані у файл «#{@path}»: #{e.message}"
    end

    private

    def parse_json(content)
      JSON.parse(content)
    rescue JSON::ParserError => e
      raise StorageLoadError, "Файл даних «#{@path}» пошкоджений (некоректний JSON): #{e.message}"
    end

    def validate_and_build_expenses(data)
      seen_ids = Set.new
      expenses = []

      data.each_with_index do |item, idx|
        errors = Validator.validate_record_hash(item, require_id: true)
        unless errors.empty?
          raise StorageLoadError, "Некоректний запис №#{idx + 1} у файлі «#{@path}»: #{errors.join(' ')}"
        end

        id = item['id']
        if seen_ids.include?(id)
          raise StorageLoadError, "Дубльований ідентифікатор id=#{id} у файлі «#{@path}»."
        end

        seen_ids.add(id)
        expenses << Expense.from_hash(item)
      end

      expenses
    end
  end
end
