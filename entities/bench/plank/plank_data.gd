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
	var extent = Bozo.Extent.SHORT
	var type: Bozo.Joint
	var windrose: Bozo.Windrose
	var post: Bozo.Post
	
	if joints.is_empty():
		type = Bozo.Joint.RECTANGLE
		extent = Helper.get_random_key(Digest.extent_to_weignt)
		windrose = Digest.joint_to_windrose_to_anchor[type].keys().pick_random()
		#windrose = Bozo.Windrose.W
		#extent = Bozo.Extent.LONG
	else:
		if free_windroses.size() == 3 and joints.size() == 1:
			post = Bozo.Post.CORNER
			type = Helper.get_random_key(Digest.post_to_joint_to_weignt[post])
			var windrose_options = Digest.extent_to_windroses[extent]
			windrose_options = windrose_options.filter(func (a): return free_windroses.has(a))
			windrose = windrose_options.pick_random()
		else:
			windrose = free_windroses.pick_random()
			post = Digest.windrose_to_post[windrose]
			type = Helper.get_random_key(Digest.post_to_joint_to_weignt[post])
			
			if type == Bozo.Joint.RECTANGLE:
				var is_used: bool = false
				
				for windrose_neighbor in Digest.windrose_neighbors[windrose]:
					if not free_windroses.has(windrose_neighbor):
						is_used = true
						break
				
				if is_used:
					type = Bozo.Joint.TRIANGLE
	
	var joint = JointData.new(self, type, windrose, extent)
	joints.append(joint)
	windrose_to_joint[windrose] = joint
	
	var used_windroses = Digest.windrose_neighbors[windrose].duplicate()
	
	if joint.extent == Bozo.Extent.LONG:
		for windrose_neighbor in Digest.windrose_neighbors[windrose]:
			used_windroses.append_array(Digest.windrose_neighbors[windrose_neighbor])
	else:
		used_windroses.append(windrose)
	
	if joint.post == Bozo.Post.CORNER:
		used_windroses.append(Digest.windrose_to_mirror[windrose])
	
	free_windroses = free_windroses.filter(func (a): return not used_windroses.has(a))
