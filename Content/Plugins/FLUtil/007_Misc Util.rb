#===============================================================================
#
# This file adds several methods to ruby classes, utilities ones to FLUtil and
# some small ones to global scope
#
#== HOW TO USE =================================================================
#
# Look at the methods and the instructions.
#
#== NOTES ======================================================================
#
# Some methods are just ruby methods from 1.8.7 and up, so they can be used in
# RGSS Player.
#
#===============================================================================


#-------------------------------------------------------------------------------
# Ruby
#-------------------------------------------------------------------------------

def m_defined?(sym)
  return Object.private_method_defined?(sym) || Object.public_method_defined?(sym)
end

class Numeric
  # Linearly interpolates between a and b by self.
  #
  # The parameter self is clamped to the range [0, 1].
  # When self = 0 returns a.
  # When self = 1 returns b.
  # When self = 0.5 returns the midpoint of a and b.
  def lerp(a, b)
    return a*(1.0-self)+b*self
  end

  # Calculates the linear parameter (lerp) that produces the interpolant value
  # within the range [a, b].
  #
  # The a and b values define the start and end of the line. Value is a location
  # between a and b. 
  # Subtract a from both a and b and self to make a', b' and self'. 
  # This makes a' to be zero and b' and self' to be reduced. Finally divide
  # self' by b'.
  # This gives the inverse_lerp amount.
  def inverse_lerp(a, b)
    return (self.to_f-a)/(b-a)
  end

  # From Ruby 2.4 
  # Camps the given value between the given minimum and maximum values.
  # Returns the given value if it is within the min and max range.
  def clamp(min, max)
    return [max,[min,self].max].min
  end unless method_defined? :clamp

  # same as .clamp(0,1)
  def clamp01
    return self.clamp(0,1);
  end

  # From Ruby 2.6.1 (or older)
  # Returns the largest number less than or equal to float with a precision of
  # ndigits decimal digits (default: 0).
  def floor_args(ndigits=0)
    return self.floor if ndigits==0
    return (self*(10**ndigits)).floor.to_f/(10**ndigits)
  end

  # Format to max of decimal digits (%g and %f). Default is 2
  # Won't work with large numbers.
  # (e.g. 1   -> format_to_gf(3) -> "1")
  # (e.g. 12.3456  -> format_to_gf(3) -> "12.346")
  def format_to_gf(digits=2)
    return "%g" % ("%.#{digits}f" % self)
  end
end

