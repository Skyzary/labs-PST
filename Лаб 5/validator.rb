# frozen_string_literal: true

require 'date'

module ExpenseTracker
  # Валідація полів запису витрати згідно з вимогами предметної області.
  module Validator
    CATEGORIES = %w[food transport study entertainment other].freeze
    MAX_DESCRIPTION_LENGTH = 200
    DATE_REGEX = /\A\d{4}-\d{2}-\d{2}\z/

    module_function

    def valid_id?(value)
      value.is_a?(Integer) && value.positive?
    end

    def parse_positive_int(raw)
      str = raw.to_s.strip
      return nil unless str.match?(/\A\d+\z/)

      val = str.to_i
      val.positive? ? val : nil
    end

    def valid_date?(value)
      return false unless value.is_a?(String) && value.match?(DATE_REGEX)

      Date.iso8601(value)
      true
    rescue Date::Error
      false
    end

    def valid_amount?(value)
      value.is_a?(Integer) && value.positive?
    end

    def valid_category?(value)
      value.is_a?(String) && CATEGORIES.include?(value)
    end

    def normalize_description(value)
      return nil unless value.is_a?(String)

      value.strip
    end

    def valid_description?(value)
      normalized = normalize_description(value)
      !normalized.nil? && !normalized.empty? && normalized.length <= MAX_DESCRIPTION_LENGTH
    end

    # Повертає масив повідомлень про помилки для хешу запису (порожній, якщо запис коректний).
    def validate_record_hash(hash, require_id: true)
      errors = []
      unless hash.is_a?(Hash)
        errors << 'Запис має бути JSON-об’єктом.'
        return errors
      end

      if require_id
        errors << 'Поле id має бути додатним цілим числом.' unless valid_id?(hash['id'])
      elsif hash.key?('id') && !hash['id'].nil? && !valid_id?(hash['id'])
        errors << 'Поле id має бути додатним цілим числом.'
      end

      errors << 'Поле date має бути реальною датою у форматі YYYY-MM-DD.' unless valid_date?(hash['date'])
      errors << 'Поле amount_in_kopecks має бути додатним цілим числом.' unless valid_amount?(hash['amount_in_kopecks'])
      unless valid_category?(hash['category'])
        errors << "Поле category має бути одним із: #{CATEGORIES.join(', ')}."
      end
      unless valid_description?(hash['description'])
        errors << "Поле description має бути непорожнім рядком до #{MAX_DESCRIPTION_LENGTH} символів."
      end

      errors
    end
  end
end
