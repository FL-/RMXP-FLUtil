#===============================================================================
#
# Module who do a basic test in this script to check if several methods are
# working as expected.
#
#== HOW TO USE =================================================================
#
# Call 'echoln(FLUtil_Test.run(write_output_file))'. When write_output_file is
# true, generates also a txt file with the info in main folder. Default is 
# false.
#
#== NOTES ======================================================================
#
# More hard to test things like messages and sprites aren't tested. And not all
# features are tested.
#
#===============================================================================

# Code quickly made for testing
module FLUtil_Test
  module_function

  OUTPUT_FILE_PATH = "FLUtil_Test.txt"

  def run(write_output_file=false)
    ret=""
    begin
      ret += "\n" + run_general_test
      ret += "\n" + run_non_essentials_test if !EsBridge::IS_ESSENTIALS
      ret += "\n" + run_essentials_test if EsBridge::IS_ESSENTIALS
    rescue => e
      ret += "\n=============================\n"
      ret+="Error rescue - "+e.message+"\n--\n"+e.backtrace[0, 5].join("\n")
    end
    ret += "\n=============================\n"
    ret += ret.downcase.include?("error") ? "Error Found!" : "All tests look ok!"
    write_into_txt(OUTPUT_FILE_PATH, ret) if write_output_file
    return ret
  end

  def write_into_txt(file_path, text)
    File.open(file_path, "w"){|file| 
      file.write("Created at #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\n"+text)
    }
  end

  def run_general_test
    ret = "=== RUNNING GENERAL TESTS ==="

    ret += "\n"+assert(m_defined?(:m_defined?), "m_defined?")

    ret += "\n"+compare(2, [10,10,10,40].find_rindex(10), "find_rindex")

    ret += "\n"+compare(0.3, 3.inverse_lerp(0,10), "inverse_lerp")

    ret += "\n"+compare(12.3, 12.34.floor_args(1), "floor_args")

    ret += "\n"+compare("1.234", 1.2345.format_to_gf(3), "format_to_gf")

    array = [10,20,30]
    array.switch_at(0,2)
    ret += "\n"+compare([30, 20, 10], array, "Array.switch_at")

    array = [10,20,30]
    array.delete_first(20)
    ret += "\n"+compare([10,30], array, "Array.delete_first")

    ret += "\n"+assert(![10,20].values_equals?([20,10]), "Array.values_equals? order")

    ret += "\n"+assert([10,20].values_equals?([10,20]), "Array.values_equals? same")

    hash = {1=>10}
    hash.store_if_new(1,20)
    ret += "\n"+compare(10, hash[1], "Hash.store_if_new")

    ret += "\n"+compare(2, [10, nil, 20].nitems, "Array.nitems")

    ret += "\n"+assert(Rect.new(1,2,30,40).contains?(5,8), "Rect.contains?")

    ret += "\n"+compare(Rect.new_min_max(1,2,31,42), Rect.new(1,2,30,40), "Rect new min max")

    rect = Rect.new(1,1,2,3)
    ret += "\n"+assert(rect.x_range_inclusive.to_a.include?(rect.y_range_exclusive.random), "Rect random range")

    color = Color.from_a([10,20,30,40])
    for i in 0...4
      ret += "\n"+compare(
        color.to_a.map{|v| (v*1.5).floor}[i], Color.lerp(color, color*2, 0.5)[i], "Color compare Lerp #{i}"
      )
    end

    tone = Tone.from_a([10,20,30,40])
    tone2 = tone*2
    tone_result = tone.to_a.map{|v| (v*1.5).floor}
    for i in 0...4
      ret += "\n"+compare(tone_result[i], Tone.lerp(tone, tone2, 0.5)[i], "Tone compare Lerp #{i}")
    end

    ret += "\n"+compare(
      "John, Jack and Joe", 
      FLUtil.format_string_list(["John", "Jack", "Joe"], "{1} and {2}"), 
      "FLUtil.format_string_list"
    )

    ret += "\n"+compare("01:01:40", FLUtil.format_time_from_seconds(3700), "FLUtil.format_time_from_seconds")
    
    ret += "\n"+compare("01", FLUtil.format_time_from_minutes(61, 1), "FLUtil.format_time_from_minutes")

    ret += "\n"+compare([1,0], FLUtil.direction_code_to_array(6), "FLUtil.direction_code_to_array")

    ret += "\n"+compare(2, FLUtil.reverse_direction_code(8), "FLUtil.reverse_direction_code")

    ret += "\n"+assert(
      EsBridge.delta < 0.2, "Delta",
      "#{(EsBridge.delta * 1_000).format_to_gf(2)} ms", "#{EsBridge.delta} should be smaller!"
    )
    
    ret += "\n"+assert(
      EsBridge.play_time.is_a?(Numeric), "Play Time", "#{FLUtil.format_time_from_seconds(EsBridge.play_time)}"
    )

    ret += "\n"+compare("POTION", EsBridge.item_name(EsBridge::IS_ESSENTIALS ? :POTION : 1).upcase, "Item name")

    ret += "\n"+assert(!EsBridge.has_item?(EsBridge::IS_ESSENTIALS ? :HYPERPOTION : 8), "Has item")

    ret += "\n"+compare(0, EsBridge.item_quantity(EsBridge::IS_ESSENTIALS ? :HYPERPOTION : 8), "Item quantity")
    
    alias_test = VariablesAlias.new(
      {:TEMP => 22,:TEST => 21}.merge(BaseVariablesSwitchesAlias.create_number_hash(20)), true
    )
    ret += "\n"+compare(22, alias_test.code_per_key[:TEMP], "Variable Alias")
    ret += "\n"+compare(1, alias_test.code_per_key[1], "Variable Alias direct")

    return ret
  end

  def run_non_essentials_test
    ret = "=== RUNNING NON ESSENTIALS TESTS ==="

    helper = ItemRandomHelper.new
    helper.require_weight = 100
    helper.allow_nil = true
    helper.allow_repeat = true
    helper.add(10.5, 1)
    helper.add_range(3, [2, 3, 4]) # Some ids
    helper.add_copying_weight(2, [5,6,7]) # More ids
    helper.add(80.5, nil)
    helper.average_sell_price
    result = helper.get(0.13)
    ret += "\n" + compare(4, result, "ItemRandomHelper")

    return ret
  end

  def run_essentials_test
    ret = "=== RUNNING ESSENTIALS TESTS ==="
    
    t = Time.now
    EsBridge.wait(0.1)
    spent_time = Time.now - t
    ret += "\n"+assert(
      0.08 < spent_time && spent_time < 0.19, "Wait", 
      "EsBridge.wait(0.1) = #{spent_time}s wait", "#{spent_time} out of range!"
    )

    ret += "\n"+assert(EsBridge.player, "Player")

    ret += "\n"+assert([true, false].include?(EsBridge.time_shading), "Time Shading")

    species = :DEOXYS

    ret += "\n"+assert(EsBridge.species_sym_is_valid(species), "Species is Valid")
    
    if EsBridge::MAJOR_VERSION < 19
      ret += "\n"+compare("DEOXYS", EsBridge.species_name(getID(PBSpecies,species)).upcase, "Species Name")
    else
      ret += "\n"+compare("DEOXYS", EsBridge.species_name(species).upcase, "Species Name")
    end

    ret += "\n"+compare("DNA", EsBridge.species_category(species).upcase, "Species Category")

    ret += "\n"+assert(EsBridge.compare_type(EsBridge.species_types(species)[0],:PSYCHIC), "Species Type")
    
    ret += "\n"+compare(50, EsBridge.species_base_stats(species)[:SPECIAL_DEFENSE], "Species Base Stat SDEF")

    ret += "\n"+assert(EsBridge.species_count >= 649, "Species Count", "Count is #{EsBridge.species_count}")

    ret += "\n"+assert(
      EsBridge.species_icon_path(species), "Species Icon path", "Path is #{EsBridge.species_icon_path(species)}"
    )
    
    ret += "\n"+compare(100, EsBridge.maximum_level, "Species Max Level")
    
    ret += "\n"+compare("SPEED", EsBridge.stat_name(:SPEED).upcase, "Stat name")
    
    if EsBridge::MAJOR_VERSION >= 19
      ret += "\n"+compare([:DEOXYS, 1], EsBridge.species_and_form(:DEOXYS_1), "Species and Form")
    end
    
    if EsBridge::MAJOR_VERSION >= 19
      ret += "\n"+compare(:DEOXYS_1, EsBridge.species_form(:DEOXYS, 1), "Species Form")
    end
    
    if EsBridge::MAJOR_VERSION >= 17
      ret += "\n"+compare(3, FLUtil.last_form_index(:DEOXYS), "FLUtil.last_form_index")
    end
    
    ret += "\n"+compare(252, EsBridge.ev_stat_limit, "EV Stat Limit")
    
    ret += "\n"+compare(510, EsBridge.ev_limit, "EV Limit")
    
    ret += "\n"+compare(31, EsBridge.iv_stat_limit, "IV Stat Limit")

    sprite_path = EsBridge.pokemon_front_sprite_filename(species, 1)
    ret += "\n"+assert(sprite_path, "Species Front Sprite path", "Path is #{sprite_path}")

    ret += "\n"+assert(
      [true, false].include?(EsBridge.day_care_has_egg?), "Day Care has Egg", "Egg is #{EsBridge.day_care_has_egg?}"
    )

    ret += "\n"+assert(
      !FLUtil.all_player_pokemon.empty?, "FLUtil.all_player_pokemon","Size #{FLUtil.all_player_pokemon.size}"
    )
    
    ret += "\n"+compare(4, EsBridge.type_effectiveness(:WATER,:FIRE), "Type Effectiveness")
    
    ret += "\n"+compare("Fire", FLUtil.type_string(:FIRE,:FIRE), "FLUtil.type_string(:FIRE,:FIRE)")
    
    ret += "\n"+compare(
      "Water and Fire", FLUtil.type_string([:WATER,:FIRE],nil," and "), "FLUtil.type_string(:WATER,:FIRE)"
    )
    
    ret += "\n"+assert(EsBridge.type_image_path, "Type path", "Path is #{EsBridge.type_image_path}")

    ret += "\n"+compare(10, EsBridge.type_icon_index(:FIRE), "Type index")
    
    ret += "\n"+assert(!FLUtil.has_item_at_bag_or_pc_or_hold?(:HYPERPOTION), "FLUtil.has_item_at_bag_or_pc_or_hold?(:HYPERPOTION)")
    
    ret += "\n"+assert(EsBridge.coins.is_a?(Numeric), "Coins", "#{EsBridge.coins} coins")
    
    ret += "\n"+assert(EsBridge.max_coins > 1_000, "Max Coins", "#{EsBridge.max_coins} max coins")
    
    ret += "\n"+assert(EsBridge.audio_name("PC access"), "Audio Basic Test")

    helper = PokemonRandomHelper.new
    helper.add(3, :RATTATA)
    helper.add(1, :SPEAROW)
    helper.add(1, :EKANS)
    result = helper.get
    ret += "\n"+assert(
      [:RATTATA, :SPEAROW, :EKANS].include?(result),
      "PokemonRandomHelper", "Drew #{result}", "Unexpectedly drew #{result}"
    )

    helper = ItemRandomHelper.new
    helper.require_weight = 100
    helper.allow_nil = true
    helper.allow_repeat = true
    helper.add(10.5, :POTION)
    helper.add_range(3, [:AWAKENING,:ANTIDOTE, :BURNHEAL])
    helper.add_copying_weight(2, [:POKEBALL,:GREATBALL,:ULTRABALL])
    helper.add(80.5, nil)
    helper.average_sell_price
    result = helper.get(0.13)
    ret += "\n"+compare(:BURNHEAL, result, "ItemRandomHelper")

    return ret
  end

  # Compare expected and value and return the message.
  def compare(expected, value, title, message=nil, error_message=nil)
    return assert(
      expected==value, title,
      "(#{value}) #{(message || "")}",
      "(#{value}, expected:#{expected}) #{(error_message || "")}"
    )
  end

  # Expect that value is true. Else, trigger error message.
  def assert(condition, title, message=nil, error_message=nil)
    if condition
      ret=title
      ret += " - "+message if message
    else
      ret="### ERROR - #{title}"
      ret += " - "+error_message if error_message
    end
    return ret
  end
end