# Roblox to Godot: A Translation Guide

## How to use this guide

This guide is a translation layer. Entries come in four kinds, and the first is the least useful one:

**Direct equivalents.** Same concept, different name.

**Same idea, different structure.** The concept exists but is shaped differently, usually split into more pieces.

**Doesn't exist, you build it.** The most important category. Roblox gives you an enormous amount for free, and some of it simply has no Godot counterpart. It's good to know this up front.

**No longer needed.** Habits that exist purely to work around Roblox's architecture. These won't exist or be required within Godot.

A note on tone before you start: Godot will feel like it's requiting you to do more work, and for the first week it actually is. Most of that is Godot declining to make a decision on your behalf. As an example, Roblox's `Humanoid` is a hundred decisions someone else already made. This is wonderful until you want to change one of them.

---

## Before you start: four shifts

### 1. No Base Game

Roblox Studio is a live session. You press play and you're inside a world that already exists, with a server, a player, a character, a camera, and a baseplate. Godot starts with nothing. An empty project has no camera, no light, no ground, no player, and pressing play gives you a blank window.

This is the single biggest source of early frustration, and it isn't a missing feature, Godot doesn't assume you're making a Roblox-shaped game. Your first hour should be spent building a scene that gets you back to the Roblox starting line: a ground plane, a light, a camera, a character controller.

### 2. Scene Tree Architecture

Roblox has a `DataModel` with fixed top-level services, and you organise your work inside the slots Roblox gave you. Godot has a `SceneTree` with no prescribed structure at all. You invent the hierarchy.

The corresponding idea to Roblox's services is the **autoload** (also called a singleton): a script or scene that Godot instantiates once at startup and parents above your main scene, reachable by name from anywhere. If you want something that behaves like `ReplicatedStorage`, you make an autoload and call it that.

### 3. Scenes & Prefabs

A Godot **scene** is a saved tree of nodes in a `.tscn` file. The word is misleading: a scene is not "a level". It's closer to a Roblox `Model` in `ReplicatedStorage` that you clone. The main difference being it is also your level, also your UI, also your bullet, also your entire game.

The pattern is: build a tree, save it as a scene, instance it anywhere (including inside other scenes). A level is a scene containing instances of prop scenes.

### 4. Broken Down Purpose

Roblox instances are chunky. A `Part` is a mesh, a collider, and a physics body at once. Godot nodes are deliberately narrow, with one job each, and you build what you want by parenting them together.

---

## Direct equivalents

Same concept, different name.

### Instances and the tree

| Roblox | Godot |
| --- | --- |
| `Instance` | `Node` |
| `Instance.new("Part")` | `MeshInstance3D.new()` |
| `:Clone()` | `.duplicate()` |
| `:Destroy()` | `.queue_free()` |
| `.Parent = x` | `x.add_child(node)` |
| `:FindFirstChild("x")` | `get_node_or_null("x")` |
| `:GetChildren()` | `get_children()` |
| `:GetDescendants()` | `find_children("*", "", true)` |
| `:IsA("BasePart")` | `node is MeshInstance3D` |
| `.Name` | `.name` |
| `game.Workspace` | your main scene root |
| `script.Parent` | `get_parent()` |
| `CollectionService` tags | groups |

### Scripting and lifecycle

| Roblox | Godot |
| --- | --- |
| `ModuleScript` | `class_name` script, or `preload()` |
| `require(module)` | `preload("res://x.gd")` |
| `RunService.Heartbeat` | `_process(delta)` |
| `RunService.RenderStepped` | `_process(delta)` |
| `RunService.Stepped` | `_physics_process(delta)` |
| `task.wait(n)` | `await get_tree().create_timer(n).timeout` |
| `task.spawn(f)` | `f.call_deferred()` |
| `task.defer(f)` | `call_deferred("f")` |
| `tick()` / `os.time()` | `Time.get_ticks_msec()` |
| `warn(x)` | `push_warning(x)` |
| `print(x)` | `print(x)` |
| `pcall(f)` | no equivalent - see mistakes |

### Events

| Roblox | Godot |
| --- | --- |
| `BindableEvent` | `signal` |
| `:Connect(f)` | `.connect(f)` |
| `:Once(f)` | `.connect(f, CONNECT_ONE_SHOT)` |
| `:Disconnect()` | `.disconnect(f)` |
| `:Wait()` | `await signal_name` |
| `:Fire(args)` | `emit_signal("name", args)` |
| `.Changed` | per-property setters, or `NOTIFICATION_*` |
| `:GetPropertyChangedSignal()` | a `set` accessor on an exported var |

