extends CharacterBody3D

#@onready var player = get_tree().current_scene.get_node("player")

@export var patrolDestinations: Array[Node3D]
@export var speed = 3.0
@onready var rng = RandomNumberGenerator.new()
var currentDestination
var destinationValue

func _ready() -> void:
	pick_destination()

func _process(delta: float) -> void:
	if currentDestination != null:
		var lookingDirection = lerp_angle(deg_to_rad(global_rotation_degrees.y), atan2(-velocity.x, -velocity.z), 0.5) #smoothing rotation
		global_rotation_degrees.y = rad_to_deg(lookingDirection)
		update_target_location(currentDestination.global_position)

func _physics_process(delta: float) -> void:
	if currentDestination != null:
		var nextLocation = $NavigationAgent3D.get_next_path_position()
		var targetVelocity = (nextLocation - global_position).normalized() * speed
		velocity = velocity.move_toward(targetVelocity, 0.25)
		move_and_slide()

func pick_destination(dont_choose = null):
	destinationValue = rng.randi_range(0, patrolDestinations.size() - 1)
	currentDestination = patrolDestinations[destinationValue]
	if  dont_choose != null and currentDestination == patrolDestinations[dont_choose]:
		pick_destination(dont_choose)

func update_target_location(target_location):
	$NavigationAgent3D.target_position = target_location
