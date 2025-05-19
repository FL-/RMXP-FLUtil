#===============================================================================
#
# EsBridge provides a compatibility layer between Essentials versions and even
# non-Essentials. Useful if you are thinking about update but aren't sure and/or
# want to create multi-version scripts
#
#== HOW TO USE =================================================================
#
# Use the available methods instead of Essentials ones.
#
#== EXAMPLES ===================================================================
#
# Instead of calling 'pbMessage', call 'EsBridge.message'.
#
#== NOTES ======================================================================
#
# This script just cover some Essentials functionalities, especially the basics
# ones. There a lot of missing methods.
#
#===============================================================================

module EsBridge
  module_function

  def major_version
    ret = 0 # No Essentials
    if defined?(Essentials)
      ret = Essentials::VERSION.split(".")[0].to_i
    elsif defined?(ESSENTIALS_VERSION)
      ret = ESSENTIALS_VERSION.split(".")[0].to_i
    elsif defined?(ESSENTIALSVERSION)
      ret = ESSENTIALSVERSION.split(".")[0].to_i
    elsif defined?(PokeBattle_Pokemon)
      ret = 1 # Technically can be -10...10 but this makes some operations easier
    end
    return ret
  end

  MAJOR_VERSION = major_version
  IS_ESSENTIALS = MAJOR_VERSION>0
  IS_MKXP = defined?(System) && System.const_defined?(:VERSION)
  
  #-----------------------------------------------------------------------------
  # General
  #-----------------------------------------------------------------------------

  def delta
    return 0.025 if !IS_MKXP || Graphics.delta > 1 # Since on some old mkxp this has a strange behavior
    return Graphics.delta
  end

  def wait(seconds)
    raise NotImplementedError.new if !IS_ESSENTIALS
    pbWait(MAJOR_VERSION < 21 ? (seconds*40).round : seconds)
  end

  def player
    raise NotImplementedError.new if !IS_ESSENTIALS
    return $Trainer if MAJOR_VERSION < 20
    return $player
  end

  def play_time
    return Graphics.frame_count/Graphics.frame_rate.to_f if MAJOR_VERSION < 21
    return $stats.play_time
  end

  def time_shading
    return case MAJOR_VERSION
      when 0..17; ENABLESHADING
      when 18;    TIME_SHADING
      else        Settings::TIME_SHADING
    end
  end

  def game_data_exists?(game_data, value)
    return getID(game_data, value) != 0 if MAJOR_VERSION < 19
    return game_data.exists?(value)
  end
  
  #-----------------------------------------------------------------------------
  # Message
  #-----------------------------------------------------------------------------
  
  def message(string, commands = nil, cmdIfCancel = 0, &block)
    raise NotImplementedError.new if !IS_ESSENTIALS
    if MAJOR_VERSION < 20
      return Kernel.pbMessage(string, commands, cmdIfCancel, &block)
    end
    return pbMessage(string, commands, cmdIfCancel, &block)
  end

  def confirm_message(string, &block)
    raise NotImplementedError.new if !IS_ESSENTIALS
    return Kernel.pbConfirmMessage(string, &block) if MAJOR_VERSION < 20
    return pbConfirmMessage(string, &block)
  end

  def message_choose_number(message, params, &block)
    raise NotImplementedError.new if !IS_ESSENTIALS
    if MAJOR_VERSION < 20
      return Kernel.pbMessageChooseNumber(message, params, &block)
    end
    return pbMessageChooseNumber(message, params, &block)
  end

  #-----------------------------------------------------------------------------
  # Draw text/sprites
  #-----------------------------------------------------------------------------  
  
  def draw_text_positions(bitmap,textpos)
    if MAJOR_VERSION < 20
      for single_text_pos in textpos
        single_text_pos[2] -= MAJOR_VERSION==19 ? 12 : 6
      end
    end
    return pbDrawTextPositions(bitmap,textpos)
  end

  def set_pokemon_bottom_offset(sprite, pokemon)
    case MAJOR_VERSION
    when 0..15
      pbPositionPokemonSprite(sprite, sprite.x, sprite.y)
      sprite.x += 8 - sprite.bitmap.width/2 if sprite.bitmap  
      sprite.y = adjustBattleSpriteY(sprite, pokemon.species, 0)  
    when 16..19
      sprite.setOffset(PictureOrigin::Bottom) 
    else
      sprite.setOffset(PictureOrigin::BOTTOM)
    end   
  end
  
  #-----------------------------------------------------------------------------
  # Pokémon
  #-----------------------------------------------------------------------------

  def species_name(species)
    return PBSpecies.getName(getID(PBSpecies, species)) if MAJOR_VERSION < 19
    return GameData::Species.get(species).name
  end

  def species_sym_is_valid(species_sym)
    return game_data_exists?(MAJOR_VERSION < 19 ? PBSpecies : GameData::Species, species_sym)
  end

  def species_category(species, form = 0)
    if MAJOR_VERSION < 19
      ret = pbGetMessage(MessageTypes::Kinds, getID(PBSpecies, fspecies_from_form_v18_minus(species, form)))
      ret ||= pbGetMessage(MessageTypes::Kinds, getID(PBSpecies, species))
      return ret
    end
    return GameData::Species.get_species_form(species, form).category
  end

  def fspecies_from_form_v18_minus(species, form)
    return species if MAJOR_VERSION < 17
    return pbGetFSpeciesFromForm(species, form)
  end
  private_class_method :fspecies_from_form_v18_minus

  # Receive species with form symbol and returns an array with species
  # symbol and form number
  def species_and_form(species_full)
    return [getID(PBSpecies, species_full), 0] if MAJOR_VERSION < 17
    if MAJOR_VERSION < 19
      return pbGetSpeciesFromFSpecies(getID(PBSpecies, species_full))
    end
    species_form = GameData::Species.get_species_form(species_full, 0)
    return [species_form.species, species_form.form]
  end

  def species_form(species, form)
    return species if MAJOR_VERSION < 17
    if MAJOR_VERSION < 19
      return pbGetFSpeciesFromForm(getID(PBSpecies, species), form)
    end
    return GameData::Species.get_species_form(species, form).id
  end

  def species_types(species)
    case MAJOR_VERSION
    when 0..18
      dexdata = pbOpenDexData
      pbDexDataOffset(dexdata,getID(PBSpecies, species),8)
      ret = [dexdata.fgetb, dexdata.fgetb]
      ret.pop if !ret[1] || ret[0] == ret[1]
      dexdata.close
      return ret
    when 19; 
      ret = [GameData::Species.get(species).type1, GameData::Species.get(species).type2]
      ret.pop if !ret[1] || ret[0] == ret[1]
      return ret
    else
      return GameData::Species.get(species).types
    end
  end

  def species_base_stats(species)
    if MAJOR_VERSION < 19
      ret = {}
      dexdata = pbOpenDexData
      pbDexDataOffset(dexdata,getID(PBSpecies, species),10)
      for s in [:HP,:ATTACK,:DEFENSE,:SPEED,:SPECIAL_ATTACK,:SPECIAL_DEFENSE]
        ret[s] = dexdata.fgetb
      end
      dexdata.close
      return ret
    end
    return GameData::Species.get(species).base_stats
  end
  
  def species_count
    return case MAJOR_VERSION
      when 0..18; PBSpecies.getCount
      when 19;    GameData::Species.keys.count
      else        GameData::Species.count
    end
  end

  def species_icon_path(species)
    if MAJOR_VERSION < 19
      return pbCheckPokemonIconFiles([getID(PBSpecies, species),0,false,0,false])
    end
    return GameData::Species.icon_filename(species)
  end
  
  def maximum_level
    return case MAJOR_VERSION
      when 0..17; PBExperience::MAXLEVEL
      when 18;    MAXIMUM_LEVEL
      else        Settings::MAXIMUM_LEVEL
    end
  end

  def internal_stat(stat)
    return {
      :HP              => PBStats::HP     ,
      :ATTACK          => PBStats::ATTACK ,
      :DEFENSE         => PBStats::DEFENSE,
      :SPEED           => PBStats::SPEED  ,
      :SPECIAL_ATTACK  => PBStats::SPATK  ,
      :SPECIAL_DEFENSE => PBStats::SPDEF  ,
    }.fetch(stat, stat) if MAJOR_VERSION < 19
    return stat
  end

  def stat_name(stat)
    case MAJOR_VERSION
    when 0..15
      return {
        :HP              => "HP",
        :ATTACK          => "Attack" ,
        :DEFENSE         => "Defense",
        :SPEED           => "Speed",
        :SPECIAL_ATTACK  => "Special Attack",
        :SPECIAL_DEFENSE => "Special Defense",
      }[stat]
    when 16..18
      return PBStats.getName(internal_stat(stat))
    else
      return GameData::Stat.get(stat).name
    end
  end

  def ev_stat_limit
    return case MAJOR_VERSION
      when 0..15;   252
      when 16..17;  PokeBattle_Pokemon::EVSTATLIMIT
      when 18;      PokeBattle_Pokemon::EV_STAT_LIMIT
      else          Pokemon::EV_STAT_LIMIT
    end
  end
  
  def ev_limit
    return case MAJOR_VERSION
      when 0..15;   510
      when 16..17;  PokeBattle_Pokemon::EVLIMIT
      when 18;      PokeBattle_Pokemon::EV_LIMIT
      else          Pokemon::EV_LIMIT
    end
  end
  
  def iv_stat_limit
    return case MAJOR_VERSION
      when 0..17; 31
      when 18;    PokeBattle_Pokemon::IV_STAT_LIMIT
      else        Pokemon::IV_STAT_LIMIT
    end
  end

  def maximize_iv(pkmn, stat)
    if MAJOR_VERSION < 18
      return false if pkmn.iv[internal_stat(stat)] == iv_stat_limit
      pkmn.iv[internal_stat(stat)] = iv_stat_limit
    else
      return false if pkmn.ivMaxed[internal_stat(stat)]
      pkmn.ivMaxed[internal_stat(stat)] = true
    end
    return true
  end
    
  def has_maxed_iv?(pkmn, stat)
    return pkmn.iv[internal_stat(stat)] >= iv_stat_limit if MAJOR_VERSION < 18
    return pkmn.ivMaxed[internal_stat(stat)]
  end

  def pokemon_front_sprite_filename(species, form=0, gender=0, shiny=false, shadow=false)
    if MAJOR_VERSION < 19
      return pbCheckPokemonBitmapFiles([getID(PBSpecies, species), false, gender, shiny, form, shadow])
    end
    return GameData::Species.front_sprite_filename(species, form, gender, shiny, shadow)
  end

  def play_cry(species, form=0)
    return pbPlayCry(species) if MAJOR_VERSION < 19
    GameData::Species.play_cry_from_species(species, form)
  end

  def register_as_seen(species, form, gender, shiny)
    if MAJOR_VERSION < 19
      $Trainer.seen[species]=true
      if MAJOR_VERSION >= 17
        pbSeenForm(fspecies_from_form_v18_minus(species,form))
      end
      return
    end
    (MAJOR_VERSION<20 ? $Trainer : $player).pokedex.register(species, gender, form, shiny)
  end

  def day_care_pokemon(index)
    return $PokemonGlobal.daycare[index][0] if MAJOR_VERSION < 20
    return nil if !$PokemonGlobal.day_care.slots[index]
    return $PokemonGlobal.day_care.slots[index].pokemon
  end

  def day_care_has_egg?
    return Kernel.pbEggGenerated? if MAJOR_VERSION < 20
    return DayCare.egg_generated?
  end
  
  #-----------------------------------------------------------------------------
  # Type
  #-----------------------------------------------------------------------------

  def type_name(type)
    return PBTypes.getName(getID(PBTypes,type)) if MAJOR_VERSION < 19
    return GameData::Type.get(type).name
  end

  def compare_type(type1, type2)
    if MAJOR_VERSION < 19
      return type1==type2 || (
        getID(PBTypes,type1) == getID(PBTypes,type2) && getID(PBTypes,type1) != nil
      ) || getID(PBTypes,type1)==type2 || type1==getID(PBTypes,type2)
    end
    return type1==type2
  end

  def type_effectiveness(attacker_type, opponent_type)
    if MAJOR_VERSION < 19
      return PBTypes.getEffectiveness(
        getID(PBTypes,attacker_type),getID(PBTypes,opponent_type)
      )
    end
    effectiveness = Effectiveness.calculate(attacker_type, opponent_type)
    if Effectiveness.ineffective?(effectiveness)
      return 0
    elsif Effectiveness.not_very_effective?(effectiveness)
      return 1
    elsif Effectiveness.super_effective?(effectiveness)
      return 4
    end
    return 2
  end

  def type_image_path
    return _INTL("Graphics/Pictures/types") if MAJOR_VERSION < 21
    return _INTL("Graphics/UI/types")
  end

  def type_icon_index(type)
    return case MAJOR_VERSION
      when 0..18; getID(PBTypes, type)
      when 19;    GameData::Type.get(type).id_number
      else        GameData::Type.get(type).icon_position
    end
  end
  
  #-----------------------------------------------------------------------------
  # Item (and related)
  #-----------------------------------------------------------------------------

  def item_name(item_id)
    return case MAJOR_VERSION
      when 0;     $data_items[item_id].name
      when 1..18; PBItems.getName(getID(PBItems, item_id))
      else        GameData::Item.get(item_id).name
    end
  end

  def has_item?(item_id)
    return case MAJOR_VERSION
      when 0;     $game_party.item_number(item_id) > 0
      when 1..18; $PokemonBag.pbQuantity(getID(PBItems,item_id)) > 0
      when 19;    $PokemonBag.pbHasItem?(item_id)
      else        $bag.has?(item_id)
    end
  end

  def item_quantity(item_id)
    return case MAJOR_VERSION
      when 0;     $game_party.item_number(item_id)
      when 1..18; $PokemonBag.pbQuantity(getID(PBItems,item_id))
      when 19;    $PokemonBag.pbQuantity?(item_id)
      else        $bag.quantity(item_id)
    end
  end

  def item_buy_price(item_id)
    return case MAJOR_VERSION
      when 0;     $data_items[item_id].price
      when 1..17; $ItemData[getID(PBItems, item_id)][ITEMPRICE]
      when 18;    pbGetItemData(item_id, ITEM_PRICE)
      else        GameData::Item.get(item_id).price
    end
  end

  def item_sell_price(item_id)
    return item_buy_price(item_id)/2 if MAJOR_VERSION < 20
    return GameData::Item.get(item_id).sell_price
  end

  def receive_item(item, quantity=1)
    return case MAJOR_VERSION
      when 0;     $game_party.gain_item(item, quantity)
      when 1..19; Kernel.pbReceiveItem(item, quantity)
      else        pbReceiveItem(item, quantity)
    end
  end

  # Silent add
  def add_item(item, quantity=1)
    return case MAJOR_VERSION
      when 0;     $game_party.gain_item(item, quantity)
      when 1..19; $PokemonBag.pbStoreItem(item, quantity)
      else        $bag.add(item, quantity)
    end
  end

  def add_item_pc(item, quantity=1)
    raise NotImplementedError.new if !IS_ESSENTIALS
    $PokemonGlobal.pcItemStorage ||= PCItemStorage.new
    if MAJOR_VERSION < 20
      return $PokemonGlobal.pcItemStorage.pbStoreItem(item, quantity)
    end
    return $PokemonGlobal.pcItemStorage.add(item, quantity)
  end
  
  #-----------------------------------------------------------------------------
  # Game Corner Coins
  #-----------------------------------------------------------------------------
    
  def coin_holder
    return $PokemonGlobal if MAJOR_VERSION < 19
    return player
  end

  def coins
    return coin_holder.coins
  end

  def coins=(value)
    coin_holder.coins = value
  end
  
  def max_coins
    return case MAJOR_VERSION
      when 0..17; MAXCOINS
      when 18;    MAX_COINS
      else        Settings::MAX_COINS
    end
  end
  
  #-----------------------------------------------------------------------------
  # Triple Triad
  #-----------------------------------------------------------------------------

  def add_triad_card(card, quantity)
    if MAJOR_VERSION < 20
      return $PokemonGlobal.triads.pbStoreItem(card, quantity)
    end
    $PokemonGlobal.triads.add(card, quantity)
  end

  def remove_triad_card(card, quantity)
    if MAJOR_VERSION < 20
      return $PokemonGlobal.triads.pbDeleteItem(card, quantity)
    end
    $PokemonGlobal.triads.remove(card, quantity)
  end

  def storage_add_triad_card(items,maxSize,maxPerSlot,item,qty)
    if MAJOR_VERSION < 20
      return ItemStorageHelper.pbStoreItem(items, maxSize, maxPerSlot, item,qty)
    end
    return ItemStorageHelper.add(items, maxSize, maxPerSlot, item, qty)
  end

  def storage_remove_triad_card(items,maxSize,item,qty)
    return case MAJOR_VERSION
      when 0..18; ItemStorageHelper.pbDeleteItem(items,maxSize,item,qty)
      when 19;    ItemStorageHelper.pbDeleteItem(items,item,qty)
      else        ItemStorageHelper.remove(items, item, qty)
    end
  end

  def storage_quantity_triad_card(items,maxSize,item)
    return case MAJOR_VERSION
      when 0..18; ItemStorageHelper.pbQuantity(items,maxSize,item)
      when 19;    ItemStorageHelper.pbQuantity(items,item)
      else        ItemStorageHelper.quantity(items, item)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Audio
  #-----------------------------------------------------------------------------

  # Use pbSEPlay(EsBridge.get_audio_name("newEssentialsSEName"))
  # Work for BGM/BGS/ME/SE. This isn't completed
  def audio_name(baseName)
    if !@@audioNameHash
      @@audioNameHash = case MAJOR_VERSION
        when 0..16;  create_audio_hash_v16_minus
        when 17..19; create_audio_hash_v19_minus
        else         {}
      end
    end
    return @@audioNameHash.fetch(baseName, baseName)  
  end
  @@audioNameHash = nil

  def create_audio_hash_v19_minus
    return {
      # BGM - Background Musics
      "Lappet Town"                  => "021-Field04"            , # substitute
      "Safari Zone"                  => "021-Field04"            , # substitute
    }
  end
  private_class_method :create_audio_hash_v19_minus

  def create_audio_hash_v16_minus
    return {
      # "Battle flee"                  => "???"                    ,
      # "Cut"                          => "???"                    ,
      # "GUI menu close"               => "???"                    ,
      # "GUI naming confirm"           => "???"                    ,
      # "GUI naming tab swap start"    => "???"                    ,
      # "GUI naming tab swap end"      => "???"                    ,
      # "GUI party switch"             => "???"                    ,
      # "GUI storage show party panel" => "???"                    ,
      # "GUI storage hide party panel" => "???"                    ,
      # "GUI storage pick up"          => "???"                    ,
      # "GUI storage put down"         => "???"                    ,
      # "Mart buy item"                => "???"                    ,
      # "Pkmn exp gain"                => "???"                    ,
      # "Rock Smash"                   => "???"                    ,
      # "Voltorb Flip level up"        => "???"                    ,
      # "Voltorb Flip gain coins"      => "???"                    ,
      # "Evolution start"              => "???"                    ,
      # "GUI save game"                => "???"                    ,

      # SE - Sound Effects
      "Battle ball drop"             => "balldrop"               ,
      "Battle ball hit"              => "balldrop"               ,
      "Battle ball shake"            => "ballshake"              ,
      "Battle catch click"           => "balldrop"               ,
      "Battle damage normal"         => "normaldamage"           ,
      "Battle damage super"          => "superdamage"            ,
      "Battle damage weak"           => "notverydamage"          ,
      "Battle jump to ball"          => "jumptoball"             ,
      "Battle recall"                => "recall"                 ,
      "Battle throw"                 => "throw"                  ,
      "Door enter"                   => "Entering Door"          ,
      "Door exit"                    => "Exit Door"              ,
      "Exclaim"                      => "jumptoball"             ,
      "GUI menu open"                => "menu"                   ,
      "GUI save choice"              => "save"                   ,
      "GUI sel buzzer"               => "buzzer"                 ,
      "GUI sel cancel"               => "Choose"                 ,
      "GUI sel cursor"               => "Choose"                 ,
      "GUI sel decision"             => "Choose"                 ,
      "Mining collapse"              => "MiningCollapse"         ,
      "Mining cursor"                => "MiningMove"             ,
      "Mining found all"             => "MiningAllFound"         ,
      "Mining hammer"                => "MiningHammer"           ,
      "Mining item get"              => "MiningItemGet"          ,
      "Mining iron"                  => "MiningIron"             ,
      "Mining reveal"                => "MiningRevealItem"       ,
      "Mining reveal full"           => "MiningFullyRevealItem"  ,
      "Mining pick"                  => "MiningPick"             ,
      "Mining ping"                  => "MiningPing"             ,
      "Mining tool change"           => "MiningChangeTool"       ,
      "PC access"                    => "accesspc"               ,
      "PC close"                     => "computerclose"          ,
      "PC open"                      => "computeropen"           ,
      "Pkmn exp full"                => "expfull"                ,
      "Pkmn faint"                   => "faint"                  ,
      "Pkmn move learnt"             => "itemlevel"              ,
      "Player bump"                  => "bump"                   ,
      "Player jump"                  => "jump"                   ,
      "Slots coin"                   => "SlotsCoin"              ,
      "Slots stop"                   => "SlotsStop"              ,
      "Tile Game cursor"             => "TileGameMove"           ,
      "Voltorb Flip explosion"       => "VoltorbFlipExplosion"   ,
      "Voltorb Flip level down"      => "VoltorbFlipLevelDown"   ,
      "Voltorb Flip mark"            => "VoltorbFlipMark"        ,
      "Voltorb Flip point"           => "VoltorbFlipPoint"       ,
      "Voltorb Flip tile"            => "VoltorbFlipTile"        ,
      # ME - Music Effects
      "Badge get"                    => "Jingle - HMTM"          , # substitute
      "Battle capture success"       => "Jingle - HMTM"          , # substitute
      "Battle victory"               => "001-Victory01"          , # substitute
      "Battle victory leader"        => "001-Victory01"          , # substitute
      "Battle victory trainer"       => "001-Victory01"          , # substitute
      "Battle victory wild"          => "001-Victory01"          , # substitute
      "Bug catching 1st"             => "SlotsBigWin"            , # substitute
      "Bug catching 2nd"             => "SlotsWin"               , # substitute
      "Bug catching 3rd"             => "Voltorb Flip Win"       ,
      "Egg get"                      => "Jingle - HMTM"          , # substitute
      "Evolution success"            => "Jingle - HMTM"          , # substitute
      "Item get"                     => "Jingle - HMTM"          , # substitute
      "Key item get"                 => "Jingle - HMTM"          , # substitute
      "Pkmn get"                     => "Jingle - HMTM"          , # substitute
      "Pkmn healing"                 => "Pokemon Healing"        ,
      "Register phone"               => "Jingle - HMTM"          , # substitute
      "Slots big win"                => "SlotsBigWin"            ,
      "Slots win"                    => "SlotsWin"               ,
      "Voltorb Flip game over"       => "Voltorb Flip Game Over" ,
      "Voltorb Flip win"             => "Voltorb Flip Win"       ,
      # BGM - Background Musics
      "Battle Elite"                 => "elite"                  ,
      "Battle Gym Leader"            => "gymleader"              ,
      "Battle roaming"               => "002-Battle02x"          , # substitute
      "Battle trainer"               => "005-Boss01"             , # substitute
      "Battle wild"                  => "002-Battle02"           , # substitute
      "Bicycle"                      => "Airship"                , # substitute
      "Cave"                         => "035-Dungeon01"          , # substitute
      "Evolution"                    => "evolv"                  ,
      "Poke Center"                  => "PokeCenter"             ,
      "Poke Mart"                    => "PokeMart"               ,
      "Surfing"                      => "Ship"                   , # substitute
      "Underwater"                   => "uwater"                 ,
      "Triple Triad"                 => "021-Field04"            , # substitute
    }.merge(create_audio_hash_v19_minus)
  end
  private_class_method :create_audio_hash_v16_minus
end