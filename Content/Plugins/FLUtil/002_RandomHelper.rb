#===============================================================================
#
# RandomHelper creates a class who helps scripters to do random operations.
#
#== EXAMPLES ===================================================================
#
# Simple Pokémon example:
#  
#  helper = PokemonRandomHelper.new
#  helper.add(3, :RATTATA)
#  helper.add(1, :SPEAROW)
#  helper.add(1, :EKANS)
#  pbAddPokemon(helper.get, 10)
#  
# In this example, player have 60% of receiving a Rattata, 20% for Spearow and
# 20% for Ekans. If a single pokémon name is misspeled, the helper throws an
# error, so you don't need to test all results.
# 
# Item, more complex example:
#  
#  helper = ItemRandomHelper.new
#  # Throws an error if total isn't 100
#  helper.require_weight = 100
#  helper.allow_nil = true
#  helper.allow_repeat = true
#  helper.add(10.5, :POTION)
#  # 3% for total. 1% for each item
#  helper.add_range(3, [:AWAKENING,:ANTIDOTE,:BURNHEAL])
#  # 2% for each item. 6% for total. 
#  helper.add_copying_weight(2, [:POKEBALL,:GREATBALL,:ULTRABALL])
#  helper.add(80.5, nil)
#  item = helper.get($game_variables[99]/100.0)
#  if item
#    pbItemBall(item)
#  else
#    pbMessage("Nothing found.")
#  end
#
# Proc example with seed example below. Since the main_seed was set, the first 3
# results will be (in order): Do nothing, Show "Hello World!" and rain.
#  
#  helper = RandomHelper.new
#  helper.add(3, proc{})                              # Do nothing
#  helper.add(1, proc{$game_screen.weather(1, 9, 0)}) # Rain
#  helper.add(1, proc{print("Hello World!")})         # Show "Hello World!"
#  helper.main_seed = 42
#  helper.get.call
#  helper.get.call
#  helper.get.call
#
#== NOTES ======================================================================
#
# helper.get also accept an seed between 0 and 1 (same seed, same results). You
# can set an integer seed for to entire class (like 'helper.main_seed = 42'), to
# always draw the values in the same sequence, but it only works with 
# MKXP/newer ruby.
#
# You can use helper.get_percentage(value) for getting a value percentage
# chance.
#
# For items, you can user helper.average_sell_price for average sell price.
#
#===============================================================================

# Base ruby class. This isn't Essentials/RPG Maker XP dependent.
# This class can be used for any value.
class RandomHelper
  attr_accessor :require_weight
  attr_accessor :allow_repeat
  attr_accessor :allow_nil

  def initialize
    @allow_repeat = false
    @allow_nil = false
    @total_weight_dirty = true
    @weights_values = []
    @random_instance = nil # only used with main_seed
  end

  # Doesn't work with older ruby.
  def main_seed=(value)
    @random_instance = EsBridge.new_random(value)
  end

  def main_seed
    return @random_instance ? @random_instance.seed : nil
  end

  def add(weight, value)
    if !@allow_nil && value==nil
      raise ArgumentError, "RandomHelper received nil value."
    end
    if !@allow_repeat && @weights_values.find_index{|wv| wv[1] == value }
      raise ArgumentError, "RandomHelper #{value} already included."
    end
    @weights_values.push([weight, value])
    @total_weight_dirty = true
  end

  def get(draw_seed = nil)
    if !draw_seed
      draw_seed = @random_instance ? @random_instance.rand : rand(0)
    end
    raise "RandomHelper is empty." if total_weight == 0
    if !fulfill_require_weight?
      raise "RandomHelper total_height is #{total_weight}, expected #{@require_weight}."
    end
    if draw_seed  > 1
      raise RangeError, "draw_seed  is #{draw_seed }. draw_seed s should be between 0 and 1 (inclusive)."
    end
    draw_seed -=0.000001 if draw_seed ==1 # small fix for 1 limit
    count = 0
    for weight_value in @weights_values
      count += weight_value[0]/total_weight.to_f
      return weight_value[1] if draw_seed  < count
    end
    raise "Unexpected result!"
  end

  def total_weight
    if @total_weight_dirty
      @cached_total_weight = 0
      for weight_value in @weights_values
        @cached_total_weight+=weight_value[0]
      end
      @total_weight_dirty = false
    end
    return @cached_total_weight
  end

  def fulfill_require_weight?
    return !@require_weight || @require_weight<=0 || ((total_weight - @require_weight).abs < 0.001)
  end

  def get_percentage(value)
    counted_weight=0
    for weight_value in @weights_values
      counted_weight += weight_value[0] if weight_value[1]==value
    end
    return 100.0*counted_weight/total_weight
  end
  
  # Same as calling "add" for each array item.
  def add_copying_weight(weight, array)
    for value in array
      add(weight, value)
    end
  end
  
  # Same as add_copying_weight, but weight is divided by array size.
  def add_range(weight, array)
    add_copying_weight(weight/array.size.to_f, array)
  end
end

class GameDataRandomHelper < RandomHelper
  def add(weight, value)
    if value && @game_data && !EsBridge.game_data_exists?(@game_data, value)
      raise TypeError, "#{value} isn't a #{@game_data}"
    end
    super(weight, value)
  end
end

class PokemonRandomHelper < GameDataRandomHelper
  def initialize
    if EsBridge::IS_ESSENTIALS
      @game_data = EsBridge::MAJOR_VERSION<19 ? PBSpecies : GameData::Species
    end
    super
  end
end

# Works with RPG Maker XP (use numeric ids)
class ItemRandomHelper < GameDataRandomHelper
  def initialize
    if EsBridge::IS_ESSENTIALS
      @game_data = EsBridge::MAJOR_VERSION<19 ? PBItems : GameData::Item
    end
    super
  end

  def add(weight, value)
    if !EsBridge::IS_ESSENTIALS && value
      if !value.is_a?(Integer)
        raise TypeError, "#{value} should be a numeric id!"
      end
      if value >= $data_items.size
        raise RangeError, "#{value} isn't a valid id!"
      end
    end
    super(weight, value)
  end

  def average_buy_price
    return average_price(false)
  end
  
  def average_sell_price
    return average_price(true)
  end

  def average_price(is_sell_price)
    counted_price=0
    for weight_value in @weights_values
      next if !weight_value[1]
      counted_price += price(weight_value[1], is_sell_price)*weight_value[0]
    end
    return counted_price/total_weight.to_f
  end
  
  def price(item, is_sell_price)
    return is_sell_price ? EsBridge.item_sell_price(item) : EsBridge.item_buy_price(item)
  end
end
