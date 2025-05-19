#===============================================================================
#
# Tween system to make smooth movements and easy commands in scene animations.
# Supports easing.
#
#== HOW TO USE =================================================================
#
# Create a Tweener instance and call it during every scene frame.
#
# There are several Tweens and commands that you can call. Some, but not all,
# are displayed in Scene_SampleTween. Run it using
# '$scene = Scene_SampleTween.new'. This scene code also has many comments.
#
#== NOTES ======================================================================
#
# This script has many things in common with PictureEx class.
#
#===============================================================================

class Tweener
  def initialize
    @tween_list=[]
  end

  def add(tween)
    tween.prepare
    @tween_list.push(tween)
    return tween
  end

  def update
    for tween in @tween_list
      tween.start if tween.should_start?
    end
    for tween in @tween_list
      tween.update if tween.state == FLTween::RUNNING
    end
    check_finish
  end

  def check_finish
    i = 0
    while i < @tween_list.size
      if @tween_list[i].should_finish
        @tween_list[i].on_finish
        @tween_list.delete_at(i)
      else
        i+=1
      end
    end
  end

  def stop(tween)
    i = @tween_list.find_index(tween)
    raise ArgumentError, "#{tween} not found!" if !i
    stop_at(i)
  end

  def stop_at(i)
    @tween_list[i].stop
    @tween_list[i].on_finish
    @tween_list.delete_at(i)
  end

  def stop_all
    stop_at(0) while @tween_list.size > 0
  end
end

# v is 0-1
module Ease
  LINEAR      = proc{|v| v}
  IN_SINE     = proc{|v| 1 - Math.cos((v * Math::PI) / 2.0)}
  OUT_SINE    = proc{|v| Math.sin((v * Math::PI) / 2.0)}
  IN_OUT_SINE = proc{|v| -(Math.cos(Math::PI * v) - 1) / 2.0}
  IN_QUAD     = proc{|v| v*v}
  OUT_QUAD    = proc{|v| 1 - (1 - v) * (1 - v)}
  IN_OUT_QUAD = proc{|v| v < 0.5 ? (2*v*v) : (1 - (-2 * v + 2)**2 / 2)}
  IN_CUBIC    = proc{|v| v*v*v}
  OUT_CUBIC   = proc{|v| 1 - (1 - v)**3}
  IN_OUT_CUBIC= proc{|v| v < 0.5 ? (4*v*v*v) : (1 - (-2 * v + 2)**3 / 2)}
  IN_QUART    = proc{|v| v*v*v*v}
  OUT_QUART   = proc{|v| 1 - (1 - v)**4}
  IN_OUT_QUART= proc{|v| v < 0.5 ? (8*v*v*v*v) : (1 - (-2 * v + 2)**4 / 2)}
  IN_QUINT    = proc{|v| v*v*v*v*v}
  OUT_QUINT   = proc{|v| 1 - (1 - v)**5}
  IN_OUT_QUINT= proc{|v| v < 0.5 ? (16*v*v*v*v*v) : (1 - (-2 * v + 2)**5 / 2)}
end

