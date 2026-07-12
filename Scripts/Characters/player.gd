extends CharacterBody2D

# movement related constants
const SPEED = 300.0
const ACCELERATION = 2000
const FRICTION = 2000
var current_direction_moving = 0.0

# jump related constants
const JUMP_VELOCITY = -400.0
const JUMP_CUT = .35
const MAX_JUMPS = 2
const JUMP_BUFFER_TIME = 0.12

#wall slide related constants
const TERMINAL_VELOCITY = 1012.6 #arbitrary number likely to never be hit, lower means slower fall
const WALL_SLIDE_SPEED = 25.0 # set speed of which terminal velocity will be divided by on a wall
const WALL_PUSH_SPEED = 600 # the strength of which the player will push away from the wall whilst sliding
const WALL_SLOPE = .7

#dash related constants
const DASH_VELOCITY = 1600
const MAX_DASHES = 2
const DASH_COOLDOWN = 3

# jump related variables
var jump_buffer_timer = 0.0
var jumps_remaining = MAX_JUMPS

# wall slide related variables
var current_max_terminal_velocity = TERMINAL_VELOCITY
var current_wall_push_speed = WALL_PUSH_SPEED
var current_collision = null
var current_collision_normal = null
var wall_normal = Vector2(0,0)

#dash related varibles
var remaining_dash_cooldown = 0.0
var dashes_remaining = MAX_DASHES
var facing_direction = 1


#physics functions
func _physics_process(delta) -> void:
	
	
	# Add the gravity.
	add_gravity(delta)
	
	
	#update how long before checking if able to jump
	update_jump_buffer(delta)
	
	
	
	#handle horiziontal movement
	
	current_direction_moving = handle_movement(delta)
	
	#save last known movement direction as facing direction value. THESE ARE NOT THE SAME, FACING DIRECTION CANNOT BE 0!
	if current_direction_moving != 0:
		facing_direction = current_direction_moving
	
	
	
	update_wall_normal()
	
	
	
	# Handle jump
	handle_jump()
	
	
	
	# Handle dash
	handle_dash()
	
	
	# after handling dash then update cooldown, must be post handle
	update_dash_cooldown(delta)
	
	
	# handle wall slide
	handle_wall_slide()
	
	
	
	
	# this pushes all changes to screen
	move_and_slide()



func update_jump_buffer(delta) -> void:
	
	#if jump is pressed, set a timer. otherwise reduce timer by time between frames until 0
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)



func add_gravity(delta) -> void:
	#print(velocity)
	
	#if not on floor, add gravity velocity times time between frames.
		#if not is_on_floor() and velocity.y <= current_max_terminal_velocity:
			#
				#velocity += get_gravity() * delta
		#elif not is_on_floor():
				#velocity.y = current_max_terminal_velocity

	if not is_on_floor():
		#Try to add gravity
		if velocity.y <= current_max_terminal_velocity:
			#add gravity and speed up
			velocity += get_gravity() * delta
		else:
			#Falling too fast
			velocity.y = current_max_terminal_velocity



func handle_jump() -> void:
	
	#if touching the floor, you have 2 jumps stored at all times
	if is_on_floor() or is_on_wall():
		jumps_remaining = MAX_JUMPS
		
	
	
		
	#if the timer was set by clicking the jump button, it is close enough to when you pushed the jump button to activate
	#and so long as you have more than 0 jumps stored, increase y velocity by a negative (upwards) constant
	#subtract stored jump
	#also adds a wall push speed, so if touching a wall and no floor, you get pushed away from wall
	if jump_buffer_timer > 0 and jumps_remaining > 0:
		velocity.y = JUMP_VELOCITY
		velocity.x = velocity.x + current_wall_push_speed * wall_normal.x
		jumps_remaining  -= 1
		jump_buffer_timer = 0
		
	#if jump button released before the gravity overtakes upwards velocity, it will reduce upwards velocity by 75%
	#this allows the player to do smaller, more precise jumps by releasing the jump button sooner.
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y = velocity.y * JUMP_CUT



func handle_movement(delta) -> float:
	
	#creates a varible equal to the value of direction using a positive / negative scale
	# left would be -1, right would be 1. both adds to 0
	var direction := Input.get_axis("move_left", "move_right")
	
	# if direction isnt 0, change x velocity by direction and speed, by an increment of acceleration per frame
	# if direction is 0, change x velocity towards 0, by an increment of friction per frame
	if direction !=0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
	
	return direction



func handle_dash() -> void:
	
	# if on floor dashes reset
	if is_on_floor():
		dashes_remaining = MAX_DASHES
		
	# if the dash button pushed, and you have dashes remaining, AND your cooldown is 0.0, you may dash
	if Input.is_action_just_pressed("dash") and dashes_remaining > 0 and remaining_dash_cooldown == 0.0:
			
			velocity.x = DASH_VELOCITY * facing_direction
			dashes_remaining -= 1



func update_dash_cooldown(delta) -> void:
	
	#if you have a dash cooldown, reduce its timer
	
	if remaining_dash_cooldown != 0.0:
		remaining_dash_cooldown = max(remaining_dash_cooldown - delta, 0.0)
	
	#if dash cooldown does equal 0.0, and you push the dash button, set the cooldown. (no need to check if dash is pushed if you have cooldown, just wasting more computer power.)
	elif Input.is_action_just_pressed("dash"):
		remaining_dash_cooldown = DASH_COOLDOWN



func handle_wall_slide() -> void:
	
	#if touching the wall and not touching the floor, terminal velocity is lowered, because sliding on a wall.
	if is_on_wall() and not is_on_floor():
		current_max_terminal_velocity = TERMINAL_VELOCITY / WALL_SLIDE_SPEED
		current_wall_push_speed = WALL_PUSH_SPEED
		
		
	#otherwise set it to the normal terminal velocity and set the wall push off speed to none (since there is no wall, or you are touching a floor)
	else:
		current_max_terminal_velocity = TERMINAL_VELOCITY
		current_wall_push_speed = 0



func update_wall_normal() -> void:
	#check if touching wall
	if is_on_wall():
		#check all possible collisions to see if their is a vector matching that of a wall
		for i in range(get_slide_collision_count()):
			current_collision = get_slide_collision(i)
			current_collision_normal = current_collision.get_normal()
			
			#if the x is bigger than the determinded wall slope, then use that as a vector.
			if abs(current_collision_normal.x) > WALL_SLOPE:
				wall_normal = current_collision_normal
