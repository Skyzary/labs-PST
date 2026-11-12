# frozen_string_literal: true

require_relative 'cli'

if __FILE__ == $PROGRAM_NAME
  data_file = ARGV[0] || ExpenseTracker::CLI::DEFAULT_DATA_FILE

  begin
    ExpenseTracker::CLI.new(data_file: data_file).run
  rescue ExpenseTracker::StorageLoadError => e
    warn "Критична помилка запуску: #{e.message}"
    warn 'Програму завершено без перезаписування файла даних.'
    exit 1
  end
end
