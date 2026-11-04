@tool
extends Node


const JOINT_SIDE_LENGTH: float = 96
const JOINT_OUTLINE_WIDTH: float = 8
const RECTANGLE_WIDTH_SCALE: float = 1.0 / 2.0
const TRIANGLE_CATHETUS_SCALE: float = 1.0 / 2.5

var PLANK_SIZE = Vector2(2, 3) * JOINT_SIDE_LENGTH

const windroses = [Bozo.Windrose.N, Bozo.Windrose.NE, Bozo.Windrose.E, Bozo.Windrose.SE, Bozo.Windrose.S, Bozo.Windrose.SW, Bozo.Windrose.W, Bozo.Windrose.NW]

const PLANK_JOINT_SIZE: int = 3
const rectangles = [Bozo.Joint.SHORT_RECTANGLE, Bozo.Joint.LONG_RECTANGLE,]
