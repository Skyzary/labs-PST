def word_stats(text)
  words = text.scan(/\b\w+\b/)
  word_count = words.length
  longest_word = words.max_by { |word| word.length }
  unique_words = words.map(&:downcase).uniq.length

  puts "Всього слів: #{word_count}"
  puts "Найдовше слово: #{longest_word}"
  puts "Унікальних слів: #{unique_words}"

  {
    word_count: word_count,
    longest_word: longest_word,
    unique_words: unique_words
  }
end

if __FILE__ == $0
  text = "Ruby is fun and ruby is powerful"
  puts "Текст: #{text}"
  word_stats(text)
end
