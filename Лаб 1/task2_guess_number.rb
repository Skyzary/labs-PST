def play_game
  target = rand(1..100)
  attempts = 0
  
  puts "ГРА: Вгадай число"
  puts "Я загадав число від 1 до 100. Спробуй вгадати!"
  
  loop do
    print "Введи число: "
    input = gets.chomp
    
    # Перевірка на порожній ввід
    next if input.strip.empty?
    
    guess = input.to_i
    attempts += 1
    
    if guess < target
      puts "більше"
    elsif guess > target
      puts "менше"
    else
      puts "вгадано! Кількість спроб: #{attempts}"
      break
    end
  end
end

if __FILE__ == $0
  play_game
end
