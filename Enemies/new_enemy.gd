extends CharacterBody3D

enum State { PATROL, CHASE }
var current_state = State.PATROL

@export var patrolDestinations: Array[Node3D]
@export var speed = 3.0
@export var chase_speed = 4.5 # Zombie rennt schneller beim Jagen
var lose_target_timer : float = 0.0
@export var lose_target_delay : float = 1.5 # Zeit in Sekunden, bis er aufgibt

var currentDestination
var destinationValue
var player: Node3D = null

@onready var nav_agent = $NavigationAgent3D
@onready var sight_raycast = $RayCast3D # Ziehe deinen RayCast hierhin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	destinationValue = 0
	pick_destination()

func pick_destination():
	currentDestination = patrolDestinations[destinationValue]
	
	if destinationValue == patrolDestinations.size() - 1:
		destinationValue = 0
	else: 
		destinationValue += 1
	
	print_debug("next destination: " + str(destinationValue))

func _physics_process(delta: float) -> void:
	# Sichtlinien-Check im Physik-Loop
	_check_player_visibility()
	
	# Logik je nach aktuellem Zustand
	match current_state:
		State.PATROL:
			if currentDestination != null:
				nav_agent.target_position = currentDestination.global_position
				_move_towards_target()
				print_debug("patrolling")
		State.CHASE:
			if player != null:
				nav_agent.target_position = player.global_position
				_move_towards_target(chase_speed)
				print_debug("chasing")
	
func _move_towards_target(current_speed: float = speed):
	var nextLocation = nav_agent.get_next_path_position()
	var targetVelocity = (nextLocation - global_position).normalized() * current_speed
	
	# Verhindert Zittern auf der Y-Achse
	targetVelocity.y = 0 
	
	velocity = velocity.move_toward(targetVelocity, 0.25)
	move_and_slide()


func _process(delta: float) -> void:
	# Drehung soll immer in Bewegungsrichtung stattfinden (egal ob Patrouille oder Jagd)
	if velocity.length() > 0.1:
		var lookingDirection = lerp_angle(deg_to_rad(global_rotation_degrees.y), atan2(-velocity.x, -velocity.z), 0.1) # 0.1 für weichere Drehung
		global_rotation_degrees.y = rad_to_deg(lookingDirection)


func update_target_location(target_location):
	$NavigationAgent3D.target_position = target_location
	
func _check_player_visibility():
	if player == null:
		# Wenn der Spieler die Area3D komplett verlässt, sofort patrouillieren
		if current_state == State.CHASE:
			current_state = State.PATROL
		return
	
	var space_state = get_world_3d().direct_space_state
	var start_pos = global_position + Vector3(0, 1.2, 0)
	
	var spieler_shape = player.get_node_or_null("CollisionShape3D")
	var ziel_pos : Vector3
	if spieler_shape:
		ziel_pos = spieler_shape.global_position 
	else:
		ziel_pos = player.global_position
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, ziel_pos)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	
	# Blicklinien-Auswertung
	if result and result.collider == player:
		# NPC SIEHT DEN SPIELER AKTUELL
		current_state = State.CHASE
		lose_target_timer = 0.0 # Timer zurücksetzen, da Sichtkontakt besteht
		return
		
	# NPC HAT DEN SPIELER GERADE AUS DEN AUGEN VERLOREN (oder Strahl flackert kurz)
	if current_state == State.CHASE:
		# Nutze get_process_delta_time() für physik-unabhängige Zeitrechnung
		lose_target_timer += get_process_delta_time()
		
		# Erst wenn die Zeit abgelaufen ist, wechselt er zurück zur Patrouille
		if lose_target_timer >= lose_target_delay:
			current_state = State.PATROL
			lose_target_timer = 0.0
	
# Signale für den Sichtbereich (Area3D)
func _on_sichtbereich_body_entered(body):
	if body.is_in_group("Spieler"):
		player = body

func _on_sichtbereich_body_exited(body):
	if body == player:
		player = null
		current_state = State.PATROL
