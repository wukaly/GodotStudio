# GodotStudio

**Coming to Godot from Roblox Studio.** A Godot template and compatibility plugin for developers experienced with Roblox Studio looking to switch to Godot.

If you have a lot of experience in Roblox Studio, learning Godot can be quite easy. The goal of this repo is to bridge that gap by making connections across both engines, as well as providing tools to jump start the journey.

**Requires Godot 4.x.**

---

## What's inside

This repo is itself a working Godot project.

```
project.godot        the template project
addons/GodotStudio/  the plugin
scenes/              the template's content
docs/                documentation for the plugin and template
```

- **Full adoption of the system** — use the whole repo as your starting point
- **Looking to branch out but still want Roblox Studio-like features** — take just `addons/GodotStudio/`

---

## Using it as a template

Click **Use this template** above, or clone it and delete any unnecessary files.
The plugin is already enabled, so everything works on first run.

---

## Using just the plugin

Copy `addons/GodotStudio/` into your own project's `addons/` folder, then enable it in **Project Settings > Plugins**.

---

## Design principle

This project is meant to be a bridge between engines, not a complete framework.

The goal is not to have you writing Roblox shaped code forever. It's so the transition is smoother, and those who are not eager to change can give Godot a shot, allowing them to slowly learn the engine for what it is.

The addon uses familiar names over Godot-native structures, and it will always say what's underneath. Where you see `ReplicatedStorage`, the docs tell you it's an autoload. Where you see a replication helper, they tell you it's wrapping `MultiplayerSynchronizer`. The goal is to lower the activation energy and then get out of the way.

---

## Contributing

**Experience reports are as valuable as code.** Everyone who makes this switch gets stuck on something different, and nobody hits all of it. If something in here was confusing, missing, or didn't behave the way your Roblox instincts expected, open an issue.

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Licence

MIT, matching Godot's own. See [LICENSE](LICENSE).

Not affiliated with or endorsed by Roblox Corporation or the Godot Foundation. "Roblox" and "Godot" are referenced only to describe what this project is for.
