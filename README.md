# GodotStudio

**Coming to Godot from Roblox Studio.** A Godot template, a compatibility add-on, and translation document for developers experienced with Roblox Studio.

If you have a lot of experience in Roblox Studio. Learning Godot can be quite easy, the goal of this repo is to bridge that gap by making connections across both engines as well as providing tools to jump start the journey.

- **[Full translation guide](docs/translation-guide.md)** | Concepts and translations linked between Godot and Roblox Studio
- **Addon** (`addons/GodotStudio/`) | Familiar service names and replication helpers over Godot-native structures
- **Template** (`demo/`) | A project that closely resembles a starting place in Roblox Studio

---

## Installing the addon

Copy `addons/GodotStudio/` into your project's `addons/` folder, then enable it in **Project Settings → Plugins**.

Or clone this repo and open it directly — the root is a working Godot project with the demo scenes.

**Requires Godot 4.x.**

---

## Using the template

Click **Use this template** above, or clone it and delete any unnecessary files. It will give you a scene with a ground plane, lighting, a third-person camera, and a character controller similar to Roblox Studio.

---

## Contributing

**The guide is the part that most needs you.** Everyone who makes this switch discovers one more catch, and nobody has them all. If you hit something the guide didn't warn you about, open an issue, or send a PR adding a row.

Adding a table row is a completely valid contribution and needs no discussion first. Larger changes to the addon are worth opening an issue for before writing code.

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Design principle

This project is meant to be a bridge between engines, not it's own framework.

The goal of this project is not to have you writing Roblox shaped code forever. It's so the transition is smoother, and those who are not eager to change can give Godot a shot. Allowing them to slowly learn the engine for what it is.

The addon uses familiar names over Godot-native structures, and they will always say what's underneath. Where you see `ReplicatedStorage`, the docs tell you it's an autoload. Where you see a replication helper, they tell you it's wrapping `MultiplayerSynchronizer`. The goal is to lower the activation energy and then get out of the way.

---

## Licence

MIT, matching Godot's own. See [LICENSE](LICENSE).

Not affiliated with or endorsed by Roblox Corporation. "Roblox" is referenced only to describe who this project is for.
