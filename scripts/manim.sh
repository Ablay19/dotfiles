/usr/bin/env bash
udoocker run --rm -v ~/{{manim_projects}}:/manim manimcommunity/manim:latest manim -pql example_scenes.py SquareToCircle