class FLTween
  attr_reader :state
  attr_reader :should_finish
  attr_reader :target
  attr_reader :start_loop_val
  attr_reader :end_loop_val

  BEFORE_START = 1
  RUNNING = 2
  INTERRUPTED = 3
  COMPLETED = 4

  # When a loop ends it will restart from the beginning.
  RESTART_LOOP = 0

  # When a loop ends it will play backwards until it completes another loop,
  # then forward again, then backwards again, and so on and on and on.
  YOYO_LOOP = 1

  #TODO
  # Each time a loop ends the difference between its endValue and its startValue
  # will be added to the endValue, thus creating tweens that increase their values with each loop cycle.
  INCREMENTAL_LOOP = 2

  def initialize(target, duration)
    @delay = 0
    @should_finish = false
    @state = BEFORE_START
    @start_loop_proc = nil
    @complete_proc = nil
    @update_condition_proc = nil
    @relative = false
    @ease = Ease::LINEAR
    @loop_quantity = 1
    @complete_loops = 0
    @loop_type = 0
    @initial_val = nil
    @target = target
    @duration = duration
  end

  def ratio
    return [[(Time.now - @start_time)/@duration.to_f, 1].min, 0].max
  end

  def should_start?
    return @state == BEFORE_START && @start_time <= Time.now
  end

  # Called with added to tweener. After fluent interface methods were called.
  def prepare
    @start_time = Time.now + @delay  # start_time FOR LOOP. 0.005 is a small fix
    @end_time = @start_time + @duration
  end

  def start
    start_loop
  end

  def start_loop
    initialize_initial_value
    @state = RUNNING
    @start_loop_proc.call(self) if @start_loop_proc
  end

  def initialize_initial_value
    @initial_val = @current_val.clone if !@initial_val
    @start_loop_val = @current_val.clone
    @end_loop_val = @target_val.clone
    if @loop_quantity != 1
      case @loop_type
      when RESTART_LOOP
        @start_loop_val = @initial_val.clone
      when YOYO_LOOP
        @end_loop_val = @initial_val.clone if @complete_loops % 2 != 0
      end
    end
    format_relative_value if @relative && (@loop_type != YOYO_LOOP || @complete_loops % 2 == 0) 
  end

  def format_relative_value
    for i in 0...@current_val.size
      next if !@end_loop_val[i]
      @end_loop_val[i] += @current_val[i]
    end
  end

  def update
    update_array if !@update_condition_proc || @update_condition_proc.call(self)
    if loop_is_finishing?
      @complete_loops += 1
      if @loop_quantity > @complete_loops || @loop_quantity<0
        @start_time = Time.now
        @end_time = @start_time + @duration
        start_loop
      else
        @should_finish = true
        @state = COMPLETED
      end
    end
  end

  def update_array
    for i in 0...@current_val.size
      update_single(i)
    end
  end

  def update_single(i)
    return if !@target_val[i]
    if @state==COMPLETED
      @current_val[i] = @end_loop_val[i]
    else
      @current_val[i] = @ease.call(ratio)*(@end_loop_val[i]-@start_loop_val[i])+@start_loop_val[i]
    end
  end

  def loop_is_finishing?
    return Time.now >= @end_time
  end

  def stop
    @state = INTERRUPTED if @state -= RUNNING
  end

  def on_finish
    @complete_proc.call(self) if @state == COMPLETED && @complete_proc
  end

  def set_delay(seconds_delay, reduce_from_duration=false)
    @delay = seconds_delay
    @duration -= @delay if reduce_from_duration
    return self
  end

  def set_ease(value)
    @ease = value
    return self
  end

  def set_relative(value=true)
    @relative = value
    return self
  end

  # -1 = infinite
  def set_loops(quantity=-1, type=RESTART_LOOP)
    @loop_quantity = quantity
    @loop_type = type
    return self
  end

  def set_start_loop_proc(value)
    @start_loop_proc = value
    return self
  end

  def set_update_condition_proc(proc)
    @update_condition_proc = proc
    return self
  end

  def set_complete_proc(value)
    @complete_proc = value
    return self
  end

  # To be used with clone
  def set_target(value)
    @target = value
    return self
  end

  def clone
    target = @target
    ease = @ease
    # To won't clone
    @target = nil
    @ease = nil
    ret = Marshal.load(Marshal.dump(self))
    @target = target
    @ease = ease
    ret.set_target(target).set_ease(ease)
    return ret
  end
end

# Move Tween;
# Internally, uses float numbers for pos.
# Pass target axis as nil to ignore an axis.
class MoveTween < FLTween
  def initialize(target, target_x, target_y, duration)
    super(target, duration)
    @target_val = [target_x,target_y]
  end

  def start
    @current_val = [@target.x, @target.y]
    super
  end

  def update_single(i)
    super(i)
    return if !@target_val[i]
    if i == 0
      @target.x = @current_val[i].floor
    else
      @target.y = @current_val[i].floor
    end
  end
