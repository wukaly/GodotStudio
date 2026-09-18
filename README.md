# GodotStudio

**Coming to Godot from Roblox Studio.** A Godot template, a compatibility add-on, and translation document for developers experienced with Roblox Studio.

If you have a lot of experience in Roblox Studio. Learning Godot can be quite easy, the goal of this repo is to bridge that gap by making connections across both engines as well as providing tools to jump start the journey.

- **[Full translation guide](docs/translation-guide.md)** | Concepts and translations linked between Godot and Roblox Studio
- **Addon** (`addons/GodotStudio/`) | Familiar service names and replication helpers over Godot-native structures
- **Template** (`demo/`) | A project that closely resembles a starting place in Roblox Studio

---

## Quick reference

The tables below cover the most common lookup comparisons. The [full guide](docs/translation-guide.md) has the rest, plus the parts that need a paragraph rather than a simple row.

### Instances and the tree

| Roblox | Godot |
| --- | --- |
| `Instance` | `Node` |
| `:Clone()` | `.duplicate()` |
| `:Destroy()` | `.queue_free()` |
| `.Parent = x` | `x.add_child(node)` |
| `:FindFirstChild("x")` | `get_node_or_null("x")` |
| `:GetChildren()` | `get_children()` |
| `:IsA("BasePart")` | `node is MeshInstance3D` |
| `:WaitForChild("x")` | not needed — `@onready var x = $x` |
| `game.Workspace` | your main scene root |
| `CollectionService` tags | groups |

### Scripting and lifecycle

| Roblox | Godot |
| --- | --- |
| `ModuleScript` | `class_name` script, or `preload()` |
| `RunService.Heartbeat` | `_process(delta)` |
| `RunService.Stepped` | `_physics_process(delta)` |
| `task.wait(n)` | `await get_tree().create_timer(n).timeout` |
| `BindableEvent` | `signal` |
| `:Connect(f)` | `.connect(f)` |
| `:Wait()` | `await signal_name` |
| `pcall(f)` | no equivalent |

### Physics and space

| Roblox | Godot |
| --- | --- |
| `Part` (anchored) | `StaticBody3D` + `MeshInstance3D` + `CollisionShape3D` |
| `Part` (unanchored) | `RigidBody3D` + children |
| character / NPC | `CharacterBody3D` |
| `CFrame` | `Transform3D` |
| `CFrame.LookVector` | `-transform.basis.z` |
| `.Touched` | `Area3D.body_entered` |
| `Region3` | `Area3D` |
| `Raycast` | `PhysicsRayQueryParameters3D` |

### UI

| Roblox | Godot |
| --- | --- |
| `ScreenGui` | `CanvasLayer` |
| `Frame` | `Control`, `Panel` |
| `TextLabel` | `Label` |
| `TextButton` | `Button` |
| `ScrollingFrame` | `ScrollContainer` |
| `UIListLayout` | `VBoxContainer` / `HBoxContainer` |
| `UDim2` | anchors plus offsets |

### Networking

| Roblox | Godot |
| --- | --- |
| server | peer id 1, the host |
| `RemoteEvent` | `@rpc("any_peer") func` |
| `:FireServer()` | `rpc_id(1, "name", args)` |
| `:FireAllClients()` | `rpc("name", args)` |
| `RemoteFunction` | nothing built in |
| automatic replication | `MultiplayerSynchronizer` |
| `SetNetworkOwner` | `set_multiplayer_authority()` |
| `Players.PlayerAdded` | `multiplayer.peer_connected` |

---

## The most common mistakes

1. **Arrays start at 0.** Lua is 1-indexed, GDScript is 0-indexed.
2. **`position` is local, `global_position` is world.** Roblox's `Part.Position` is always world space. Godot's `position` is relative to the parent.
3. **Studs are not metres.** A stud is roughly 0.28 m.
4. **`queue_free()` is deferred.** The node still exists until the end of the frame.
5. **`@rpc` defaults to `authority`.** A client calling it does nothing; no error, no warning. Add `"any_peer"`.

Full list with explanations: [mistakes](docs/translation-guide.md#mistakes-that-will-bite-you).

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
