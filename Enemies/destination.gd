extends Node3D

func enter_trigger(body):
	if body.name == "enemy" and body.currentDestination == self:
		body.pick_destination()
