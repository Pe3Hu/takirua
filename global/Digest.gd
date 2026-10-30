@tool
extends Node




#region weight
var extent_to_factor = {
	Bozo.Extent.SHORT: 2, 
	Bozo.Extent.LONG: 3
}

var extent_to_weignt = {
	Bozo.Extent.SHORT: 2, 
	Bozo.Extent.LONG: 5
}

var post_to_joint_to_weignt = {
	Bozo.Post.CORNER: {
		Bozo.Joint.TRIANGLE: 2, 
		Bozo.Joint.SQUARE: 5
	},
	Bozo.Post.SIDE: {
		Bozo.Joint.TRIANGLE: 1, 
		Bozo.Joint.RECTANGLE: 2
	},
}
#endregion

#region windrose
var joint_to_windrose_to_anchor = {
	Bozo.Joint.SQUARE: {
		Bozo.Windrose.NE: Vector2(0.5, -1),
		Bozo.Windrose.SE: Vector2(0.5, 1),
		Bozo.Windrose.SW: Vector2(-0.5, 1),
		Bozo.Windrose.NW: Vector2(-0.5, -1),
	},
	Bozo.Joint.TRIANGLE: {
		Bozo.Windrose.NE: Vector2(0.5, -1),
		Bozo.Windrose.SE: Vector2(0.5, 1),
		Bozo.Windrose.SW: Vector2(-0.5, 1),
		Bozo.Windrose.NW: Vector2(-0.5, -1),
		Bozo.Windrose.N: Vector2(0, -1.5),
		Bozo.Windrose.E: Vector2(1, 0),
		Bozo.Windrose.S: Vector2(0, 1.5),
		Bozo.Windrose.W: Vector2(-1, 0),
	},
	Bozo.Joint.RECTANGLE: {
		Bozo.Windrose.N: Vector2(0, -1.5),
		Bozo.Windrose.E: Vector2(1, 0),
		Bozo.Windrose.S: Vector2(0, 1.5),
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
	Bozo.Joint.RECTANGLE: {
		Bozo.Windrose.N: 0,
		Bozo.Windrose.E: 1,
		Bozo.Windrose.S: 2,
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


var windrose_to_extents = {
	Bozo.Windrose.NE: [Bozo.Extent.SHORT],
	Bozo.Windrose.SE: [Bozo.Extent.SHORT],
	Bozo.Windrose.SW: [Bozo.Extent.SHORT],
	Bozo.Windrose.NW: [Bozo.Extent.SHORT],
	Bozo.Windrose.N: [Bozo.Extent.SHORT],
	Bozo.Windrose.E: [Bozo.Extent.SHORT, Bozo.Extent.LONG],
	Bozo.Windrose.S: [Bozo.Extent.SHORT],
	Bozo.Windrose.W: [Bozo.Extent.SHORT, Bozo.Extent.LONG],
}

var extent_to_windroses = {
	Bozo.Extent.SHORT: [Bozo.Windrose.NE, Bozo.Windrose.SE,Bozo.Windrose.SW, Bozo.Windrose.NW], 
	Bozo.Extent.LONG: [Bozo.Windrose.N, Bozo.Windrose.E,  Bozo.Windrose.S,Bozo.Windrose.W]
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
