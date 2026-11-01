#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'menu'

# Точка входу в програму "Морський бій"
if __FILE__ == $PROGRAM_NAME
  menu = Battleship::Menu.new
  menu.run
end