### Physics and space

| Roblox | Godot |
| --- | --- |
| `CFrame` | `Transform3D` |
| `CFrame.LookVector` | `-transform.basis.z` |
| `Vector3` | `Vector3` |
| `Region3` | `Area3D` |
| `Raycast` / `RaycastParams` | `PhysicsRayQueryParameters3D` |
| `RaycastResult.Instance` | `result.collider` |
| `.Touched` | `Area3D.body_entered` |
| `.TouchEnded` | `Area3D.body_exited` |
| `Anchored = true` | `StaticBody3D` |
| `Anchored = false` | `RigidBody3D` |
| `CollisionGroup` | collision layers and masks |
| `BodyVelocity` (legacy) | `linear_velocity` |
| `AlignPosition` / constraints | `Joint3D` types |
| `workspace.Gravity` | project setting, or `gravity_scale` |

### UI

| Roblox | Godot |
| --- | --- |
| `ScreenGui` | `CanvasLayer` |
| `Frame` | `Control`, `Panel` |
| `TextLabel` | `Label` |
| `TextButton` / `ImageButton` | `Button` / `TextureButton` |
| `TextBox` | `LineEdit`, `TextEdit` |
| `ImageLabel` | `TextureRect` |
| `ScrollingFrame` | `ScrollContainer` |
| `UIListLayout` | `VBoxContainer` / `HBoxContainer` |
| `UIGridLayout` | `GridContainer` |
| `UIPadding` | `MarginContainer` |
| `UIAspectRatioConstraint` | `AspectRatioContainer` |
| `UDim2` scale and offset | anchors plus offsets |
| `BillboardGui` | `Sprite3D`, or a `SubViewport` |
| `SurfaceGui` | `SubViewport` on a material |

### Animation, audio, input

| Roblox | Godot |
| --- | --- |
| `TweenService:Create()` | `create_tween()` |
| `AnimationController` | `AnimationPlayer` |
| animation blending | `AnimationTree` |
| `Sound` in a part | `AudioStreamPlayer3D` |
| `Sound` (2D) | `AudioStreamPlayer` |
| `SoundGroup` | audio bus |
| `UserInputService` | `Input` singleton |
| `ContextActionService` | input map actions |
| `:IsKeyDown()` | `Input.is_action_pressed()` |
| `InputBegan` | `_unhandled_input(event)` |
| `Mouse.Hit` | camera `project_ray_normal()` plus a raycast |

### Networking

| Roblox | Godot |
| --- | --- |
| server | peer id 1, the host |
| `RemoteEvent` | `@rpc("any_peer") func` |
| `:FireServer()` | `rpc_id(1, "name", args)` |
| `:FireClient(plr)` | `rpc_id(peer_id, "name", args)` |
| `:FireAllClients()` | `rpc("name", args)` |
| `RemoteFunction` | nothing - you build it |
| automatic replication | `MultiplayerSynchronizer` |
| server-side instancing | `MultiplayerSpawner` |
| `SetNetworkOwner` | `set_multiplayer_authority()` |
| `Players.PlayerAdded` | `multiplayer.peer_connected` |
| `IsServer()` | `multiplayer.is_server()` |
| `LocalPlayer` | `multiplayer.get_unique_id()` |

---

## Same idea, different structure

These exist in both engines but are shaped differently.

### Part becomes three nodes

A Roblox `Part` is simultaneously a visual mesh, a collision volume, and a physics body. Godot splits these into separate nodes that you parent together:

```
RigidBody3D           the physics body
├── MeshInstance3D    what you see
└── CollisionShape3D  what you hit
```

Anchored becomes `StaticBody3D`. Unanchored becomes `RigidBody3D`. A trigger volume with no collision response becomes `Area3D`. A player or NPC you move with code rather than forces becomes `CharacterBody3D`.

It makes sense when you need a hitbox that isn't a model, or a collider covering multiple meshes, or visuals with no collision at all. On roblox you fight `CanCollide` and track invisible parts.

### Scripts attach to nodes, and there is no Script/LocalScript split

On Roblox, a script's *location* determines where it runs. A `Script` in `ServerScriptService` runs on the server; a `LocalScript` in `StarterPlayerScripts` runs on the client.