end

# Move ox and oxy Tween
# Pass target axis as nil to ignore an axis
class MoveOXYTween < FLTween
  def initialize(target, target_x, target_y, duration)
    super(target, duration)
    @target_val = [target_x,target_y]
  end

  def start
    @current_val = [@target.ox, @target.oy]
    super
  end

  def update_single(i)
    super(i)
    return if !@target_val[i]
    if i == 0
      @target.ox = @current_val[i].floor
    else
      @target.oy = @current_val[i].floor
    end
  end
end

class ZoomTween < FLTween
  def initialize(target, target_x, target_y, duration)
    super(target, duration)
    @target_val = [target_x,target_y]
  end

  def start
    @current_val = [@target.zoom_x, @target.zoom_y]
    super
  end

  def update_single(i)
    super(i)
    return if !@target_val[i]
    if i == 0
      @target.zoom_x = @current_val[i]
    else
      @target.zoom_y = @current_val[i]
    end
  end
end

class RotateTween < FLTween
  def initialize(target, target_val, duration)
    super(target, duration)
    @target_val = [target_val]
  end

  def start
    @current_val = [@target.angle]
    super
  end

  def update_single(i)
    super(i)
    @target.angle = @current_val[i]
  end
end

class OpacityTween < FLTween
  def initialize(target, target_val, duration)
    super(target, duration)
    @target_val = [target_val]
  end

  def start
    @current_val = [@target.opacity]
    super
  end

  def update_single(i)
    super(i)
    @target.opacity = @current_val[i]
  end
end

# To be used by Color and Tone
class BaseColorTween < FLTween
  def initialize(target, value, duration)
    super(target, duration)
    @target_val = value
    @target_val = @target_val.to_a if value.is_a?(desired_type)
  end

  def start
    @current_val = target_object_value.to_a
    super
  end

  def update_array
    super
    self.target_object_value = get_formatted_color
  end

  def get_formatted_color
    ret = desired_type.new(0,0,0)
    for i in 0..3
      ret[i] = @current_val[i] || target_object_value[i]
    end
    return ret
  end

  # Different of target_val, is the current target (sprite) value
  def target_object_value
    raise NotImplementedError
  end

  def target_object_value=(value)
    raise NotImplementedError
  end

  def desired_type
    raise NotImplementedError
  end
end

class ColorTween < BaseColorTween
  # So only tweens alpha
  def self.newAlpha(target, value, duration)
    return self.new(target,[nil,nil,nil,value],duration)
  end

  def target_object_value
    return @target.color
  end

  def target_object_value=(value)
    @target.color = value
  end

  def desired_type
    return Color
  end
end

class ToneTween < BaseColorTween
  def target_object_value
    return @target.tone
  end

  def target_object_value=(value)
    @target.tone = value
  end

  def desired_type
    return Tone
  end
end

# Just to schedule callbacks. Can have target or not. Can also use custom updates
class DummyTween < FLTween
  def initialize(*args)
    args.size==2 ? super(args[0], args[1]) : super(nil, args[0])
    @target_val = [nil]
  end
end

# A custom tween. Update proc has the self and the value as parameters.
# Put nil as initial_val or target_val if it isn't relevant.
class CustomTween < FLTween
  def initialize(target, initial_val, target_val, update_proc, duration)
    super(target, duration)
    @update_proc = update_proc
    @current_val = [initial_val]
    @target_val = [target_val]
  end

  def update_single(i)
    super(i)
    @update_proc.call(self, @current_val[i])
  end
end

