extends CharacterBody3D

@export var patrolDestinations: Array[Node3D]
@export var speed = 3.0

var currentDestination
var destinationValue


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	destinationValue = 0
	pick_destination()

func pick_destination():
	currentDestination = patrolDestinations[destinationValue]
	++destinationValue

func _physics_process(delta: float) -> void:
	if currentDestination != null:
		var nextLocation = $NavigationAgent3D.get_next_path_position()
		var targetVelocity = (nextLocation - global_position).normalized() * speed
		velocity = velocity.move_toward(targetVelocity, 0.25)
		move_and_slide()


func _process(delta: float) -> void:
	if currentDestination != null:
		var lookingDirection = lerp_angle(deg_to_rad(global_rotation_degrees.y), atan2(-velocity.x, -velocity.z), 0.5) #smoothing rotation
		global_rotation_degrees.y = rad_to_deg(lookingDirection)
		update_target_location(currentDestination.global_position)


func update_target_location(target_location):
	$NavigationAgent3D.target_position = target_location