Godot has one kind of script and it runs wherever the node exists. Context is something you check instead of declaring it:

```gdscript
func _ready():
	if multiplayer.is_server():
		_setup_authoritative_state()
	else:
		_setup_local_visuals()
```

This is more error-prone than Roblox's approach, because nothing stops you from writing server logic that also runs on clients. A distinction needs to be made prior.

### Services become autoloads

Roblox's services are fixed. Godot's equivalent is the autoload, configured in Project Settings → Autoload: a script or scene instantiated once at startup, parented above your main scene, this makes it defined globally. Similar to `script` or `workspace` in Roblox Studio.

If you want Roblox's shape, make them yourself. An autoload named `Players` holding a dictionary of connected peers, one named `ReplicatedStorage` holding preloaded scenes. Use them sparingly, though. Roblox pushes you toward globals because the service model is global; Godot code generally ages better when things are passed in rather than reached for.

### Replication is explicit

Roblox replicates property changes on anything under `Workspace` automatically. Godot replicates nothing unless you specify.

You ask with two nodes. `MultiplayerSpawner` watches a path and replicates the creation and deletion of children under it, so the server instancing a scene there causes clients to instance it too. `MultiplayerSynchronizer` sits inside a scene and carries a list of properties to keep in sync, with per-property choice of every frame or on-change.

This is more setup than Roblox and it's better for a competitive game, because bandwidth is a budget and Roblox spends it for you. Being forced to name every replicated property means you notice when the list gets expensive.

### CFrame becomes Transform3D

Both store position and orientation together. The differences that matter:

`CFrame.new(x, y, z)` becomes `Transform3D(Basis(), Vector3(x, y, z))`, though in practice you'll usually set `position` directly. `CFrame.Angles(rx, ry, rz)` becomes `Basis.from_euler(Vector3(rx, ry, rz))` - both in radians. Multiplication composes transforms in both, and in both the order matters and reads left-to-right as parent-to-child.

### ModuleScript becomes a class or a resource

A `ModuleScript` returning a table becomes one of two things in Godot.

For code you want to call, give the script a `class_name` and it becomes globally available as a type. For shared *data* - stats, weapon configs, level definitions - the idiomatic answer is a custom `Resource`, which you can create as a file, edit in the inspector, and reference from scenes. There is no real Roblox equivalent to a resource, and it's one of the genuinely nicer things about Godot once it clicks.

---

## Doesn't exist - you build it

This is the section to read before planning anything. Roblox gives you an enormous amount for free, and a good share of it has no Godot counterpart at all. Nothing here is a Godot deficiency - Godot is an engine, and Roblox is an engine plus a platform plus a backend plus a storefront. But if you budget as though these are free, your schedule is wrong from day one.

### Humanoid

The big one. `CharacterBody3D` gives you a capsule and `move_and_slide()`. That's it.

`Humanoid` gives you health and death, walk speed and jump power, states (running, jumping, swimming, climbing, seated), automatic animation blending from the state, ragdoll on death, nametags, seat support, auto-stepping over obstacles, slope limits, and hip-height ground alignment. Every one of those is yours to write.

Budget a week or two for a character controller that feels as good as Roblox's default, and expect the last 20% - step handling, slope behaviour, coyote time, air control - to take longer than the first 80%. Start from a community controller rather than a blank file.

### DataStoreService

Godot has no backend. None. There is no persistence service, no key-value store, no cloud anything.

Your options are local files under `user://` (fine for single-player saves, useless for anything a player could edit), or a server you run yourself - which means a real backend: a host, a database, an API, auth, and the operational burden of all of it. Plan this before you need it, because it determines your whole architecture.

### Player and character lifecycle

Roblox spawns a player, builds them a character from their avatar, parents it to the workspace, gives them a camera, respawns them on death, and hands you `Players.LocalPlayer`. Godot does none of this.

You write: the peer-connected handler, the player registry, character scene instantiation, spawn point selection, camera setup, the death and respawn cycle, and cleanup on disconnect. It's not hard, but it's a system, and it's the first one you'll need.

### The whole platform layer

No `MarketplaceService`, no developer products, no game passes, no Robux. Monetisation on Steam means Steamworks; on mobile it means the platform stores. Each is its own integration.

