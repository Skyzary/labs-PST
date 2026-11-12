# frozen_string_literal: true

module Battleship
  # Базовий клас помилки гри
  class GameError < StandardError; end

  # Помилка некоректного формату координат
  class InvalidCoordinateError < GameError; end

  # Помилка повторного пострілу в клітинку
  class CellAlreadyHitError < GameError; end

  # Помилка некоректного розміщення корабля
  class InvalidShipPlacementError < GameError; end
end
