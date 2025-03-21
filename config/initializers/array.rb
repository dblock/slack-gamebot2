# frozen_string_literal: true

class Array
  def and
    join_with 'and'
  end

  def or
    join_with 'or'
  end

  def same?
    uniq.length == 1
  end

  private

  def join_with(separator)
    if count > 1
      "#{self[0..-2].join(', ')} #{separator} #{self[-1]}"
    else
      first
    end
  end
end