No avatar system, no catalog, no `Players:GetUserThumbnailAsync`. No built-in chat with filtering. No text or image moderation - and if you ship user-generated content or chat to an audience including minors, that moderation obligation is yours now, legally as well as practically. No built-in analytics. No matchmaking service. No friends list or social graph outside what a platform SDK gives you.

### Team Create

No real-time collaborative editing. Godot uses version control, which means Git, which means teaching your artists Git. The `.tscn` scene format is text and merges better than binary formats do, but merging two people's edits to the same scene is still unpleasant. Structure your project so people own separate scenes.

### Terrain

No voxel terrain editor. Godot has `HeightMapShape3D` for collision and community addons for terrain and voxels, but nothing comparable to Roblox's smooth terrain tooling out of the box.

### The Toolbox

No in-editor library of free models and assets. Godot's Asset Library is mostly addons and tools, not art. You're sourcing assets from Kenney, Poly Haven, itch, Sketchfab or an artist.

### Streaming

No `StreamingEnabled`. If your world is bigger than memory, you write the loading and unloading yourself.

### A word on what you get in exchange

Every item above is real cost, and the list is long enough to be discouraging. The thing on the other side of the ledger is that none of it is a black box any more. When Roblox's character controller does something you don't like, you work around it forever. When yours does, you fix it. Whether that trade is worth it depends entirely on how much your game wants to do something Roblox wasn't shaped for.

---

## No longer needed

Habits that exist only to work around Roblox's architecture. Delete them.

### WaitForChild

Roblox streams instances in, so a child may not exist when your script runs. Godot loads a scene synchronously and completely before `_ready()` fires. Everything in your scene is there.

```gdscript
@onready var health_bar = $UI/HealthBar
```

It's simply there. No waiting, no timeout, no nil check. If a path is wrong you get an error immediately, which is better.

### Defensive FindFirstChild

If the node is part of your own scene, it exists. Reserve `get_node_or_null()` for genuinely optional things - a weapon that may or may not be equipped - rather than using it everywhere out of habit.

### Instance.new then set Parent last

The Roblox performance ritual of configuring an instance fully before parenting it has no equivalent here. `add_child()` when you like.

### Debris service

```gdscript
await get_tree().create_timer(3.0).timeout
queue_free()
```

Or a `Timer` node with one-shot and autostart, connected to `queue_free`.

### StreamingEnabled concerns

Nothing streams unless you make it. The class of bug where a part existed on the server but not yet on a client doesn't exist.

### Worrying about replication cost by accident

On Roblox, setting a property on a `Workspace` instance might replicate to every client. In Godot nothing replicates unless a `MultiplayerSynchronizer` names that property. You can mutate freely and think about bandwidth only where you opted in.

### Waiting on game:IsLoaded()

No equivalent needed. `_ready()` means ready.

---

## Mistakes that will bite you

Each of these has cost someone a full day. They're ordered roughly by how quickly you'll hit them.

### Arrays start at 0

Lua is 1-indexed. GDScript is 0-indexed. `for i in range(items.size())` starts at zero, `items[0]` is the first element, and `#t` becomes `items.size()`. This will catch you more than once in the first week.

### position is local, global_position is world

The worst one, because it fails quietly.

Roblox's `Part.Position` is **always world space**, whatever the part is parented to. Godot's `position` is **relative to the parent**. If your node is a child of anything that isn't at the origin, setting `position` will not put it where you expect.

```gdscript
node.position = Vector3(0, 10, 0)
node.global_position = Vector3(0, 10, 0)
```

The first is 10 units above the parent. The second is 10 units above the world origin.

The same split applies to `transform` and `global_transform`, and to `rotation` and `global_rotation`. When translating Roblox code, `global_position` is almost always the one you want.

### Studs are not metres

One Roblox stud is conventionally treated as about 0.28 metres, so Godot units - which are metres by default for physics - are roughly three and a half times larger. Copying coordinates or sizes straight across makes everything enormous and makes gravity feel like the moon.

In practice most people don't convert precisely. Pick a character height in metres that looks right (1.8 is a reasonable human), scale your world to that, and retune movement values by feel. Do this at the very start; rescaling a built level is miserable.

### queue_free is deferred

`Destroy()` is immediate. `queue_free()` marks the node for deletion at the end of the current frame. Between the call and the actual free, the node still exists and still processes.

```gdscript
node.queue_free()
print(is_instance_valid(node))
```

