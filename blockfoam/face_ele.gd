extends ImmediateGeometry


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var points=[]
var matrix=[]
var selected=false
var draw_timer=[0,10000.0]

# Called when the node enters the scene tree for the first time.
func _ready():
	selected=false
	material_override=$material1.material_override
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#draw_timer[0]-=delta
	#if draw_timer[0]<=0:
	#	draw_timer[0]=draw_timer[1]
	#	clear()
	#	#if selected:
	#	if matrix==[]:
	#		draw_simple()
	#	else:
	#		draw_matrix()

func draw_simple():

	# Begin draw.
	begin(Mesh.PRIMITIVE_TRIANGLES)

	# Prepare attributes for add_vertex.
	#set_normal(Vector3(0, 0, 1))
	#set_uv(Vector2(0, 0))
	# Call last for each vertex, adds the above attributes.
	set_normal(-((points[0]-points[1]).cross((points[2]-points[1]))))
	add_vertex(points[2])
	add_vertex(points[1])
	add_vertex(points[0])
	add_vertex(points[3])
	add_vertex(points[2])
	add_vertex(points[0])
	
	#set_normal(((points[0]-points[1]).cross((points[2]-points[1]))))
	#add_vertex(points[0])
	#add_vertex(points[1])
	#add_vertex(points[2])
	#add_vertex(points[0])
	#add_vertex(points[2])
	#add_vertex(points[3])	

	# End drawing.
	end()


func draw_matrix():


	# Begin draw.
	begin(Mesh.PRIMITIVE_TRIANGLES)

	for i1 in range(matrix.size()-1):
		for i2 in range(matrix[i1].size()-1):
			var p=[]
			p.append(matrix[i1][i2])
			p.append(matrix[i1][i2+1])
			p.append(matrix[i1+1][i2+1])			
			p.append(matrix[i1+1][i2])
			set_normal(-((p[0]-p[1]).cross((p[2]-p[1]))))
			add_vertex(p[2])
			add_vertex(p[1])
			add_vertex(p[0])
			add_vertex(p[3])
			add_vertex(p[2])
			add_vertex(p[0])
	
	end()

func is_line(v):
	var l=0
	for i in v.size()-1:
		l+=v[i+1].distance_to(v[i])
	var dist=(l-v[-1].distance_to(v[0]))
	#print(dist)
	return dist<0.001
	
func set_points_edges(x1,x2,y1,y2):
	if is_line(x1) and is_line(x2) and is_line(y1) and is_line(y2):
		set_points([x1[0],x1[-1],x2[-1],x2[0]])
	else:
		matrix=[]
		for i1 in range(11):
			var line=[]
			for i2 in range(11):
				var py=y1[i1]+(y2[i1]-y1[i1])*(i2/10.0)
				var px1=x1[i2]-(x1[0]+(x1[-1]-x1[0])*(i2/10.0))
				var px2=x2[i2]-(x2[0]+(x2[-1]-x2[0])*(i2/10.0))
				line.append(py+(px1+(px2-px1)*(i1/10.0)))
				#line.append(py)
			matrix.append(line)
		clear()
		draw_matrix()
		

func set_points(plist):
	points=plist
	clear()
	draw_simple()
	

func set_selected(sel):
	if sel:
		selected=true
		material_override=$material2.material_override
	else:
		selected=false
		material_override=$material1.material_override
