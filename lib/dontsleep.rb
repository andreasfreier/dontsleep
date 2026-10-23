# frozen_string_literal: true

require "rbconfig"
require "dontsleep/version"

# rumouse (and its ffi dependency) only exists where it can be built —
# effectively macOS. Keep the require lenient so the gem *installs and loads*
# anywhere; on other platforms `Dontsleep.start` (and the executable) refuse
# with a clear message before the mouse is ever needed.
begin
  require "rumouse"
rescue LoadError
  module RuMouse
    def initialize
      raise Dontsleep::Error,
            "rumouse could not be loaded — dontsleep needs macOS (and the ffi gem)"
    end
  end
end

# Dontsleep keeps a macOS machine awake by nudging the cursor a couple of
# pixels now and then, so the system never considers you idle — while your
# SSH sessions, builds, and downloads keep going through your breaks.
#
#   Dontsleep.start                 # 2px ping-pong nudge, every 60s, until Ctrl-C
#   Dontsleep.start(minutes: 120)   # stop automatically after 120 minutes
#   Dontsleep.start(wander: true)   # old-school: teleport to a random spot (unattended boxes)
module Dontsleep
  class Error < StandardError; end

  def self.start(interval: 60, nudge: 2, minutes: nil, wander: false, quiet: false)
    raise Error, "dontsleep only supports macOS" unless on_mac?

    mouse = build_mouse
    deadline = minutes ? Time.now + minutes * 60 : nil
    positive = true

    until (deadline && Time.now > deadline)
      real_sleep(interval)
      move_mouse(mouse, nudge: nudge, wander: wander, positive: positive)
      positive = !positive # +2, −2, +2, −2 … on one fixed axis: pure ping-pong,
      # zero drift — the cursor jitters in place instead of walking away
      print(".") { $stdout.flush } unless quiet
    end
    puts
    "stopped (auto-stop)"
  rescue Interrupt
    puts
    "stopped (goodbye)"
  end

  def self.on_mac?
    RbConfig::CONFIG["host_os"] =~ /darwin/ ? true : false
  end

  # Indirection points so tests can run the loop on a fake mouse / fake clock.
  def self.build_mouse
    RuMouse.new
  end

  def self.real_sleep(seconds)
    sleep(seconds)
  end

  def self.move_mouse(mouse, nudge:, wander:, positive:)
    if wander
      mouse.move(100 + rand(200), 100 + rand(200))
    else
      pos = mouse.position
      delta = positive ? nudge : -nudge
      mouse.move(pos[:x] + delta, pos[:y]) # fixed axis (x): the twitch is invisible
    end
  end
end