That prints `true`. If you need it gone right now, `free()` does that - but only when you're certain nothing else is mid-signal on it. Checking `is_queued_for_deletion()` is often what you actually want.

### Freed nodes and null are different things

A freed node reference isn't null, it's a dangling object, and touching it raises an error. `if node:` is not a sufficient check. Use `is_instance_valid(node)`.

### No pcall

GDScript has no exceptions and no protected call. Errors either print and continue or crash. You cannot wrap risky code and recover. This changes how you write defensive code: validate inputs up front rather than catching failures after.

### Methods use a dot

Lua's `:` for method calls versus `.` for fields doesn't exist here. Everything is `.`. Minor, but it'll trip your fingers for a week.

### Signal arguments must match exactly

Roblox is relaxed about connecting a function with the wrong number of parameters. Godot errors. If a signal emits two arguments, your handler takes exactly two - no more, no fewer. Use `.bind()` to attach extra context rather than adding parameters.

### Degrees in the inspector, radians in code

`rotation` is in radians. `rotation_degrees` is in degrees, and the inspector shows degrees. Mixing them produces rotations that are wrong by a factor of about 57, which at least is obvious.

Roblox's `CFrame.Angles` is radians too, so code translates cleanly - it's the inspector that's the odd one out.

### _process versus _physics_process

`_process` runs once per rendered frame at whatever rate the machine manages. `_physics_process` runs at a fixed rate (60 Hz by default) and is where all physics and movement belongs. Putting `move_and_slide()` in `_process` produces movement that varies with framerate - and in multiplayer, desynchronises clients.

### The authority default will silently eat your RPCs

Worth repeating because it's the single most common Godot multiplayer bug. `@rpc` with no arguments defaults to `authority`, meaning only the authority may call it. A client calling it does nothing - no error, no warning, nothing happens. If a client-to-server call mysteriously doesn't work, check for a missing `"any_peer"`.

### Node paths break when you rename

`$UI/HealthBar` is a string path resolved at runtime. Renaming the node in the editor does not update the script, and you find out when it runs. Prefer `@onready` at the top of the file so failures happen at load, and consider `@export var health_bar: Control` with the node dragged in - then the editor maintains the link for you.

### Forward is -Z in both

A relief rather than a gotcha, and worth knowing so you don't second-guess it: both engines are Y-up and right-handed, and in both, an object's forward direction is its local **negative** Z. Roblox's `LookVector` corresponds to `-transform.basis.z`. Your spatial intuition transfers intact.

---

## A suggested order

The temptation is to port your Roblox project immediately. Don't. You'll make every structural mistake at once, in a codebase you care about.

**First, rebuild the starting line.** Make a scene with a ground plane, a light, a camera, and a capsule you can move with WASD. This sounds trivial and it is the single most useful hour you'll spend, because it forces you through node composition, input maps, `_physics_process`, and the local-versus-global position trap in a context where nothing is at stake.

**Second, learn scenes as prefabs.** Build something small, save it as its own scene, and instance twenty of them from code. Once the scene-as-prefab idea clicks, Godot's architecture stops feeling arbitrary.

**Third, write a character controller you're happy with.** Don't port one and don't accept the first tutorial's. This is the thing you'll interact with for the rest of the project, and Roblox spoiled you - a controller that feels merely okay will undermine everything built on top of it.

**Fourth, then networking.** Two instances on one machine, one hosting, a synchronised cube. Get that working before anything ambitious. Godot's multiplayer is genuinely straightforward once the authority model is clear, and genuinely baffling before that.

**Only then port anything.** And port the design, not the code. Your Roblox scripts encode a decade of Roblox-specific assumptions; translating them line by line produces something that works badly and reads worse.

### Where to look things up

The official docs are the right reference, and the class reference in particular is excellent - it's also built into the editor, so pressing F1 or ctrl-clicking a type takes you straight there. Read the multiplayer tutorial page properly rather than skimming; it's short and the authority model is the thing you most need to get right.

For questions, the Godot forum and the community Discord both have people who've made this exact switch.

### One last thing

The hardest part of this transition isn't technical. It's that on Roblox you were fast, and for a while here you won't be. That's not a signal you chose wrong - it's the cost of the engine not making decisions for you, paid up front, in exchange for never hitting a wall you can't get through later.

---

*Corrections and additions welcome. If you hit something this guide didn't warn you about, please open an issue.*
