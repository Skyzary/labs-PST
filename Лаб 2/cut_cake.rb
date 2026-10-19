def cut(cake)
  return [] if cake.nil? || cake.strip.empty?

  lines = cake.strip.split("\n").map(&:strip).reject(&:empty?)
  return [] if lines.empty?

  h = lines.size
  w = lines[0].size

  grid = Array.new(h) { Array.new(w, false) }
  raisin_count = 0

  (0...h).each do |r|
    (0...w).each do |c|
      if lines[r][c] =~ /[oOоО]/
        grid[r][c] = true
        raisin_count += 1
      end
    end
  end

  total_area = h * w
  return [] if raisin_count == 0 || (total_area % raisin_count) != 0

  target_area = total_area / raisin_count

  dimensions = []
  (1..h).each do |piece_h|
    if (target_area % piece_h) == 0
      piece_w = target_area / piece_h
      dimensions << [piece_h, piece_w] if piece_w <= w
    end
  end

  dimensions.sort_by! { |_dh, dw| -dw }

  covered = Array.new(h) { Array.new(w, false) }
  pieces = []

  can_place = lambda do |r, c, dh, dw|
    return false if r + dh > h || c + dw > w

    r_count = 0
    (r...(r + dh)).each do |i|
      (c...(c + dw)).each do |j|
        return false if covered[i][j]

        if grid[i][j]
          r_count += 1
          return false if r_count > 1
        end
      end
    end

    r_count == 1
  end

  backtrack = lambda do
    first_r = nil
    first_c = nil

    (0...h).each do |i|
      (0...w).each do |j|
        unless covered[i][j]
          first_r = i
          first_c = j
          break
        end
      end
      break if first_r
    end

    return true if first_r.nil?

    dimensions.each do |dh, dw|
      next unless can_place.call(first_r, first_c, dh, dw)

      (first_r...(first_r + dh)).each do |i|
        (first_c...(first_c + dw)).each do |j|
          covered[i][j] = true
        end
      end

      piece_lines = (first_r...(first_r + dh)).map do |i|
        (first_c...(first_c + dw)).map { |j| grid[i][j] ? 'o' : '.' }.join
      end
      pieces << piece_lines.join("\n")

      return true if backtrack.call

      pieces.pop
      (first_r...(first_r + dh)).each do |i|
        (first_c...(first_c + dw)).each do |j|
          covered[i][j] = false
        end
      end
    end

    false
  end

  backtrack.call ? pieces : []
end

if __FILE__ == $PROGRAM_NAME
  cake1 = <<~CAKE
    ........
    ..o.....
    ...o....
    ........
  CAKE
  puts cut(cake1)
  puts "---"

  cake2 = <<~CAKE
    .o......
    ......o.
    ....o...
    ..o.....
  CAKE
  puts cut(cake2)
  puts "---"

  cake3 = <<~CAKE
    .o.o....
    ........
    ....o...
    ........
    .....o..
    ........
  CAKE
  puts cut(cake3)
end
