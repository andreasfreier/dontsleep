# frozen_string_literal: true

require "rbconfig"
require "dontsleep/version"
require "rumouse"

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

    mouse = RuMouse.new
    deadline = minutes ? Time.now + minutes * 60 : nil
    positive = true
    axis = 0

    until (deadline && Time.now > deadline)
      sleep interval
      move_mouse(mouse, nudge: nudge, wander: wander, positive: positive, axis: axis)
      positive = !positive
      axis = (axis + 1) % 2
      print "." unless quiet
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

  def self.move_mouse(mouse, nudge:, wander:, positive:, axis:)
    if wander
      mouse.move(100 + rand(200), 100 + rand(200))
    else
      pos = mouse.position
      delta = positive ? nudge : -nudge
      new_x = axis.even? ? pos[:x] + delta : pos[:x]
      new_y = axis.even? ? pos[:y] : pos[:y] + delta
      mouse.move(new_x, new_y)
    end
  end
end
