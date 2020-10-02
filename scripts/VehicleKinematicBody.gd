extends KinematicBody
class_name VehicleKinematicBody

var speed = 0.0
var steering = 0.0

export var acceleration = 10.0
export var friction_deceleration = 5.0
export var max_speed = 40.0

export var max_steering =  PI / 3 # radians
export var steering_speed = 4.2
export var steering_roll = 0.5
export var steering_yaw = 0.4
export var steering_center_multiplier = 4

export var hover_height = 0.6

export var gravity_acc = 10.0
export var hover_acc = 5.5

export var roll_speed = 6;
export var pitch_speed = 12;
export var yaw_speed = 8;

export var collision_speed_decrease = 10
export var max_trail_length = 2.5

# Vehicle instability
export var instability_period : float = 1.8
export var offset_position_max : Vector3 = Vector3(0.05, 0.03, 0.0)

var offset_position : Vector3
onready var timer_value : float = -1
onready var instability_node = get_node("CollisionShape")

onready var aabb = get_node("CollisionShape/ship").get_aabb()
onready var initial_pos = get_node("CollisionShape/ship").global_transform.origin
onready var ship_model = get_node("CollisionShape")
onready var initial_basis = get_node("CollisionShape/ship").global_transform.basis

onready var particles : Particles = get_node("CollisionParticles")
onready var trail_left : Trail3D = get_node("CollisionShape/ship/Trail3D Left")
onready var trail_right : Trail3D = get_node("CollisionShape/ship/Trail3D Right")

var contact_points = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	process_input(delta)
	
	# adjust trails to vehicle speed
	trail_left.length = (speed / max_speed) * max_trail_length
	trail_right.length = (speed / max_speed) * max_trail_length
	trail_left.segment_length = trail_left.length / trail_left.density_lengthwise
	trail_right.segment_length = trail_right.length / trail_right.density_lengthwise
	
	var ground_normal = get_gravity(delta)

	# apply steering
	global_transform.basis = global_transform.basis.rotated(global_transform.basis.y.normalized(), -steering * delta)
	
	# apply speed
	var velocity_vector = move_and_slide(global_transform.basis.xform(Vector3(0.0, 0.0, speed * -1)))
	
	# collision particles
	if get_slide_count() > 0:
		var col = get_slide_collision(0)
		if col.local_shape != ship_model:
			particles.global_transform.origin = col.position
			particles.emitting = true
	else:
		particles.emitting = false
	
	# Roll
	# Project the normal onto a plane of the Y axis
	# - Start with roll from normal of contact point, then add steering roll
	var p_z = Plane(global_transform.basis.z,0)
	var rot_vec_y = p_z.project(ground_normal.normalized())
	var z_rotation_angle = -global_transform.basis.y.angle_to(rot_vec_y) * sign(global_transform.basis.x.dot(rot_vec_y))
	global_transform.basis = global_transform.basis.orthonormalized().slerp( 
		global_transform.basis.rotated(global_transform.basis.z.normalized(), z_rotation_angle),
		delta * roll_speed)
	
	# ship model - roll & yaw
	vehicle_instability(delta)
	var ship_speed_precent = min(1, speed / max_speed)
	ship_model.transform.basis = ship_model.transform.basis.orthonormalized().slerp(
		initial_basis.rotated(initial_basis.z, -steering * steering_roll * ship_speed_precent) \
		.rotated(initial_basis.y, -steering * steering_yaw * ship_speed_precent), delta * roll_speed) \
		.rotated(initial_basis.z, sign(instability_node.translation.x) * Vector3.UP.angle_to(instability_node.translation + Vector3.UP * 10))
	
	# Yaw
	# - Project forward vector onto ground normal plane
	# - Adjust yaw towards this projection
	var p_x = Plane(ground_normal.normalized(), 0)
	var rot_vec_z = p_x.project(global_transform.basis.z)
	var x_rotation_angle = -global_transform.basis.z.angle_to(rot_vec_z) * sign(global_transform.basis.y.dot(rot_vec_z))
	global_transform.basis = global_transform.basis.orthonormalized().slerp( 
		global_transform.basis.rotated(global_transform.basis.x.normalized(), x_rotation_angle),
		delta * pitch_speed)
	
	# Pitch
	# - If we have collided, then turn towards direction of collision
	# velocity_vector.y = 0
	var y_rotation_angle = 0
	if velocity_vector != Vector3.ZERO:
		var p_y = Plane(global_transform.basis.y,0)
		var rot_vec_x = p_y.project(-velocity_vector).normalized()
		y_rotation_angle = global_transform.basis.z.angle_to(rot_vec_x) * sign(global_transform.basis.x.dot(rot_vec_x))
		global_transform.basis = global_transform.basis.orthonormalized().slerp( 
			global_transform.basis.rotated(global_transform.basis.y.normalized(), y_rotation_angle),
			delta * yaw_speed)
		
		# If we have collided, then slow down 
		if speed > collision_speed_decrease and abs(y_rotation_angle) > 0.1:
			speed -= collision_speed_decrease * abs(y_rotation_angle)
			#print("Collision: " + str(collision_speed_decrease * abs(y_rotation_angle)))

