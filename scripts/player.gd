extends Node

"""
Script for handling player actions, like select and move a pawn
camera movement and rotation, etc.
"""

var t_camera = null
var arena = null
var curr_pawn = null
var pawns = []
var player_ui = null

var stage_control = 0

func configure(var my_camera, var my_arena, var my_ui):
	self.t_camera = my_camera
	self.arena = my_arena
	self.player_ui = my_ui
	self.pawns = self.get_children()

func _camera_rotation():
	if Input.is_action_just_pressed("cam_rotate_right"):
		self.t_camera.y_rot += 90
	if Input.is_action_just_pressed("cam_rotate_left"):
		self.t_camera.y_rot -= 90

""" DECAPRED :(
func _select_pawn_for_movement():
	self.curr_pawn = self.t_camera.select_pawn()
	if !self.curr_pawn: return
	if !self.curr_pawn.can_act(): self.curr_pawn = null
	if !(self.curr_pawn in self.pawns): self.curr_pawn = null
	if self.curr_pawn != null and self.curr_pawn.can_act():
		var t = self.curr_pawn.get_tile()
		var d = self.curr_pawn.distance
		var h = self.curr_pawn.jump_height
		self.t_camera.set_target(t)
		self.arena.mark_available_movements(t, d, h, self.pawns)

func _select_tile_for_movement():
	var t = self.t_camera.select_tile()
	if t == null: return
	if t.reachable:
		self.t_camera.set_target(t)
		self.curr_pawn.path_stack = self.arena.gen_path(t)

func ally_move_pawn():
	if Input.is_action_just_pressed("ui_accept"):
		if self.curr_pawn == null:
			self._select_pawn_for_movement()
		elif self.curr_pawn.path_stack.empty():
			self._select_tile_for_movement()
		return self.curr_pawn
"""

func _aux_select_a_pawn():
	var p = self.t_camera.select_pawn()
	if p and p in self.pawns and p.can_act():
		self.t_camera.set_target(p.get_tile())
		self.curr_pawn = p

func _act_select_a_pawn():
	"""
	Stage where the player must select a pawn for indicate 
	a command to perform. When a pawn is selected and the pawn
	is available to act this will rise up the next stage
	"""
	self.arena.reset()
	self.curr_pawn = null
	self.player_ui.update_buttons(self.curr_pawn, false)
	if Input.is_action_just_pressed("ui_accept"):
		self._aux_select_a_pawn()
		if self.curr_pawn: self.stage_control = 1

func _act_select_a_command_for_pawn():
	"""
	Stage for select a command for a pawn. At this point a valid pawn
	is selected and the tactics menu is updated in order to display
	all the available commands for my current pawn. When an command is 
	selected it will rise up the specific stage.

	- At this stage player can choose an other pawn
	- At this stage player can go back
	"""
	self.arena.reset()
	self.curr_pawn.get_tile().reachable = true
	self.player_ui.update_buttons(self.curr_pawn, true)

	if Input.is_action_just_pressed("ui_cancel"):
		self.stage_control = 0

	elif Input.is_action_just_pressed("player_move_pawn"):
		self.stage_control = 2

	elif Input.is_action_just_pressed("player_wait_pawn"):
		self.curr_pawn.wait()
		self.stage_control = 0

	elif Input.is_action_just_pressed("ui_accept"):
		self._aux_select_a_pawn()

func _act_select_a_tile_to_move():
	"""
	At this stage the player choosed to move a pawn so the the
	arena will display all the available movments and we will be
	waiting for the player to choose one of the available locations.
	Once it is done the arena will generate a path for this pawn
	and will rise up the next stage.

	- At this stage player can go back
	"""
	self.player_ui.update_buttons(self.curr_pawn, true)
	var t = self.curr_pawn.get_tile()
	var d = self.curr_pawn.distance
	var h = self.curr_pawn.jump_height
	self.arena.mark_available_movements(t, d, h, self.pawns)

	if Input.is_action_just_pressed("ui_cancel"):
		self.stage_control = 1
	elif Input.is_action_just_pressed("ui_accept"):
		var dt = self.t_camera.select_tile()
		if dt and dt.reachable:
			self.t_camera.set_target(dt)
			self.curr_pawn.path_stack = self.arena.gen_path(dt)
			self.stage_control = 3

func _act_move_selected_pawn(var delta):
	"""
	At this stage player confirmed a new location for its pawn
	so this function will be handling that movement. Once it is done
	pawn will automatically go back to stage 0 or 1 according to it's
	available actions

	- At this stage player just can see what is happing on the level
	  but has no interaction with it.
	"""
	self.player_ui.update_buttons(null, false)
	if self.curr_pawn.move(delta):
		self.curr_pawn.can_move = false
		if self.curr_pawn.can_act(): self.stage_control = 1
		else: self.stage_control = 0

func act(var delta):
	match self.stage_control:
		0: self._act_select_a_pawn()
		1: self._act_select_a_command_for_pawn()
		2: self._act_select_a_tile_to_move()
		3: self._act_move_selected_pawn(delta)

func _process(var _delta):
	self._camera_rotation()