# RPG Maker XP standard scene to test tween, but thee Tweener is also
# compatible with Essentials Scenes.
# Call with '$scene = Scene_SampleTween.new'.
class Scene_SampleTween
  # These paths should have sprites or the scene won't work!
  MARILL_PATH = "Graphics/Pictures/introMarill"
  BOY_PATH = "Graphics/Pictures/introBoy"

  def start_scene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @tweener = Tweener.new
    @sprites = {}
    @sprites["Marill"] = Sprite.new(@viewport)
    @sprites["Marill"].bitmap = Bitmap.new(MARILL_PATH)
    @sprites["Marill"].x = 64
    @sprites["Marill"].y = 48
    # Set ox and oy to center, so it can be rotated correctly
    @sprites["Marill"].ox = @sprites["Marill"].bitmap.width/2
    @sprites["Marill"].oy = @sprites["Marill"].bitmap.height/2
    @sprites["Boy"] = Sprite.new(@viewport)
    @sprites["Boy"].bitmap = Bitmap.new(BOY_PATH)
    @sprites["Boy"].x = 16
    @sprites["Boy"].y = Graphics.height-@sprites["Boy"].bitmap.height-16
    Graphics.transition
  end

  def main
    start_scene
    # Set Boy to move 400 to right in 1.4s. Set ease as IN_OUT_QUAD (means
    # that it goes slower toward the start and end). Make it relative (so is 
    # x+400 instead of using 360 as target x). Make infinite (-1) loops, style
    # of Yoyo loops (means to back into start once the first loop ends).
    @tweener.add(MoveTween.new(
      @sprites["Boy"], 360, nil, 1.4
    ).set_ease(Ease::IN_OUT_QUAD).set_relative.set_loops(-1,FLTween::YOYO_LOOP))
    # Move Marill to (x:Graphics.width/2 and y:64) in 1.5s. Wait the animation
    # finish to start the next command.
    wait_tween_state(@tweener.add(
      MoveTween.new(@sprites["Marill"], Graphics.width/2, 64, 1.5)
    )) 
    # Wait 0.8s
    wait(0.8)
    # Move Marill to the current position plus (x:-128, y:16) in 3 seconds. Wait
    # the animation finish to start the next command. Set ease as
    # IN_OUT_CUBIC (slow downs in the start and in the end).
    wait_tween_state(@tweener.add(
      MoveTween.new(@sprites["Marill"], -128, 16, 3)
    ).set_ease(Ease::IN_OUT_CUBIC).set_relative)
    # Fade Marill (0 opacity) in 3.5 seconds. Set ease as IN_OUT_SINE. Wait
    # 0.5 seconds to start.
    @tweener.add(
      OpacityTween.new(@sprites["Marill"], 0, 3.5)
    ).set_ease(Ease::IN_OUT_SINE).set_delay(0.5)
    # Makes Marill start rotate 7 times counterclockwise (so uses negative
    # values). Set ease as IN_QUAD (slow at start).
    @tweener.add(
      RotateTween.new(@sprites["Marill"], -7*360, 4)
    ).set_ease(Ease::IN_QUAD)
    # Zooms Marill to x2.5 its size.
    @tweener.add(ZoomTween.new(@sprites["Marill"], 2.5, 2.5, 4))
    # Wait 3s. It counts only after last move, since wait_tween_state
    # wasn't used these commands. So all commands after this one runs in
    # parallel.
    wait(5)
    finish_scene
  end

  def finish_scene
    Graphics.freeze
    for key in @sprites.keys
      @sprites[key].dispose if @sprites[key] && @sprites[key].disposed?
      @sprites[key] = nil
    end
    @viewport.dispose
    $scene = ($game_map) ? Scene_Map.new : nil
  end

  def update
    # Important to call @tweener.update every frame
    @tweener.update
  end

  # Wait a little. When is nil, wait a single frame
  def wait(seconds=nil)
    target_time = Time.now + (seconds || 0.002)
    while Time.now < target_time && !cancel_press?
      Graphics.update
      Input.update
      self.update
    end
  end

  # Return true while tween state is different than informed state. Default
  # is Completed
  def wait_tween_state(tween, state=nil)
    state ||= FLTween::COMPLETED
    wait while tween.state != state && !cancel_press?
  end

  # Create just to have an easy quit. Make it false to disable it.
  def cancel_press?
    return Input.trigger?(Input::C) || Input.trigger?(Input::B)
  end
end