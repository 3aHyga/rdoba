#!/usr/bin/ruby -KU
# frozen_string_literal: true

class String
  def fe
    if RUBY_VERSION < '1.9'
      self
    else
      return self unless Encoding.default_internal

      if frozen?
        dup.force_encoding(Encoding.default_internal || 'UTF-8').freeze
      else
        force_encoding(Encoding.default_internal || 'UTF-8')
      end
    end
  end
  alias fenc fe
end
