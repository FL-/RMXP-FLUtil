#===============================================================================
#
# Variables Switches Alias provides a shorter and more readable way (instead of 
# magic numbers) to call switches and variables.
#
#== INSTALLATION ===============================================================
#
# Define your switches and variables in the 004_MyAlias.rb file, you don't
# need to insert all, just the ones that you want to call.
#
#== HOW TO USE =================================================================
#
# Call '$gs[:YOUR_KEY_HERE]' or '$gv[:YOUR_KEY_HERE]' to read or write 
# switches/variables values. If you use a non-existent key, it raises an error.
#
#== EXAMPLES ===================================================================
#
# Original code to remove an apricorn:
#
#  $bag.remove(pbGet(8))
#  data = GameData::Item.get(pbGet(8))
#  pbSet(3, data.name)
# 
# With this script:
#  
#  $bag.remove($gv[:APRICORN_DELIVERED])
#  data = GameData::Item.get($gv[:APRICORN_DELIVERED])
#  $gv[:TEMP_PKMN_NAME] = data.name
#
# Or
#  
#  $bag.remove($gv[8])
#  data = GameData::Item.get($gv[8])
#  $gv[3] = data.name
#
#== NOTES ======================================================================
#
# 'code_per_key' can be used to return switch/variable number, so 
# '$gv[:TEMP].code_per_key' will return 1 (since it is variable 1). 
#
# You can also use numbers as keys. This makes a lot shorter,  '$gv[1]' instead
# of '$game_variables[1]'. Using the below code, you can merge the Hash with
# numbers until 42:
#  
#  $gs = SwitchesAlias.new({
#    :STARTING_OVER  => 1  ,
#  }.merge(BaseVariablesSwitchesAlias.create_number_hash(42), true)
#
# In the class instantiation (.new), the second parameter is if the class allows
# different keys with same values. When true, you can bind multiple names for a
# term (to keep easily remembering the keys), when false, you can't, and is 
# harder to accidentally assign a wrong number to a key.
#
#===============================================================================

class BaseVariablesSwitchesAlias
  attr_accessor :code_per_key

  def initialize(code_per_key, allow_repeated_values)
    @code_per_key = code_per_key
    @allow_repeated_values = allow_repeated_values
    check_hash
  end

  def [](key)
    check_key(key)
  end

  def []=(key, _value)
    check_key(key)
  end

  def check_key(key)
    raise "key #{key} invalid for #{self.class.name}." if !@code_per_key.has_key?(key)
  end

  def check_hash
    return if @allow_repeated_values
    values = @code_per_key.values
    repeatedValue = values.detect{ |e| values.count(e) > 1 }
    if repeatedValue
      raise ArgumentError, "#{@code_per_key.select{|_key,value| repeatedValue==value}.inspect} while allow_repeated_values=false"
    end
  end

  # Used for easily create a short way to call variables indexes
  def self.create_number_hash(last_value)
    ret = {}
    for i in 1..last_value
      ret[i] = i
    end
    return ret
  end
end

class SwitchesAlias < BaseVariablesSwitchesAlias
  def [](key)
    super(key)
    return $game_switches[@code_per_key[key]]
  end

  def []=(key, value)
    super(key, value)
    raise TypeError, "Value #{value} for key #{key} isn't a boolean." if value!=true && value!=false
    $game_switches[@code_per_key[key]] = value
  end
end

class VariablesAlias < BaseVariablesSwitchesAlias
  def [](key)
    super(key)
    return $game_variables[@code_per_key[key]]
  end

  def []=(key, value)
    super(key, value)
    $game_variables[@code_per_key[key]] = value
  end
end