module Enumerable
  # From Ruby 1.8.7
  # Returns the elements for which the block returns the maximum values.
  # With a block given and no argument, returns the element for which the block
  # returns the maximum value.
  def max_by(number = nil)
    return value_by(number, true, &proc)
  end unless method_defined? :max_by

  # From Ruby 1.8.7
  # Returns the elements for which the block returns the minimum values.
  # With a block given and no argument, returns the element for which the block
  # returns the minimum value.
  def min_by(number = nil)
    return value_by(number, false, &proc)
  end unless method_defined? :min_by

  # From Ruby 1.8.7
  # Returns first n elements from enum.
  def take(number)
    ret = []
    for item in self
      ret.push(item)
      break if ret.size == number
    end
    return ret
  end unless method_defined? :take

  # From Ruby 1.8.7
  # Passes elements to the block until the block returns nil or false, then
  # stops iterating and returns an array of all prior elements.
  def take_while
    ret = []
    for item in self
      break if !yield(item)
      ret.push(item) 
    end
    return ret
  end unless method_defined? :take_while

  # From Ruby 1.8.7
  # Drops first n elements from enum, and returns rest elements in an array.
  def drop
    ret = []
    for item in self
      if number>0
        number-=1
        next
      end
      ret.push(item)
    end
    return ret
  end unless method_defined? :drop

  # From Ruby 1.8.7
  # Drops elements up to, but not including, the first element for which the
  # block returns nil or false and returns an array containing the remaining
  # elements.
  def drop_while
    ret = []
    for item in self
      ret.push(item) if !ret.empty? || !yield(item)
    end
    return ret
  end unless method_defined? :drop_while

  # User internally by max_by and min_by
  def value_by(number = nil, use_biggest=true)
    ret = Array.new(number ? number : 1)
    notorious_values = ret.clone
    for item in self
      for i in 0...ret.size
        current_value = block_given? ? yield(item) : item
        next if notorious_values[i] && (
          (use_biggest && notorious_values[i]>=current_value) || 
          (!use_biggest && notorious_values[i]<=current_value)
        )
        if i < ret.size-1 # shift next values
          for j in 0...(ret.size-1-i)
            j_reverse = ret.size-1-j
            notorious_values[j_reverse] = notorious_values[j_reverse-1]
            ret[j_reverse] = ret[j_reverse-1]
          end
        end
        ret[i] = item
        notorious_values[i] = current_value
        break
      end
    end
    return number ? ret : ret[0]
  end
  private :value_by

  # From Ruby 1.9.1
  # Returns the index of the first object in self such that is == to obj.
  # If a block is given instead of an argument, returns first object for which
  # block is true. 
  # Returns nil if no match is found.
  if !method_defined?(:find_index)
    def find_index(arg=nil)
      for i in 0...length
        return i if (block_given? && yield(self[i])) || (!block_given? && arg==self[i])
      end
      return nil
    end
    alias :index :find_index
  end

  # From Ruby 1.9.1 rindex with args
  # Returns the index of the last object in self == to obj.
  # If a block is given instead of an argument, returns first object for which
  # block is true. 
  # Returns nil if no match is found.
  def find_rindex(arg=nil)
    for i in 0...length
      r_index =  length - i - 1 
      return r_index if (block_given? && yield(self[r_index])) || (!block_given? && arg==self[r_index])
    end
    return nil
  end

  # From Ruby 1.9.1
  # Returns the number of elements.
  # If an argument is given, counts the number of elements which equal obj
  # using ==.
  # If a block is given, counts the number of elements for which the block
  # returns a true value.
  def count(*args)
    ret = 0
    for value in self
      if (args.size == 0 && !block_given?) || (args.size > 0 && args[0]==value) || (block_given? && yield(value))
        ret+=1
      end
    end
    return ret
  end unless method_defined? :count

  # From Ruby 2.1.10
  # Returns the result of interpreting enum as a list of [key, value] pairs.
  # If a block is given, the results of the block on each element of the enum
  # will be used as pairs.
  def to_h
    ret = {}
    for val in self
      new_value = block_given? ? yield(val) : val
      ret[new_value[0]] = new_value[1]
    end
    return ret
  end unless method_defined? :to_h
  
  # From Ruby 2.4
  # Returns the sum of elements in an Enumerable.
  # If a block is given, the block is applied to each element before addition.
  # If enum is empty, it returns init.
  def sum(init=0)
    ret = init
    for value in self
      ret+=block_given? ? yield(value) : value
    end
    return ret
  end unless method_defined? :sum
end

class Array 
  # From older Ruby, deleted in 1.9
  # Returns the number of non-nil elements in self.
  # May be zero.
  def nitems
    return count{|x| x != nil}
  end unless method_defined? :nitems

  # Switch two elements indexes
  def switch_at(index1, index2)
    tmp = self[index2]
    self[index2] = self[index1]
    self[index1] = tmp
  end
  
  # Deletes first item from self that are equal to obj.
  # If a block is given instead of an argument, deletes first object for which 
  # block is true.
  # Returns if item is deleted. 
  def delete_first(obj=nil)
    index = block_given? ? self.find_index(&proc) : self.index(obj)
    return false if !index
    self.delete_at(index)
    return true
  end

  # Compare two arrays by each value. Return true if they are equals.
  # Compares order.
  def values_equals?(other_array)
    return false if self.size != other_array.size
    for i in 0...self.size
      return false if self[i] != other_array[i]
    end
    return true
  end
end

class Hash
  # Store new value if hash doesn't contains the key
  def store_if_new(key, value)
    return if has_key?(key)
    self[key] = value
  end
end

class Range
  # Returns a random value from range
  def random
    return rand(self.last-self.first).floor+self.first
  end
end

class Dir
  # Ensure that the folder path exists, creating if didn't exists
  def self.ensure_path(path)
    current_path = ""
    for dir in path.split("/")
      current_path+=dir+"/"
      Dir.mkdir(current_path) unless File.exist?(current_path)
    end
  end

  # Same as ensure_path, but it doesn't count last name.
  def self.ensure_file_path(file_path)
    split_path = file_path.split("/")
    split_path.pop
    return ensure_path(split_path.join("/"))
  end
