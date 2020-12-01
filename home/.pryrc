require 'time'

class Time
  def to_us
    strftime('%m/%d/%Y %I:%M %p')
  end
end
