# frozen_string_literal: true

require "csv"
require "fileutils"
require "json"

PASSING_SCORE = 60
VALID_SCORE_RANGE = (0..100)

def parse_score(raw_score)
  raise ArgumentError, "Missing score" if raw_score.nil?

  stripped = raw_score.strip
  raise ArgumentError, "Empty score" if stripped.empty?

  score = Integer(stripped, 10)
  unless VALID_SCORE_RANGE.cover?(score)
    raise ArgumentError, "Score out of range: #{score}"
  end

  score
end

def build_report(csv_path)
  total = 0
  valid_scores = []
  invalid_rows = []

  CSV.foreach(csv_path, headers: true, encoding: "UTF-8").with_index(1) do |row, row_number|
    total += 1
    begin
      score = parse_score(row["score"])
      valid_scores << score
    rescue ArgumentError, TypeError
      invalid_rows << row_number
    end
  end

  valid_count = valid_scores.size
  average = valid_count.zero? ? 0.0 : (valid_scores.sum.to_f / valid_count).round(1)
  passed = valid_scores.count { |score| score >= PASSING_SCORE }

  {
    total: total,
    valid: valid_count,
    invalid_rows: invalid_rows,
    average: average,
    passed: passed
  }
end

def write_report(output_path, report)
  FileUtils.mkdir_p(File.dirname(output_path))
  File.write(output_path, "#{JSON.pretty_generate(report)}\n", encoding: "UTF-8")
end

def main
  csv_path = File.join(__dir__, "data", "students.csv")
  output_path = File.join(__dir__, "output", "report.json")

  report = build_report(csv_path)
  write_report(output_path, report)
rescue Errno::ENOENT => e
  warn "Помилка: файл не знайдено (#{e.message})"
  exit 1
rescue CSV::MalformedCSVError => e
  warn "Помилка формату CSV: #{e.message}"
  exit 1
end