end

# Formats the other parameters by replacing {1}, {2}, etc. with those
# placeholders.
def _INTL(*arg)
  #begin
  #  string = MessageTypes.getFromHash(MessageTypes::SCRIPT_TEXTS, arg[0])
  #rescue
    string = arg[0]
  #end
  string = string.clone
  (1...arg.length).each do |i|
    string.gsub!(/\{#{i}\}/, arg[i].to_s)
  end
  return string
end if !m_defined?(:_INTL)

# Formats the other parameters by replacing {1}, {2}, etc. with those
# placeholders.
# This version acts more like sprintf, supports e.g. {1:d} or {2:s}
def _ISPRINTF(*arg)
  #begin
  #  string = MessageTypes.getFromHash(MessageTypes::SCRIPT_TEXTS, arg[0])
  #rescue
    string = arg[0]
  #end
  string = string.clone
  (1...arg.length).each do |i|
    string.gsub!(/\{#{i}\:([^\}]+?)\}/) { |_m| next sprintf("%" + $1, arg[i]) }
  end
  return string
end if !m_defined?(:_ISPRINTF)

def _I(str, *arg)
  return _MAPINTL($game_map.map_id, str, *arg)
end if !m_defined?(:_I)

def _MAPINTL(_mapid, *arg)
  string = arg[0]
  #string = MessageTypes.getFromMapHash(_mapid, arg[0])
  string = string.clone
  (1...arg.length).each do |i|
    string.gsub!(/\{#{i}\}/, arg[i].to_s)
  end
  return string
end if !m_defined?(:_MAPINTL)

#-------------------------------------------------------------------------------
# RGSS
#-------------------------------------------------------------------------------

class Rect
  # Same as x
  def x_min
    return x
  end

  # Same as y
  def y_min
    return y
  end

  # x+width
  def x_max
    return x+width
  end

  # y+height
  def y_max
    return y+height
  end
  
  def x_range_inclusive
    return x_min..x_max
  end
  
  def x_range_exclusive
    return x_min...x_max
  end
  
  def y_range_inclusive
    return y_min..y_max
  end
  
  def y_range_exclusive
    return y_min...y_max
  end

  # Creates a rectangle from min/max coordinate values.
  def self.new_min_max(x_min, y_min, x_max, y_max)
    return Rect.new(x_min, y_min, x_max - x_min, y_max - y_min)
  end

  def contains?(x1, y1)
    return x1 >= x && x1 < x_max && y1 >= y && y1 < y_max
  end unless method_defined? :contains?
end

class Color
  def [](index)
    return case index
      when 0; self.red
      when 1; self.green
      when 2; self.blue
      when 3; self.alpha
      else; raise IndexError, "Get index #{index} in color object"
    end
  end

  def []=(index, value)
    case index
      when 0; self.red = value
      when 1; self.green = value
      when 2; self.blue = value
      when 3; self.alpha = value
      else; raise IndexError, "Set index #{index} in color object"
    end
  end

  # Sum all values by other (Color)
  def +(other)
    return Color.new(red+other.red, green+other.green, blue+other.blue, alpha+other.alpha)
  end

  # Subtract all values by other (Color)
  def -(other)
    return Color.new(red-other.red, green-other.green, blue-other.blue, alpha-other.alpha)
  end

  # Multiply all values by value (number)
  def *(value)
    return Color.new(red*value, green*value, blue*value, alpha*value)
  end

  # Divide all values by value (number)
  def /(value)
    return Color.new(red/value, green/value, blue/value, alpha/value)
  end

  def to_a
    return [self[0], self[1], self[2], self[3]]
  end

  def self.from_a(array)
    if array.size == 4
      return Color.new(array[0], array[1], array[2], array[3])
    else
      return Color.new(array[0], array[1], array[2])
    end
  end

  # Linearly interpolates between a and b by t.
  #
  # The parameter t is clamped to the range [0, 1].
  # When t = 0 returns a.
  # When t = 1 returns b.
  # When t = 0.5 returns the midpoint of a and b.
  def self.lerp(a, b, t)
    return Color.new(
      t.lerp(a.red,b.red),
      t.lerp(a.green,b.green),
      t.lerp(a.blue,b.blue),
      t.lerp(a.alpha,b.alpha)
    )
  end
end

class Tone
  def [](index)
    return case index
      when 0; self.red
      when 1; self.green
      when 2; self.blue
      when 3; self.gray
      else; raise IndexError, "Get index #{index} in tone object"
    end
  end

  def []=(index, value)
    case index
      when 0; self.red = value
      when 1; self.green = value
      when 2; self.blue = value
      when 3; self.gray = value
      else; raise IndexError, "Set index #{index} in tone object"
    end
  end

  # Sum all values by other (Tone)
  def +(other)
    return Tone.new(red+other.red, green+other.green, blue+other.blue, gray+other.gray)
  end

  # Subtract all values by other (Tone)
  def -(other)
    return Tone.new(red-other.red, green-other.green, blue-other.blue, gray-other.gray)
  end

  # Multiply all values by value (number)
  def *(value)
    return Tone.new(red*value, green*value, blue*value, gray*value)
  end

  # Divide all values by value (number)
  def /(value)
    return Tone.new(red/value, green/value, blue/value, gray/value)
  end

  def to_a
    return [self[0], self[1], self[2], self[3]]
  end

  def self.from_a(array)
    if array.size == 4
      return Tone.new(array[0], array[1], array[2], array[3])
    else
      return Tone.new(array[0], array[1], array[2])
    end
  end

  # Linearly interpolates between a and b by t.
  #
  # The parameter t is clamped to the range [0, 1].
  # When t = 0 returns a.
  # When t = 1 returns b.
  # When t = 0.5 returns the midpoint of a and b.
  def self.lerp(a, b, t)
    return Tone.new(
      t.lerp(a.red,b.red),
      t.lerp(a.green,b.green),
      t.lerp(a.blue,b.blue),
      t.lerp(a.gray,b.gray)
    )
  end
end

# Shortcut to easily echoln data, like in an array.
# So you can use 'ep("Value",42)' to easily print in log.
def ep(*args)
  for arg in args
    echoln(arg.inspect)
  end
end

# Same as above, but using a single line format like A:B, C:D, E:F...
# eps means "echo print single".
def eps(*args)
  if args.size==1
    echoln(args[0].inspect)
    return
  end
  s = ""
  for i in 0...args.size
    s += i%2==0 ? "#{args[i].inspect}: " : "#{args[i].inspect}, "
  end
  echoln(s)
end

module FLUtil
  module_function

  # Format a list into string, in a way that makes sense reading.
  # (format_string_list(["John", "Jack", "Joe"], "{1} and {2}") -> "John, Jack and Joe")
  # (format_string_list(["Jack", "Joe"], "{1} and {2}") -> "Jack and Joe")
  # (format_string_list(["Joe"], "{1} and {2}") -> "Joe")
  def format_string_list(list, mask)
    ret = ""
    for i in 0...list.size
      item = list[list.size-i-1]
      ret = case i
        when 0; item
        when 1; _INTL(mask,item,ret)
        else;   item+", "+ret
      end
    end
    return ret
  end

  # Format Time
  # mode: 1 = hours, 2 = hours and minutes, 3 = hours, minutes and seconds.
  # Default mode is 3.
  # (e.g. format_time_from_seconds(3700) -> "01:01:40")
  # (e.g. format_time_from_seconds(3700, 2) -> "01:01")
  def format_time_from_seconds(total_seconds, mode=3)
    ret = sprintf("%02d",total_seconds/(60*60))
    ret = sprintf("%s:%02d", ret, total_seconds/60 % 60) if mode >= 2
    ret = sprintf("%s:%02d", ret, total_seconds % 60) if mode >= 3
    return ret
  end

  # Same as format_time_from_seconds, but with minutes.
  def format_time_from_minutes(total_minutes, mode=3)
    return format_time_from_seconds(total_minutes*60, mode)
  end

  # Inform a direction code (as numpad number), returns the movement array.
  # (e.g. direction_code_to_array(2) -> [0,1])
  # (e.g. direction_code_to_array(9) -> [1,-1])
  def direction_code_to_array(direction)
    if 10>direction && direction>0
      return [(direction-1)%3-1, 1-(direction-1)/3]
    end
    return [0,0]
  end
  
  # Inform a direction code (as numpad number), returns the opposite code.
  # (e.g. reverse_direction_code(2) -> 8)
  # (e.g. reverse_direction_code(9) -> 1)
  def reverse_direction_code(direction)
    return 10>direction && direction>0 ? 10-direction : 0
  end
  
  # Check if is running by joiplay Android app.
  def has_running_by_joiplay?
    return $joiplay!=nil && $joiplay!=false
  end

  def has_event_on_pos?(x,y)
    return $game_map.events.values.find{|e| e.x==x && e.y==y} != nil
  end

  # Set sprites with keys in hash as visible if they exists.
  def set_visible(sprites, keys, value)
    for key in keys
      next if !sprites[key]
      sprites[key].visible = value
    end
  end

  # Returns left X coordinate where the pixel column isn't empty
  def find_bitmap_left(bitmap)
    return 0 if !bitmap
    for j in 0...bitmap.width
      for i in 0...bitmap.height
        return j if bitmap.get_pixel(j,i).alpha>0
      end
    end
    return 0
  end
  def find_bitmap_right(bitmap)
    return 0 if !bitmap
    for j in 1..bitmap.width
      for i in 0...bitmap.height
        return bitmap.width-j if bitmap.get_pixel(bitmap.width-j,i).alpha>0
      end
    end
    return 0
  end
  def find_bitmap_top(bitmap)
    return 0 if !bitmap
    for i in 0...bitmap.height
      for j in 0...bitmap.width
        return i if bitmap.get_pixel(j,i).alpha>0
      end
    end
    return 0
  end
  def find_bitmap_bottom(bitmap)
    return 0 if !bitmap
    for i in 1..bitmap.height
      for j in 0...bitmap.width
        return bitmap.height-i if bitmap.get_pixel(j,bitmap.height-i).alpha>0
      end
    end
    return 0
  end
end

#-------------------------------------------------------------------------------
# Essentials
#-------------------------------------------------------------------------------

module FLUtil
  module_function

  # Returns type name with a divider (default is "/"). Accept two params or
  # array.
  # (e.g. type_string(:FIRE) -> "Fire")
  # (e.g. type_string(:FIRE,:FIRE) -> "Fire")
  # (e.g. type_string([:FIRE,:WATER],nil," and ") -> "Fire and Water")
  def type_string(type, type2=nil, divider="/")
    if type.is_a?(Array)
      type1 = type[0]
      type2 = type[1]
    else
      type1 = type
    end
    ret = EsBridge.type_name(type1)
    ret += divider + EsBridge.type_name(type2) if type2 && type1!=type2
    return ret
  end

  # Easy choice system where last option returns -1
  def message(message, commands=nil)
    if commands
      ret = EsBridge.message(message,commands,commands.size)
    else
      ret = EsBridge.message(message)
    end
    ret = -1 if commands && commands.size==ret+1
    return ret
  end

  # Gives money with message and SFX
  def receive_money(quantity)
    EsBridge.money += quantity
    EsBridge.message(_INTL("\\se[]Obtained ${1}!\\se[Mart buy item]\\wt[16]",quantity))
  end

  # Returns an array with all current player pokémon in party, PC and Day Care.
  # Fusioned pokémon doesn't count, only the fusion.
  # Purify Chamber isn't checked.
  # Include eggs checks for unhatched pokémon.
  def all_player_pokemon(include_eggs=false)
    ret = EsBridge.player.party+[]
    pbEachPokemon{|pokemon,_box| ret.push(pokemon) }
    for i in 0..1
      ret.push(EsBridge.day_care_pokemon(i)) if EsBridge.day_care_pokemon(i)
    end
    ret.delete_if {|pk| pk.egg? } if !include_eggs
    return ret
  end 

  # Damage every pokémon, but never K.O. a pokémon (they remain with 1 of HP)
  # Displays a message if show_message is true.
  def damage_party(damage, show_message)
    someoneDamaged = false
    for pokemon in EsBridge.player.party
      next if pokemon.egg? || pokemon.hp<=1 
      pokemon.hp = [pokemon.hp-damage, 1].max
      someoneDamaged = true
    end
    if show_message && someoneDamaged
      EsBridge.message(_INTL("Party received {1} damage!",damage))
    end
  end

  # pbChoosePokemon for species array (or single species)
  def choose_species(species, variable_number=1, name_variable_number=2)
    species_array = species.is_a?(Array) ? species : [species]
    return pbChoosePokemon(variable_number, name_variable_number, proc{|pk| 
      !pk.egg? && species_array.include?(pk.species)
    })
  end

  # Give Egg with message.
  # Print an error message if player already have 6 pokémon.
  def receive_egg(fSpecies)
    EsBridge.message(_INTL("\\me[]Obtained Egg!\\me[Egg get]\1"))
    print("ERROR! Egg cannot be added!") if EsBridge.player.party.size==6
    pbGenerateEgg(fSpecies)
  end
  
  # +1 in form of selected pokémon. Return to form 0 if surpass the limit.
  # If limit is nil, use the form limit
  # Returns if form was swapped
  def swap_form(pokemon, limit=nil)
    return false if pokemon.egg?
    limit ||= last_form_index(pokemon.species)
    return false if limit==0
    pokemon.form = pokemon.form==limit ? 0 : pokemon.form + 1
    return true
  end

  # Same as swap_form, but change the entire party when species match.
  def swap_species_form(species) 
    ret=false
    limit = last_form_index(species)
    for pokemon in EsBridge.player.party
      if !pokemon.egg? && pokemon.species==species && swap_form(pokemon,limit)
        ret=true
      end
    end
    return ret
  end

  # Returns the last form index
  def last_form_index(species)
    ret = 1
    ret += 1 while species != EsBridge.species_form(species, ret)
    ret -= 1
    return ret
  end

  # Ask player to select a valid pokémon following valid_form_proc.
  # Then, +1 in form of selected pokémon. Return to form 0 if surpass the limit.
  def ask_change_form(valid_form_proc)
    pbChoosePokemon(1,2,valid_form_proc)
    return false if pbGet(1)<0
    swap_form(EsBridge.player.party[pbGet(1)])
    return true
  end

  # Checks bag and PC
  def total_item_quantity(item)
    ret = EsBridge.item_quantity(item)
    if $PokemonGlobal.pcItemStorage
      ret += $PokemonGlobal.pcItemStorage.pbQuantity(item)
    end
    return ret
  end

  def has_item_at_bag_or_pc?(item)
    return total_item_quantity(item) > 0
  end

  def has_item_at_bag_or_pc_or_hold?(item)
    return has_item_at_bag_or_pc?(item) || all_player_pokemon.find{|pk| pk.item==item} != nil
  end

  def receive_item_at_bag_or_pc(item, quantity=1, silent=false)
    if (silent && !EsBridge.add_item(item, quantity)) || (!silent && !EsBridge.receive_item(item, quantity))
      $PokemonGlobal.pcItemStorage ||= PCItemStorage.new
      if EsBridge.add_item_pc(item,quantity)
        Kernel.pbMessage(_INTL("Item was sent into your PC.")) if !silent
      else
        return false
      end
    end
    return true
  end

  # Like pbChooseItem, but works with proc for filter items.
  def choose_item(var = 0, &proc)
    ret = nil
    pbFadeOutIn do
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, $bag)
      ret = screen.pbChooseItemScreen(&proc)
    end
    $game_variables[var] = ret || :NONE if var > 0
    return ret
  end
end

# Plane who scrolls
class ScrollPlane < AnimatedPlane
  attr_accessor :x_limit
  attr_accessor :y_limit

  def initialize(viewport)
   super(viewport)
   @x_limit = 64
   @y_limit = 64
   @float_ox = 0
   @float_oy = 0
  end

  # Speed is per second
  def set_speed(x_speed, y_speed)
    @x_speed = x_speed
    @y_speed = y_speed
    return self
  end

  def update
    super
    if @x_speed
      @float_ox = wrap_value(@float_ox + @x_speed*EsBridge.delta, @x_limit)
    end
    if @y_speed
      @float_oy = wrap_value(@float_oy + @y_speed*EsBridge.delta, @y_limit)
    end
    self.ox = @float_ox.round
    self.oy = @float_oy.round
  end

  def wrap_value(value, limit)
    value = value-limit if value>=limit
    value = value+limit if value<=-limit
    return value
  end

  def setBitmap(file, hue=0)
    super(file, hue)
    return if !@bitmap
    @x_limit = @bitmap.width
    @y_limit = @bitmap.height
  end
end if defined?(AnimatedPlane)