# frozen_string_literal: true

require 'json'
require 'set'
require_relative 'expense'
require_relative 'storage'
require_relative 'validator'

module ExpenseTracker
  class ImportError < StandardError; end

  # Основна бізнес-логіка обліку витрат, фільтрації, статистики та імпорту.
  class Tracker
    attr_reader :expenses

    def initialize(storage)
      @storage = storage
      @expenses = @storage.load
    end

    def add_expense(date:, amount_in_kopecks:, category:, description:)
      expense = Expense.new(
        id: next_id,
        date: date,
        amount_in_kopecks: amount_in_kopecks,
        category: category,
        description: description
      )

      commit_change { @expenses << expense }
      expense
    end

    def find_by_id(id)
      @expenses.find { |e| e.id == id }
    end

    def delete_expense(id)
      target = find_by_id(id)
      return nil unless target

      commit_change { @expenses.reject! { |e| e.id == id } }
      target
    end

    def filter(category: nil, from_date: nil, to_date: nil)
      @expenses.select do |e|
        next false if category && e.category != category
        next false if from_date && e.date < from_date
        next false if to_date && e.date > to_date

        true
      end
    end

    def statistics(list = @expenses)
      return empty_statistics if list.empty?

      total = list.sum(&:amount_in_kopecks)
      count = list.length
      by_category = build_category_stats(list, total)

      {
        count: count,
        total_kopecks: total,
        average_kopecks: (total.to_f / count).round,
        max_expense: list.max_by(&:amount_in_kopecks),
        min_expense: list.min_by(&:amount_in_kopecks),
        by_category: by_category
      }
    end

    def import_from_json(file_path)
      data = read_import_array(file_path)
      taken_ids = Set.new(@expenses.map(&:id))
      imported = []
      skipped = []
      reassigned_ids = 0

      data.each_with_index do |item, idx|
        errors = Validator.validate_record_hash(item, require_id: false)
        unless errors.empty?
          skipped << { index: idx + 1, reasons: errors }
          next
        end

        assigned_id, was_reassigned = resolve_import_id(item['id'], taken_ids)
        reassigned_ids += 1 if was_reassigned
        taken_ids.add(assigned_id)

        imported << Expense.new(
          id: assigned_id,
          date: item['date'],
          amount_in_kopecks: item['amount_in_kopecks'],
          category: item['category'],
          description: item['description']
        )
      end

      commit_change { @expenses.concat(imported) } unless imported.empty?

      {
        imported_count: imported.length,
        reassigned_ids_count: reassigned_ids,
        skipped: skipped
      }
    end

    private

    def next_id
      return 1 if @expenses.empty?

      @expenses.map(&:id).max + 1
    end

    def commit_change
      snapshot = @expenses.dup
      yield
      @storage.save(@expenses)
    rescue StorageSaveError
      @expenses = snapshot
      raise
    end

    def empty_statistics
      {
        count: 0,
        total_kopecks: 0,
        average_kopecks: 0,
        max_expense: nil,
        min_expense: nil,
        by_category: []
      }
    end

    def build_category_stats(list, total)
      grouped = list.group_by(&:category)
      grouped.map do |category, items|
        cat_total = items.sum(&:amount_in_kopecks)
        percentage = total.positive? ? (cat_total * 100.0 / total).round(1) : 0.0
        {
          category: category,
          count: items.length,
          total_kopecks: cat_total,
          percentage: percentage
        }
      end.sort_by { |c| -c[:total_kopecks] }
    end

    def read_import_array(file_path)
      raise ImportError, "Файл «#{file_path}» не знайдено." unless File.exist?(file_path)
      raise ImportError, "Шлях «#{file_path}» не є файлом." unless File.file?(file_path)

      content = File.read(file_path, encoding: 'UTF-8')
      raise ImportError, "Файл «#{file_path}» порожній." if content.strip.empty?

      data = JSON.parse(content)
      raise ImportError, 'Файл імпорту повинен містити JSON-масив записів.' unless data.is_a?(Array)

      data
    rescue JSON::ParserError => e
      raise ImportError, "Некоректний JSON у файлі «#{file_path}»: #{e.message}"
    rescue SystemCallError, IOError => e
      raise ImportError, "Не вдалося прочитати файл «#{file_path}»: #{e.message}"
    end

    def resolve_import_id(raw_id, taken_ids)
      if Validator.valid_id?(raw_id) && !taken_ids.include?(raw_id)
        [raw_id, false]
      else
        max_taken = taken_ids.empty? ? 0 : taken_ids.max
        [max_taken + 1, true]
      end
    end
  end
end