func vehicle_instability(delta):
	if timer_value > 0:
		timer_value -= delta
	else:
		offset_position = Vector3((randf()*2-1) * offset_position_max.x, (randf()*2-1) * offset_position_max.y, (randf()*2-1) * offset_position_max.z)
		var dist = (instability_node.translation - offset_position).length()
		timer_value = max(dist / offset_position_max.length(), 0.6) * instability_period

		var tween = $CollisionShape/Tween
		tween.interpolate_property(instability_node, "translation",
				instability_node.translation, offset_position, timer_value, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.start()

func process_input(delta):
		# speed
	if Input.is_action_pressed("ui_up") && speed < max_speed :
		speed = speed + acceleration * delta
	elif Input.is_action_pressed("ui_down") && speed > 0.0:
		speed = speed - (acceleration * delta / 2)
	elif speed != 0:
		if(speed > 0):
			speed = speed - min(friction_deceleration * delta, speed)
		if(speed < 0):
			speed = speed + min(friction_deceleration * delta, speed*-1)
	
	# steering
	if Input.is_action_pressed("ui_left") && steering > -max_steering * Input.get_action_strength("ui_left"):
		steering -= steering_speed * delta
	elif Input.is_action_pressed("ui_right") && steering < max_steering * Input.get_action_strength("ui_right"):
		steering += steering_speed * delta 
	elif steering != 0:
		if steering > 0:
			steering -= min(steering, steering_speed * delta * steering_center_multiplier)
		else:
			steering += min(steering * -1, steering_speed * delta * steering_center_multiplier)
	
func get_gravity(delta): 
	var space_state = get_world().direct_space_state
	var height_offset = Vector3(0, 0.1,0) * global_transform.basis.y
	var aabb_y = Vector3(0, aabb.position.y, 0)
	var ray_points = Array()
	
	# ray points down centre line
	ray_points.push_back( global_transform.origin + aabb_y * global_transform.basis.y  - (aabb.size.z/2) * global_transform.basis.z + height_offset)
	ray_points.push_back( global_transform.origin + aabb_y * global_transform.basis.y  + height_offset)
	ray_points.push_back( global_transform.origin + aabb_y * global_transform.basis.y  + (aabb.size.z/2) * global_transform.basis.z + height_offset)

	# find average distance and normal
	contact_points = 0
	var normal = Vector3.ZERO
	var distance = 0
	for point in ray_points:
		var to = point + global_transform.basis.y * -(hover_height + (gravity_acc-hover_acc) + height_offset.y )
		var coll = space_state.intersect_ray(point, to, [self])
		if coll:
			contact_points += 1
			distance += point.distance_to(coll.position) - height_offset.y 
			normal += coll.normal
	
	var grav_vector = Vector3.ZERO
	if !contact_points:
		grav_vector = Vector3(0, -gravity_acc , 0)
	else:
		normal /= contact_points
		distance /= contact_points
		grav_vector = Vector3(0, max(hover_acc * (hover_height  - distance), -gravity_acc), 0)
	
	move_and_slide(grav_vector)

	return normal
