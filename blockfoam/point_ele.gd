extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var camera=null

# Called when the node enters the scene tree for the first time.
func _ready():
	camera=get_node("../../../../Camera")
	set_selected(false)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$label.rect_global_position= camera.unproject_position(self.to_global(Vector3(0,0,0)))
	$label_sel.rect_global_position=$label.rect_global_position

func set_text(text):
	$label.text=text
	$label_sel.text=text
	
func set_selected(sel):
	if sel:
		$label.visible=false
		$label_sel.visible=true
	else:
		$label.visible=true
		$label_sel.visible=false
