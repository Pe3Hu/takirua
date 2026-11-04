@tool
extends Node




#region weight
var joint_to_factor = {
	Bozo.Joint.SHORT_RECTANGLE: 2, 
	Bozo.Joint.LONG_RECTANGLE: 3
}

var joint_to_weight = {
	Bozo.Joint.SHORT_RECTANGLE: 2, 
	Bozo.Joint.LONG_RECTANGLE: 5
}

var post_to_joint_to_weignt = {
	Bozo.Post.CORNER: {
		Bozo.Joint.TRIANGLE: 2, 
		Bozo.Joint.SHORT_RECTANGLE: 1,
	},
	Bozo.Post.SIDE: {
		Bozo.Joint.TRIANGLE: 1, 
		Bozo.Joint.SHORT_RECTANGLE: 1,
		Bozo.Joint.LONG_RECTANGLE: 1,
	},
}

var windrose_to_weight = {
	Bozo.Windrose.N: 6,
	Bozo.Windrose.E: 4,
	Bozo.Windrose.S: 5,
	Bozo.Windrose.W: 3,
}
#endregion

#region windrose
var joint_to_windrose_to_anchor = {
	Bozo.Joint.TRIANGLE: {
		Bozo.Windrose.NE: Vector2(1.0 - Catalog.TRIANGLE_CATHETUS_SCALE, -1.5 + Catalog.TRIANGLE_CATHETUS_SCALE),
		Bozo.Windrose.SE: Vector2(1.0 - Catalog.TRIANGLE_CATHETUS_SCALE,  1.5 - Catalog.TRIANGLE_CATHETUS_SCALE),
		Bozo.Windrose.SW: Vector2(-1.0 + Catalog.TRIANGLE_CATHETUS_SCALE, 1.5 - Catalog.TRIANGLE_CATHETUS_SCALE),
		Bozo.Windrose.NW: Vector2(-1.0 + Catalog.TRIANGLE_CATHETUS_SCALE, -1.5 + Catalog.TRIANGLE_CATHETUS_SCALE),
		Bozo.Windrose.N: Vector2(0, -1.5),
		Bozo.Windrose.E: Vector2(1, 0),
		Bozo.Windrose.S: Vector2(0, 1.5),
		Bozo.Windrose.W: Vector2(-1, 0),
	},
	Bozo.Joint.SHORT_RECTANGLE: {
		Bozo.Windrose.N: Vector2(0, -1.5),
		Bozo.Windrose.S: Vector2(0, 1.5),
		Bozo.Windrose.E: Vector2(1, 0),
		Bozo.Windrose.W: Vector2(-1, 0),
		Bozo.Windrose.NE: Vector2(1, -0.5),   
		Bozo.Windrose.SE: Vector2(1, 0.5),    
		Bozo.Windrose.NW: Vector2(-1, -0.5),  
		Bozo.Windrose.SW: Vector2(-1, 0.5),   
	},
	Bozo.Joint.LONG_RECTANGLE: {
		Bozo.Windrose.E: Vector2(1, 0),
		Bozo.Windrose.W: Vector2(-1, 0),
	}
}

var joint_to_windrose_to_rotation = {
	Bozo.Joint.TRIANGLE: {
		Bozo.Windrose.NE: 2,
		Bozo.Windrose.SE: 3,
		Bozo.Windrose.SW: 0,
		Bozo.Windrose.NW: 1,
		Bozo.Windrose.N: 3,
		Bozo.Windrose.E: 0,
		Bozo.Windrose.S: 1,
		Bozo.Windrose.W: 2,
	},
	Bozo.Joint.SHORT_RECTANGLE: {
		Bozo.Windrose.N: 0,
		Bozo.Windrose.E: 1,
		Bozo.Windrose.S: 2,
		Bozo.Windrose.W: 3,
		Bozo.Windrose.NE: 1,
		Bozo.Windrose.SE: 1,
		Bozo.Windrose.SW: 3,
		Bozo.Windrose.NW: 3,
	},
	Bozo.Joint.LONG_RECTANGLE: {
		Bozo.Windrose.E: 1,
		Bozo.Windrose.W: 3,
	}
}

