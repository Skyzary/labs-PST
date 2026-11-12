# frozen_string_literal: true

require_relative 'validator'

module ExpenseTracker
  # Модель запису про витрату.
  class Expense
    attr_reader :id, :date, :amount_in_kopecks, :category, :description

    def initialize(id:, date:, amount_in_kopecks:, category:, description:)
      @id = id
      @date = date
      @amount_in_kopecks = amount_in_kopecks
      @category = category
      @description = Validator.normalize_description(description)
    end

    def self.from_hash(hash)
      new(
        id: hash['id'],
        date: hash['date'],
        amount_in_kopecks: hash['amount_in_kopecks'],
        category: hash['category'],
        description: hash['description']
      )
    end

    def self.format_kopecks(kopecks)
      format('%d.%02d грн', kopecks / 100, kopecks % 100)
    end

    def formatted_amount
      self.class.format_kopecks(@amount_in_kopecks)
    end

    def to_h
      {
        'id' => @id,
        'date' => @date,
        'amount_in_kopecks' => @amount_in_kopecks,
        'category' => @category,
        'description' => @description
      }
    end
  end
end
