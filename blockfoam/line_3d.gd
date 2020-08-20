extends Line2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var points_3d=[]
var camera=null
var center=null
var curve3d=null

# Called when the node enters the scene tree for the first time.
func _ready():
	camera=get_node("../../../../Camera")
	center=get_node("../..")

func set_points_3d_vec(vec):
	points_3d=vec

func set_points_3d(p3d1,p3d2):
	points_3d.clear()
	points_3d.append(p3d1)
	points_3d.append(p3d2)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for i in range(points.size()):		
		points[i]=self.to_local(camera.unproject_position(center.to_global(points_3d[min(i,points_3d.size()-1)])))
	
		
func has_points(p3d1,p3d2):
	return (points_3d[0]==p3d1 or points_3d[1]==p3d1) and (points_3d[0]==p3d2 or points_3d[1]==p3d2)

func set_block_selected(sel):
	if sel:
		default_color=Color(1.0,0.3,0.3,0.6)
	else:		
		default_color=Color(1.0,1.0,1.0,0.6)
