class_name PlankData
extends Resource



var windrose_to_joint: Dictionary
var joints: Array[JointData]

var free_windroses: Array


func _init() -> void:
	init_joints()

func init_joints() -> void:
	free_windroses.append_array(Catalog.windroses)

	while not free_windroses.is_empty():
		add_joint()

func add_joint() -> void:
	if free_windroses.is_empty(): return
	var type: Bozo.Joint
	var windrose: Bozo.Windrose
	var post: Bozo.Post

	if joints.is_empty():
		# Первый джойнт — всегда прямоугольник (короткий или длинный).
		windrose = Helper.get_random_key(Digest.windrose_to_weight)
		var type_options = Digest.windrose_to_joints[windrose].filter(func (a): return a != Bozo.Joint.TRIANGLE)
		type = type_options.pick_random()
		post = Digest.windrose_to_post[windrose]
	else:
		if free_windroses.size() == 3 and joints.size() == 1:
			post = Bozo.Post.CORNER
			type = Bozo.Joint.TRIANGLE
			#type = Helper.get_random_key(Digest.post_to_joint_to_weignt[post])
			var windrose_options: Array = Digest.joint_to_windroses[type]
			windrose_options = windrose_options.filter(func (a): return free_windroses.has(a))
			windrose = windrose_options.pick_random()
		else:
			windrose = free_windroses.pick_random()
			post = Digest.windrose_to_post[windrose]
			var valid_weights := {}
			
			for _t in Digest.windrose_to_joints[windrose]:
				valid_weights[_t] = Digest.post_to_joint_to_weignt[post][_t]
			
			type = Helper.get_random_key(valid_weights)

			if type == Bozo.Joint.SHORT_RECTANGLE or type == Bozo.Joint.LONG_RECTANGLE:
				var is_used: bool = false

				for windrose_neighbor in Digest.windrose_neighbors[windrose]:
					if not free_windroses.has(windrose_neighbor):
						is_used = true
						break

				if is_used:
					type = Bozo.Joint.TRIANGLE

	var joint = JointData.new(self, type, windrose)
	joints.append(joint)
	windrose_to_joint[windrose] = joint

	var used_windroses = Digest.windrose_neighbors[windrose].duplicate()

	if joint.type == Bozo.Joint.LONG_RECTANGLE:
		for windrose_neighbor in Digest.windrose_neighbors[windrose]:
			used_windroses.append_array(Digest.windrose_neighbors[windrose_neighbor])
	else:
		used_windroses.append(windrose)

	if joint.post == Bozo.Post.CORNER:
		used_windroses.append(Digest.windrose_to_mirror[windrose])

	free_windroses = free_windroses.filter(func (a): return not used_windroses.has(a))
