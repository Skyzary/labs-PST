# frozen_string_literal: true

module Sudoku
  # Представляє ігрове поле Судоку (4x4 або 9x9) у вигляді двовимірного масиву.
  class Board
    attr_reader :size, :block_size, :grid

    def initialize(puzzle_data)
      @initial = puzzle_data[:initial].map(&:dup).freeze
      @solution = puzzle_data[:solution].map(&:dup).freeze
      @grid = puzzle_data[:initial].map(&:dup)
      @size = @grid.length
      @block_size = Math.sqrt(@size).to_i
    end

    def initial_cell?(row, col)
      @initial[row][col] != 0
    end

    def cell_value(row, col)
      @grid[row][col]
    end

    def set_cell(row, col, value)
      @grid[row][col] = value
    end

    # Перевіряє, чи відповідає хід правилам Судоку (без урахування поточного значення в (row, col)).
    def valid_move?(row, col, num)
      return [false, "Число #{num} вже є в рядку #{row + 1}."] if in_row?(row, col, num)
      return [false, "Число #{num} вже є в стовпці #{col + 1}."] if in_col?(row, col, num)
      return [false, "Число #{num} вже є в блоці #{@block_size}×#{@block_size}."] if in_block?(row, col, num)

      [true, nil]
    end

    def full?
      @grid.all? { |row| row.none?(&:zero?) }
    end

    def solved?
      return false unless full?

      expected = (1..@size).to_a
      rows_valid = @grid.all? { |row| row.sort == expected }
      cols_valid = (0...@size).all? { |c| @grid.map { |r| r[c] }.sort == expected }
      blocks_valid = all_blocks_valid?(expected)

      rows_valid && cols_valid && blocks_valid
    end

    # Повертає [row, col, correct_value] для першої знайденої порожньої клітинки.
    def next_hint
      @size.times do |r|
        @size.times do |c|
          return [r, c, @solution[r][c]] if @grid[r][c].zero?
        end
      end
      nil
    end

    def render
      puts
      print_column_headers
      print_border('┌', '┬', '┐')

      @size.times do |r|
        print_row(r)
        if ((r + 1) % @block_size).zero? && r < @size - 1
          print_border('├', '┼', '┤')
        end
      end

      print_border('└', '┴', '┘')
      puts
    end

    private

    def in_row?(row, col, num)
      @size.times.any? { |c| c != col && @grid[row][c] == num }
    end

    def in_col?(row, col, num)
      @size.times.any? { |r| r != row && @grid[r][col] == num }
    end

    def in_block?(row, col, num)
      start_r = (row / @block_size) * @block_size
      start_c = (col / @block_size) * @block_size

      (start_r...(start_r + @block_size)).any? do |r|
        (start_c...(start_c + @block_size)).any? do |c|
          !(r == row && c == col) && @grid[r][c] == num
        end
      end
    end

    def all_blocks_valid?(expected)
      (0...@size).step(@block_size).all? do |start_r|
        (0...@size).step(@block_size).all? do |start_c|
          block_values = []
          @block_size.times do |dr|
            @block_size.times do |dc|
              block_values << @grid[start_r + dr][start_c + dc]
            end
          end
          block_values.sort == expected
        end
      end
    end

    def print_column_headers
      header = +'    '
      @size.times do |c|
        header << "#{c + 1} "
        header << '  ' if ((c + 1) % @block_size).zero? && c < @size - 1
      end
      puts header
    end

    def print_border(left, mid, right)
      segment = '─' * (@block_size * 2 + 1)
      line = Array.new(@block_size, segment).join(mid)
      puts "  #{left}#{line}#{right}"
    end

    def print_row(row_idx)
      line = +"#{row_idx + 1} │ "
      @size.times do |c|
        val = @grid[row_idx][c]
        line << (val.zero? ? '.' : val.to_s)
        line << ' '
        line << '│ ' if ((c + 1) % @block_size).zero? && c < @size - 1
      end
      line << '│'
      puts line
    end
  end
end
