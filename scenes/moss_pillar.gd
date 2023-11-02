@tool

extends Node3D

@export var shellAmount : int = 16

# Called when the node enters the scene tree for the first time.
func _ready():
	var shells = Node3D.new();
	shells.name = "Shells"
	for n in shellAmount:
		var scene = preload("res://scenes/base_pillar.tscn");
		var node = scene.instantiate();
		var mat = node.get_surface_override_material(0).duplicate();
		mat.set_shader_parameter("shellIndex", n);
		mat.set_shader_parameter("shellCount", shellAmount);
		node.set_surface_override_material(0, mat);
		shells.add_child(node);
		# node.set_owner(get_tree().edited_scene_root);
	add_child(shells)
	shells.set_owner(get_tree().edited_scene_root);
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
