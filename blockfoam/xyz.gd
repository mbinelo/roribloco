extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var size=0.2
var camera=null
var center=null
# Called when the node enters the scene tree for the first time.
func _ready():
	camera=get_node("../../../Camera")
	center=get_node("../../../scene/center")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		var px=camera.unproject_position(center.to_global(Vector3(size,0,0)))
		var py=camera.unproject_position(center.to_global(Vector3(0,size,0)))
		var pz=camera.unproject_position(center.to_global(Vector3(0,0,size)))
		var ori=camera.unproject_position(center.to_global(Vector3(0,0,0)))
		$Lx.points[0]=Vector2(ori)
		$Lx.points[1]=Vector2(px)
		$Ly.points[0]=Vector2(ori)
		$Ly.points[1]=Vector2(py)
		$Lz.points[0]=Vector2(ori)
		$Lz.points[1]=Vector2(pz)
		$Tx.set_global_position(px)
		$Ty.set_global_position(py)
		$Tz.set_global_position(pz)
