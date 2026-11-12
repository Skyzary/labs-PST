# frozen_string_literal: true

require 'json'

module Battleship
  class Statistics
    attr_reader :file_path, :wins, :losses

    def initialize(file_path = File.expand_path('stats.json', __dir__))
      @file_path = file_path
      @wins = 0
      @losses = 0
      load_stats!
    end

    def record_win!
      @wins += 1
      save_stats!
    end

    def record_loss!
      @losses += 1
      save_stats!
    end

    def total_games
      @wins + @losses
    end

    def win_rate
      return 0.0 if total_games.zero?

      ((@wins.to_f / total_games) * 100).round(1)
    end

    def summary
      <<~TEXT
        ========================================
                   СТАТИСТИКА ІГОР
        ========================================
         Всього зіграно партій: #{total_games}
         Перемог гравця:        #{wins}
         Перемог комп'ютера:    #{losses}
         Відсоток перемог:      #{win_rate}%
        ========================================
      TEXT
    end

    private

    def load_stats!
      return unless File.exist?(@file_path)

      data = JSON.parse(File.read(@file_path))
      @wins = data['wins'] || 0
      @losses = data['losses'] || 0
    rescue StandardError => e
      # Якщо файл пошкоджений, скидаємо до нулів
      @wins = 0
      @losses = 0
    end

    def save_stats!
      data = {
        'wins' => @wins,
        'losses' => @losses,
        'updated_at' => Time.now.to_s
      }
      File.write(@file_path, JSON.pretty_generate(data))
    rescue StandardError => e
      warn "[Увага] Не вдалося зберегти статистику: #{e.message}"
    end
  end
end
