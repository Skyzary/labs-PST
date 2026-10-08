def play_rps
  choices = %w[Камінь Ножиці Папір]
  
  user_wins = 0
  comp_wins = 0
  ties = 0
  total_rounds = 0
  
  puts "Гра 'Камінь, ножиці, папір'."
  puts "Для виходу з гри введіть 'Вихід'."
  
  loop do
    print "\nВаш вибір (Камінь, Ножиці, Папір): "
    user_choice = gets.chomp.capitalize
    
    break if user_choice == "Вихід"
    
    unless choices.include?(user_choice)
      puts "Некоректний вибір. Спробуйте ще раз."
      next
    end
    
    comp_choice = choices.sample
    puts "Вибір комп'ютера: #{comp_choice}"
    
    total_rounds += 1
    
    if user_choice == comp_choice
      puts "Нічия!"
      ties += 1
    elsif (user_choice == "Камінь" && comp_choice == "Ножиці") ||
          (user_choice == "Ножиці" && comp_choice == "Папір") ||
          (user_choice == "Папір" && comp_choice == "Камінь")
      puts "Ви перемогли!"
      user_wins += 1
    else
      puts "Комп'ютер переміг!"
      comp_wins += 1
    end
    
    puts "\n--- Статистика ---"
    puts "Раундів зіграно: #{total_rounds}"
    puts "Перемог користувача: #{user_wins}"
    puts "Перемог комп'ютера: #{comp_wins}"
    puts "Нічиїх: #{ties}"
    puts "------------------"
  end
end

if __FILE__ == $0
  play_rps
end
