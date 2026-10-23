# frozen_string_literal: true

require "minitest/autorun"
require "rbconfig"
require "dontsleep/version"
require "dontsleep"

# A mouse double: records moves, reports its current position.
class FakeMouse
  attr_reader :moves

  def initialize
    @pos = { x: 500.0, y: 300.0 }
    @moves = []
  end

  def position
    @pos
  end

  def move(x, y)
    @pos = { x: x, y: y }
    @moves << { x: x, y: y }
  end
end

# Run N ticks of the *real* move_mouse decision logic against a fake mouse.
# Mirrors Dontsleep.start's loop: the sign flips every tick on one fixed axis.
def drive_ticks(mouse, n, wander: false, nudge: 2)
  positive = true
  n.times do
    Dontsleep.move_mouse(mouse, nudge: nudge, wander: wander, positive: positive)
    positive = !positive
  end
end
class DontsleepTest < Minitest::Test
  def test_nudge_cancels_out_over_many_ticks
    mouse = FakeMouse.new
    start = { x: 500.0, y: 300.0 }
    drive_ticks(mouse, 1000) # ~16 hours of ticking
    assert_in_delta start[:x], mouse.position[:x], 2.0 # at most one step off
    assert_equal start[:y], mouse.position[:y]         # y never moves at all
  end

  def test_wander_stays_in_its_rectangle
    mouse = FakeMouse.new
    drive_ticks(mouse, 50, wander: true)
    mouse.moves.each do |m|
      assert_operator m[:x], :>=, 100
      assert_operator m[:x], :<=, 300
      assert_operator m[:y], :>=, 100
      assert_operator m[:y], :<=, 300
    end
  end

  def test_platform_guard_is_a_boolean
    assert [true, false].include?(Dontsleep.on_mac?)
  end

  # Exercise the real loop with a fake mouse and no waiting.
  def test_start_loop_auto_stops
    fake = FakeMouse.new
    Dontsleep.define_singleton_method(:build_mouse) { fake }
    Dontsleep.define_singleton_method(:real_sleep) { |_s| }
    Dontsleep.define_singleton_method(:on_mac?) { true }

    result = Dontsleep.start(interval: 1, minutes: 0.001, quiet: true)

    assert_equal "stopped (auto-stop)", result
    assert_operator fake.moves.length, :>=, 1
  ensure
    # restore the real implementations for any later tests / runs
    Dontsleep.singleton_class.class_eval <<~RUBY
      def self.build_mouse
        RuMouse.new
      end

      def self.real_sleep(seconds)
        sleep(seconds)
      end

      def self.on_mac?
        RbConfig::CONFIG["host_os"] =~ /darwin/ ? true : false
      end
    RUBY
  end
end
