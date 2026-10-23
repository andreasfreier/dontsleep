# dontsleep

Keep your Mac awake by moving the mouse a couple of pixels.

macOS decides you're "idle" when the mouse and keyboard have been still for a
while — and then it sleeps, killing your SSH sessions, your builds, your
downloads, and whatever else was patiently running. `dontsleep` prevents that
by nudging the cursor **2 pixels** now and then: invisible to you, convincing
to the operating system.

> **macOS only.** The gem depends on `rumouse`, which drives the mouse through
> macOS' Core Graphics events. On other platforms it installs fine but refuses
> to run, with a clear message. (Linux/Windows support: open an issue or send
> a patch — we'd love that.)

## Installation

```ruby
# Gemfile
gem "dontsleep"
```

or simply:

```sh
gem install dontsleep
```

Requires macOS and a Ruby ≥ 2.5 with the `ffi` gem (pulled in automatically).
You will need to grant your terminal **Accessibility** permission under
*System Settings → Privacy & Security → Accessibility* — that's macOS asking
nicely that an app may move the mouse. It asks once.

## Usage

The executable does the job:

```sh
dontsleep                    # 2px nudge every 60s, runs until you press Ctrl-C
dontsleep --minutes 120      # …and stops itself after 2 hours
dontsleep --interval 30      # more frequent, smaller heartbeats
dontsleep --wander           # old-school mode: teleport to a random spot —
                             # for unattended machines you're not touching
dontsleep --quiet            # no heartbeat dots
```

From Ruby:

```ruby
require "dontsleep"
Dontsleep.start(minutes: 60)   # e.g. wrapped around a long build
```

A `.` is printed with each nudge, so you can see it's alive. Ctrl-C always
stops it cleanly.

## Why a nudge and not a wander?

The original idea — move the mouse to a random position — works, but every
minute it *yanks your cursor away* from wherever you're actually clicking.
A 2-pixel ping-pong (right, left, down, up…) resets the idle timer while
staying out of your way. `--wander` keeps the classic behavior for machines
you've left alone.

## Development

```sh
bundle exec rake        # run tests
bundle exec rake build  # build the gem
```

## License

[MIT](LICENSE.txt) — do whatever you like, no warranty, as with all
small utilities.