var windrose_to_post = {
	Bozo.Windrose.NE: Bozo.Post.CORNER,
	Bozo.Windrose.SE: Bozo.Post.CORNER,
	Bozo.Windrose.SW: Bozo.Post.CORNER,
	Bozo.Windrose.NW: Bozo.Post.CORNER,
	Bozo.Windrose.N: Bozo.Post.SIDE,
	Bozo.Windrose.E: Bozo.Post.SIDE,
	Bozo.Windrose.S: Bozo.Post.SIDE,
	Bozo.Windrose.W: Bozo.Post.SIDE,
}

var post_to_windroses = {
	Bozo.Post.CORNER: [Bozo.Windrose.NE, Bozo.Windrose.SE,Bozo.Windrose.SW, Bozo.Windrose.NW], 
	Bozo.Post.SIDE: [Bozo.Windrose.N, Bozo.Windrose.E, Bozo.Windrose.S,Bozo.Windrose.W], 
}

var windrose_to_joints = {
	Bozo.Windrose.NE: [Bozo.Joint.TRIANGLE, Bozo.Joint.SHORT_RECTANGLE],
	Bozo.Windrose.SE: [Bozo.Joint.TRIANGLE, Bozo.Joint.SHORT_RECTANGLE],
	Bozo.Windrose.SW: [Bozo.Joint.TRIANGLE, Bozo.Joint.SHORT_RECTANGLE],
	Bozo.Windrose.NW: [Bozo.Joint.TRIANGLE, Bozo.Joint.SHORT_RECTANGLE],
	Bozo.Windrose.N: [Bozo.Joint.TRIANGLE, Bozo.Joint.SHORT_RECTANGLE],
	Bozo.Windrose.E: [Bozo.Joint.TRIANGLE, Bozo.Joint.SHORT_RECTANGLE, Bozo.Joint.LONG_RECTANGLE],
	Bozo.Windrose.S: [Bozo.Joint.TRIANGLE, Bozo.Joint.SHORT_RECTANGLE],
	Bozo.Windrose.W: [Bozo.Joint.TRIANGLE, Bozo.Joint.SHORT_RECTANGLE, Bozo.Joint.LONG_RECTANGLE],
}

var joint_to_windroses = {
	Bozo.Joint.TRIANGLE: [Bozo.Windrose.N, Bozo.Windrose.E, Bozo.Windrose.S,Bozo.Windrose.W, Bozo.Windrose.NE, Bozo.Windrose.SE,Bozo.Windrose.SW, Bozo.Windrose.NW], 
	Bozo.Joint.SHORT_RECTANGLE: [Bozo.Windrose.E, Bozo.Windrose.W, Bozo.Windrose.N, Bozo.Windrose.S, Bozo.Windrose.NE, Bozo.Windrose.SE,Bozo.Windrose.SW, Bozo.Windrose.NW], 
	Bozo.Joint.LONG_RECTANGLE: [Bozo.Windrose.E, Bozo.Windrose.W]
}

const windrose_neighbors = {
	Bozo.Windrose.N: [Bozo.Windrose.NW, Bozo.Windrose.NE],
	Bozo.Windrose.NE: [Bozo.Windrose.N, Bozo.Windrose.E],
	Bozo.Windrose.E: [Bozo.Windrose.NE, Bozo.Windrose.SE],
	Bozo.Windrose.SE: [Bozo.Windrose.E, Bozo.Windrose.S],
	Bozo.Windrose.S: [Bozo.Windrose.SE, Bozo.Windrose.SW],
	Bozo.Windrose.SW: [Bozo.Windrose.S, Bozo.Windrose.W],
	Bozo.Windrose.W: [Bozo.Windrose.SW, Bozo.Windrose.NW],
	Bozo.Windrose.NW: [Bozo.Windrose.W, Bozo.Windrose.N],
}

const windrose_to_mirror = {
	Bozo.Windrose.NE: Bozo.Windrose.NW,
	Bozo.Windrose.NW: Bozo.Windrose.NE,
	Bozo.Windrose.SW: Bozo.Windrose.SE,
	Bozo.Windrose.SE: Bozo.Windrose.SW,
}
#endregion
