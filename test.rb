# frozen_string_literal: true

require_relative 'lib/LFA'

config = LFA::Router::Config.parse('config.yaml')
pp(here: "GET /api/country", function: config.dig("/api/country", "GET"))
pp(here: "GET /api/language", function: config.dig("/api/language", "GET"))
pp(here: "PUT /api/language", function: config.dig("/api/language", "PUT"))
pp(here: "GET /api/data/csv", function: config.dig("/api/data/csv", "GET"))
pp(here: "GET /api/data/json", function: config.dig("/api/data/json", "GET"))

