class PlanEntry
  attr_accessor :detail,:location,:companions,:important,:year, :month, :day, :hour
  def initialize(detail='', location='', companions=[], important=false,
                 year=Time.new.year.to_i, month=Time.new.month.to_i, day=Time.new.day.to_i, hour = Time.new.hour.to_i)
    @detail = detail.strip;
    @location = location
    @companions = companions
    @important = important
    @year = year
    @month = month
    @day = day
    @hour = hour
  end
end