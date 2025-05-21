# FLUtil
This script is for RPG Maker XP. It adds a lot of useful classes and methods for scripters:
- RandomHelper who make doing things like raffle a lot easier. **Recommended even for non-scripters**.
- Variable Switches Alias, who makes switch/variable access shorter and more readable
- Tween system
- Multiversion/non-essentials layer (partial)
- Misc classes and methods

Works with or without Essentials.

## Download
[![](https://custom-icon-badges.demolab.com/badge/-Download-red?style=for-the-badge&logo=download&logoColor=white)](../../archive/refs/heads/main.zip)

## Installation
For Essentials version 19 and above, follow FL's [Essentials plugin installation instructions](https://github.com/FL-/Misc/tree/main/Guides/EssentialsInstallPlugin).

For others (including non-Essentials), copy and paste the .rb files in [FLUtil folder](/Content/Plugins/FLUtil) into script sections above main, in order. You can skip the first file (only with instructions) and the last (only with test stuff for me).

## How to Use
Look at [001_Main Notes.rb](/Content/Plugins/FLUtil/001_Main%20Notes.rb) for instructions.

## Examples:
Examples are based in Essentials, but most works in a vanilla RPG Maker XP project.

### RandomHelper

```ruby
helper = ItemRandomHelper.new
helper.add(60, :POTION) 
helper.add(30, :ANTIDOTE)
helper.add(10, :ETHER)
pbItemBall(helper.get)
```

### Variable Switches Alias
Original code to remove an apricorn:

```ruby
$bag.remove(pbGet(8))
data = GameData::Item.get(pbGet(8))
pbSet(3, data.name)
```

With this script:
  
```ruby
$bag.remove($gv[:APRICORN_DELIVERED])
data = GameData::Item.get($gv[:APRICORN_DELIVERED])
$gv[:TEMP_PKMN_NAME] = data.name
```

Or

```ruby
$bag.remove($gv[8])
data = GameData::Item.get($gv[8])
$gv[3] = data.name
```

### Tweener
![](Screens/gif.gif)

All movements in this gif were made in sample scene. The first Marill's movement was made with this code:

```ruby
# Move Marill to (x:Graphics.width/2 and y:64) in 1.5s.
@tweener.add(MoveTween.new(@sprites["Marill"], Graphics.width/2, 64, 1.5))
```

### EsBridge

```ruby
# Display message in all Essentials versions
EsBridge.message("Message here")
# Returns frame delta. Works with or without MKXP-Z
EsBridge.delta
# Returns item name in all Essentials, and even in base RPG Maker XP (but you should use a number as parameter)
EsBridge.item_name(:POTION)
```

### Misc Util

```ruby
# Random value from range
(2..5).random
# Access Color rbga like an Array
some_color[1] = 200
# Lerp between two tones (for mixing). Below example means 80% red and 20% blue
Tone.lerp(Tone.new(255,0,0), Tone.new(0,0,255), 0.8)
# Format Time from seconds. This code will returns "01:01:40"
FLUtil.format_time_from_seconds(3700)
# Returns all player pokémon (including party, boxes and Day Care)
FLUtil.all_player_pokemon
# Change all deoxys forms in party to +1. Go to 0 after last
FLUtil.swap_species_form(:DEOXYS)
# Returns if the item is in the bag, pc or hold in any pokémon 
FLUtil.has_item_at_bag_or_pc_or_hold?(:POTION)
```