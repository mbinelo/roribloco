extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var points=[]
var points_ele=[]
var blocks=[]# [points],[cells],[grading],[externalfaces],zone,gradingtype
var blocks_lines=[]
var blocks_edges=[]
var edges_lines=[]
var faces=[]
var unused_faces=[]
var boundaries=[]
var edges=[] #type,p1,p2,[pointsVec3]
var faces_ele=[]
var point_idx=0
var selected_block=-1
var selected_boundary=-1
var selected_point=-1
var selected_edge=-1
var selected_epoint=-1
var item_edit=null
var tree_points=null
var pos_window=Vector2(320+30,32)
var point_ele_comp=preload("res://point_ele.tscn")
var line3d_comp=preload("res://line_3d.tscn")
var face_ele_comp=preload("res://face_ele.tscn")
var last_position = Vector2()
var mouse_position = Vector2()
var pressed = false
var tree_collapsed=[false,false,false,false,false,false]
var dbase=100000
var edgebase=1000
var point_edit_base=0
var point_del_base=dbase*1
var block_del_base=dbase*2
var block_edit_base=dbase*3
var block_cell_edit_base=dbase*4
var block_grading_edit_base=dbase*5
var boundary_del_base=dbase*6
var boundary_name_edit_base=dbase*7
var boundary_type_edit_base=dbase*8
var boundary_faces_edit_base=dbase*9
var block_zone_edit_base=dbase*10
var edge_del_base=dbase*11
var edge_edit_base=dbase*12
var edge_point_del_base=dbase*13
var edge_type=""
var edit_ref=null
var func_remove_faces=false



# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_window_maximized(true)
	$panel_edit_point.visible=false
	update_tree()
	init_menu()
	print(float2str(12.1234567891011121314151617181920))
	print(float2str(12.12))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#$scene.rotate(Vector3(0,1,0),1*delta)
	#$scene.rotate(Vector3(1,0,0),1.5*delta)
	#$scene.rotate(Vector3(0,0,1),0.7*delta)
	#$hud/Label.rect_global_position= $Camera.unproject_position($scene/center/CSGBox.to_global(Vector3(0,0,0)))
func _unhandled_input(event):
	if event is InputEventMouseButton:
		pressed = event.is_pressed()
		if pressed:
			last_position = event.position
	elif event is InputEventMouse and pressed:
		var delta = event.position - last_position
		last_position = event.position
		if Input.is_action_pressed("mouse_bleft"):
			$scene.rotate_z(delta.x * 0.01)
			$scene.rotate_x(delta.y * 0.01)
		if Input.is_action_pressed("mouse_bright"):		
			$scene.global_translate(Vector3(delta.x * 0.001*$Camera.size,0,-delta.y * 0.001*$Camera.size))

		
	if event is InputEventMouseButton:
		if event.is_pressed():
			# zoom in
			if event.button_index == BUTTON_WHEEL_UP:
				$Camera.size+=$Camera.size*0.1
				# call the zoom function
			# zoom out
			if event.button_index == BUTTON_WHEEL_DOWN:
				$Camera.size-=$Camera.size*0.1
				# call the zoom function		

		
func _input(event):
	if event is InputEventMouse:
		mouse_position = event.position


func float2str(v):
	var res="%.20f" % v	
	var continua=true
	while continua:
		var s=res.length()
		res=res.trim_suffix("0")
		if s==res.length():
			continua=false
			if res=="":
				res=0 
				res=res.trim_sufix(".")
	return res

func init_menu():
	
	$menu_actions.get_popup().clear()
	$menu_actions.get_popup(). add_item("create main blocks", 0)
	$menu_actions.get_popup(). add_item("create boundary", 1)
	$menu_actions.get_popup(). add_item("set cells", 2)
	$menu_actions.get_popup(). add_item("collapse point", 3)
	$menu_actions.get_popup(). add_item("create point", 10)
	$menu_actions.get_popup(). add_item("create block", 11)
	$menu_actions.get_popup(). add_item("remove blocks by box selection", 4)
	$menu_actions.get_popup(). add_item("create arc by circle center", 5)
	$menu_actions.get_popup(). add_item("create arc by arc point", 6)
	$menu_actions.get_popup(). add_item("create spline", 7)
	$menu_actions.get_popup(). add_item("create polyLine", 8)
	#$menu_actions.get_popup(). add_item("create BSpline", 9)
	$menu_actions.get_popup(). add_item("translate points", 12)	
	$menu_actions.get_popup(). add_item("rotate points", 13)
	$menu_actions.get_popup(). add_item("scale points", 14)	
	$menu_actions.get_popup(). add_item("clear all", 15)	
	$menu_actions.get_popup().connect("id_pressed", self, "_on_menu_actions_item_pressed")
	$menu_file.get_popup().connect("id_pressed", self, "_on_menu_file_item_pressed")
	$menu_view.get_popup().connect("id_pressed", self, "_on_menu_view_item_pressed")
func is_point_used(i):
	for b in blocks:
		if b[0].has(i):
			return true
	return false
	
func update_tree():
	var tree = $Tree
	var vroot=tree.get_root()
	if vroot!=null:
		var iz=0
		var it=vroot.get_children()
		while it!=null:
			tree_collapsed[iz]=it.collapsed
			iz+=1
			it=it.get_next()
	print("tree "+str(tree.get_child_count()))
	tree.select_mode=Tree.SELECT_ROW
	tree.clear()
	tree.columns=2
	tree.set_column_min_width(0,30)
	tree.set_column_min_width(1,50)
	tree.set_hide_root(false)
	var root = tree.create_item()
	root.set_text(0, "geometry")
	tree_points = tree.create_item(root)
	tree_points.set_text(0, "points")
	tree_points.set_selectable(1,false)

	for i in range(points.size()):
		var p = $Tree.create_item(tree_points)
		p.set_text(0, "p_"+str(i))
		p.set_text(1, "["+str(points[i].x)+" "+str(points[i].y)+" "+str(points[i].z)+"]")
		if is_point_used(i)==false:
			p.add_button(1,$del10.texture,i+point_del_base,false,"remove")	
		p.add_button(1,$lapis16.texture,i+point_edit_base,false,"edit")	
		p.set_custom_bg_color(1,Color(0.0,0.1,0.0))		

	var item = tree.create_item(root)
	item.set_text(0, "blocks")
	
	for i in range(blocks.size()):
		var p = $Tree.create_item(item)
		p.set_text(0, "b_"+str(i))
		p.add_button(0,$del10.texture,i+block_del_base,false,"remove")
		var p1 = $Tree.create_item(p)
		p1.set_text(0, "points")
		p1.set_text(1, str(blocks[i][0]))
		p1.add_button(1,$lapis16.texture,i+block_edit_base,false,"edit")	
		p1.set_custom_bg_color(1,Color(0.0,0.1,0.0))		
		var p2 = $Tree.create_item(p)
		p2.set_text(0, "cells")
		p2.set_text(1, str(blocks[i][1]))
		p2.add_button(1,$lapis16.texture,i+block_cell_edit_base,false,"edit")	
		p2.set_custom_bg_color(1,Color(0.0,0.1,0.0))		
		var p3 = $Tree.create_item(p)
		p3.set_text(0, blocks[i][5])
		p3.set_text(1, str(blocks[i][2]))
		p3.add_button(1,$lapis16.texture,i+block_grading_edit_base,false,"edit")	
		p3.set_custom_bg_color(1,Color(0.0,0.1,0.0))		
		var p4 = $Tree.create_item(p)
		p4.set_text(0, "zone")
		p4.set_text(1, str(blocks[i][4]))
		p4.add_button(1,$lapis16.texture,i+block_zone_edit_base,false,"edit")	
		p4.set_custom_bg_color(1,Color(0.0,0.1,0.0))			
		
	item = tree.create_item(root)
	item.set_text(0, "faces")
	for i in range(faces.size()):
		var p = $Tree.create_item(item)
		p.set_text(0, "f_"+str(i))
		p.set_text(1, str(faces[i][0]))
		p.set_custom_bg_color(1,Color(0.0,0.1,0.0))		
			
	item = tree.create_item(root)
	item.set_text(0, "edges")	
	for i in range(edges.size()):
		var p = $Tree.create_item(item)
		p.set_text(0, "e_"+str(i))
		p.set_text(1, edges[i][0]+" "+str(edges[i][1])+":"+str(edges[i][2]))
		p.add_button(1,$del10.texture,i+edge_del_base,false,"remove")	
		if edges[i][0]!="arc":
			p.add_button(1,$lapis16.texture,i+edge_edit_base,false,"edit")	
		p.set_custom_bg_color(1,Color(0.0,0.1,0.0))	
		if edges[i][0]=="arc":
			var p1 = $Tree.create_item(p)
			p1.set_text(0, "ep_0")
			p1.set_text(1,"["+str(edges[i][3][0].x)+" "+str(edges[i][3][0].y)+" "+str(edges[i][3][0].z)+"]")
			p1.set_custom_bg_color(1,Color(0.0,0.1,0.0))								
		else:
			for i2 in range(edges[i][3].size()):
				var p1 = $Tree.create_item(p)
				p1.set_text(0, "ep_"+str(i2))
				p1.set_text(1,"["+str(edges[i][3][i2].x)+" "+str(edges[i][3][i2].y)+" "+str(edges[i][3][i2].z)+"]")
				p1.set_custom_bg_color(1,Color(0.0,0.1,0.0))			
				p1.add_button(1,$del10.texture,i*edgebase+i2+edge_point_del_base,false,"remove")						
				
	var itembound = tree.create_item(root)
	itembound.set_text(0, "boudaries")	
	
	for i in range(boundaries.size()):
		var p = $Tree.create_item(itembound)
		p.set_text(0, "bc_"+str(i))
		p.add_button(0,$del10.texture,i+boundary_del_base,false,"remove")
		var p1 = $Tree.create_item(p)
		p1.set_text(0, "name")
		p1.set_text(1, str(boundaries[i][1]))
		p1.add_button(1,$lapis16.texture,i+boundary_name_edit_base,false,"edit")	
		p1.set_custom_bg_color(1,Color(0.0,0.1,0.0))		
		var p2 = $Tree.create_item(p)
		p2.set_text(0, "type")
		p2.set_text(1, str(boundaries[i][2]))
		p2.add_button(1,$lapis16.texture,i+boundary_type_edit_base,false,"edit")	
		p2.set_custom_bg_color(1,Color(0.0,0.1,0.0))		
		var p3 = $Tree.create_item(p)
		p3.set_text(0, "faces")
		p3.set_text(1, str(boundaries[i][0]))
		p3.add_button(1,$lapis16.texture,i+boundary_faces_edit_base,false,"edit")	
		p3.set_custom_bg_color(1,Color(0.0,0.1,0.0))	
	
	update_unused_faces()
	item = tree.create_item(itembound)
	item.set_text(0, "unused faces")	
	for i in range(unused_faces.size()):
		var p = $Tree.create_item(item)
		p.set_text(0, "f_"+str(unused_faces[i]))
	
	$Tree.hide_root=true
	vroot=tree.get_root()
	var iz=0
	var it=vroot.get_children()
	while it!=null:
		it.collapsed=tree_collapsed[iz]
		iz+=1
		it=it.get_next()

func clear_points():
	points.clear()
	for ch in $scene/center/points.get_children():
		ch.queue_free()

func clear_blocks():
	blocks.clear()
	for l3d in $scene/center/b_lines.get_children():
		l3d.queue_free()
		
func append_point(pos):
	points.append(pos)
	
func append_face(plist):
	var cont=0
	for i2 in range(blocks.size()):
		if block_has_points(blocks[i2],plist)==true:
			cont+=1
	if cont==1:
		faces.append([plist])
		return true
	else:
		return false
	
	
	
func verify_edge(p1,p2):
	for i in range(blocks_edges.size()):
		for i2	in range(blocks_edges[i].size()):
			if blocks_edges[i][i2][0]==p1 and blocks_edges[i][i2][1]==p2:
				return [p1,p2]
			if blocks_edges[i][i2][0]==p2 and blocks_edges[i][i2][1]==p1:
				return [p2,p1]
	return []

func append_edge_points(e_type,p1,p2):
	var ps=verify_edge(p1,p2)
	if ps.size()==2:
		p1=ps[0]
		p2=ps[1]		
		edges.append([e_type,p1,p2,[],[]])##type,p1,p2,[pointsVec3]
	else:
		$dialogInvalidEdge.popup_centered()

		
func append_edge_arc_center(p1,p2,center):
	var ps=verify_edge(p1,p2)
	if ps.size()==2:
		p1=ps[0]
		p2=ps[1]
		var v3=calc_circle_point(points[p1],points[p2],center,0.5)
		edges.append(["arc",p1,p2,[v3,center],[]])##type,p1,p2,[pointsVec3]
	else:
		$dialogInvalidEdge.popup_centered()

func append_edge_arc_point(p1,p2,v3):
	var ps=verify_edge(p1,p2)
	if ps.size()==2:
		p1=ps[0]
		p2=ps[1]	
		var center=calc_circle_center(points[p1],points[p2],v3)
		edges.append(["arc",p1,p2,[v3,center],[]])##type,p1,p2,[pointsVec3]
	else:
		$dialogInvalidEdge.popup_centered()


func append_block(p_list,cells,grading,zone,grading_type):
	blocks.append([p_list,cells,grading,[false,false,false,false,false,false],zone,grading_type])

	

func create_master_block(p_ini,p_fim,cut_x,cut_y,cut_z):
	clear_points()
	var vp=[]
	var pcont=0
	var vecx=[p_ini.x]
	for c in cut_x:
		vecx.append(c)
	vecx.append(p_fim.x)
	var vecy=[p_ini.y]
	for c in cut_y:
		vecy.append(c)
	vecy.append(p_fim.y)
	var vecz=[p_ini.z]
	for c in cut_z:
		vecz.append(c)
	vecz.append(p_fim.z)
	
	for ix in range(vecx.size()):
		vp.append([])
		for iy in range(vecy.size()):
			vp[ix].append([])
			for iz in range(vecz.size()):
				var p=Vector3(vecx[ix],vecy[iy],vecz[iz])
				vp[ix][iy].append(pcont)
				append_point(p)
				pcont+=1
	clear_blocks()
	for ix in range(vecx.size()-1):
		for iy in range(vecy.size()-1):
			for iz in range(vecz.size()-1):
				append_block([vp[ix][iy][iz],vp[ix+1][iy][iz],vp[ix+1][iy+1][iz],vp[ix][iy+1][iz],vp[ix][iy][iz+1],vp[ix+1][iy][iz+1],vp[ix+1][iy+1][iz+1],vp[ix][iy+1][iz+1]],[1,1,1],[1,1,1],"","simpleGrading")
	update_faces()
	update_tree()
	

func append_boundary(bname,btype):
	boundaries.append([[],bname,btype])

func get_p_min():
	var pr = Vector3(9999999,9999999,9999999)
	for p in points:
		pr.x=min(pr.x,p.x)
		pr.y=min(pr.x,p.y)
		pr.z=min(pr.x,p.z)
	return pr

func get_p_max():
	var pr = Vector3(-9999999,-9999999,-9999999)
	for p in points:
		pr.x=max(pr.x,p.x)
		pr.y=max(pr.x,p.y)
		pr.z=max(pr.x,p.z)
	return pr
			
func update_faces():
	faces=[]
	for i in range(blocks.size()):
		blocks[i][3][0]=append_face([blocks[i][0][0],blocks[i][0][3],blocks[i][0][2],blocks[i][0][1]])
		blocks[i][3][1]=append_face([blocks[i][0][4],blocks[i][0][5],blocks[i][0][6],blocks[i][0][7]])
		blocks[i][3][2]=append_face([blocks[i][0][0],blocks[i][0][1],blocks[i][0][5],blocks[i][0][4]])
		blocks[i][3][3]=append_face([blocks[i][0][3],blocks[i][0][7],blocks[i][0][6],blocks[i][0][2]])
		blocks[i][3][4]=append_face([blocks[i][0][4],blocks[i][0][7],blocks[i][0][3],blocks[i][0][0]])
		blocks[i][3][5]=append_face([blocks[i][0][1],blocks[i][0][2],blocks[i][0][6],blocks[i][0][5]])
	update_unused_faces()
		
func update_unused_faces():
	unused_faces=[]
	for i in range(faces.size()):
		var h=false
		for b in boundaries:
			if b[0].has(i):
				h=true
		if h==false:
			unused_faces.append(i)	

func unselect_all_lines():
	for i1 in range(blocks_lines.size()):
		for l in blocks_lines[i1]:
			l.set_block_selected(false)

func unselect_all_points():
	for ele in $scene/center/points.get_children():
		ele.set_selected(false)
				
func select_block(i,unselect=true):
	if unselect:
		unselect_all_lines()
		unselect_all_faces()			
	for l in blocks_lines[i]:
		l.set_block_selected(true)

	for i1 in range(points.size()):
		if blocks[i][0].has(i1):
			points_ele[i1].set_selected(true)
		else:
			if unselect:
				points_ele[i1].set_selected(false)
			
func select_point(i):
	unselect_all_lines()
	unselect_all_faces()			
	for i1 in range(points.size()):
		if i==i1:
			points_ele[i1].set_selected(true)
		else:
			points_ele[i1].set_selected(false)			
	
func unselect_all_faces():
	for i1 in range(faces.size()):
		faces_ele[i1].set_selected(false)			
		
func select_face(i):
	unselect_all_lines()
	unselect_all_faces()		
	faces_ele[i].set_selected(true)

	for i1 in range(points.size()):
		if faces[i][0].has(i1):
			points_ele[i1].set_selected(true)
		else:
			points_ele[i1].set_selected(false)
			
	for i1 in range(blocks_lines.size()):
		for l in blocks_lines[i1]:
			if l.has_points(points[faces[i][0][0]],points[faces[i][0][1]])\
			or l.has_points(points[faces[i][0][1]],points[faces[i][0][2]])\
			or l.has_points(points[faces[i][0][2]],points[faces[i][0][3]])\
			or l.has_points(points[faces[i][0][3]],points[faces[i][0][0]]):
				l.set_block_selected(true)			

func select_edge(i):
	if i>=0:
		unselect_all_lines()
		unselect_all_faces()
		unselect_all_points()
		edges_lines[i].set_block_selected(true)
		points_ele[edges[i][1]].set_selected(true)
		points_ele[edges[i][2]].set_selected(true)
			
					
			
func select_boundary(b):
	for i1 in range(faces.size()):
		faces_ele[i1].set_selected(false)
	for i1 in range(points_ele.size()):
		points_ele[i1].set_selected(false)
	for i in boundaries[b][0]:
		faces_ele[i].set_selected(true)		
		for i1 in range(points.size()):
			if faces[i][0].has(i1):
				points_ele[i1].set_selected(true)
		
	
		
func block_has_points(block,plist):
	var res=true
	for p in plist:
		if block[0].has(p)==false:
			res=false
	return res
	
func update_geometry():
	points_ele=[]
	var pmin=Vector3(9999999,99999999,99999999)
	var pmax=Vector3(-9999999,-9999999,-9999999)
	for ch in $scene/center/points.get_children():
		ch.queue_free()			
	for i in range(points.size()):
		var point_ele=point_ele_comp.instance()
		point_ele.set_text(str(i))
		point_ele.translation=points[i]
		points_ele.append(point_ele)
		$scene/center/points.add_child(point_ele)
		pmin.x=min(pmin.x,points[i].x)
		pmin.y=min(pmin.y,points[i].y)
		pmin.z=min(pmin.z,points[i].z)
		pmax.x=max(pmax.x,points[i].x)
		pmax.y=max(pmax.y,points[i].y)
		pmax.z=max(pmax.z,points[i].z)
			
	$scene/center.translation=-(pmin+pmax)/2
	for l3d in $scene/center/b_lines.get_children():
		l3d.queue_free()	
	blocks_lines=[]
	blocks_edges=[]
	edges_lines=[]
	for i in range(edges.size()):
		edges_lines.append(null)
	for i in range(blocks.size()):
		var p_list=blocks[i][0]	
		blocks_lines.append([])
		blocks_edges.append([])
		#append_line(i,
		append_line(i,p_list[0],p_list[1])
		blocks_edges[i].append([p_list[0],p_list[1]])
		append_line(i,p_list[1],p_list[2])
		blocks_edges[i].append([p_list[1],p_list[2]])
		append_line(i,p_list[2],p_list[3])
		blocks_edges[i].append([p_list[2],p_list[3]])
		append_line(i,p_list[3],p_list[0])
		blocks_edges[i].append([p_list[3],p_list[0]])
		append_line(i,p_list[4],p_list[5])
		blocks_edges[i].append([p_list[4],p_list[5]])
		append_line(i,p_list[5],p_list[6])
		blocks_edges[i].append([p_list[5],p_list[6]])
		append_line(i,p_list[6],p_list[7])
		blocks_edges[i].append([p_list[6],p_list[7]])
		append_line(i,p_list[7],p_list[4])
		blocks_edges[i].append([p_list[7],p_list[4]])
		append_line(i,p_list[0],p_list[4])
		blocks_edges[i].append([p_list[0],p_list[4]])
		append_line(i,p_list[1],p_list[5])
		blocks_edges[i].append([p_list[1],p_list[5]])
		append_line(i,p_list[2],p_list[6])
		blocks_edges[i].append([p_list[2],p_list[6]])
		append_line(i,p_list[3],p_list[7])
		blocks_edges[i].append([p_list[3],p_list[7]])

		var vecs=[]
		var vquants=[]
		var vecfaces=[]
		var vecgrad=[]
		#blocks[i][3][0]=append_face([blocks[i][0][0],blocks[i][0][3],blocks[i][0][2],blocks[i][0][1]])
		vecs.append([points[p_list[0]],points[p_list[1]],points[p_list[3]],points[p_list[2]]])
		vquants.append(blocks[i][1][0])
		vecgrad.append(blocks[i][2][0])
		vecfaces.append(0)
		vecs.append([points[p_list[0]],points[p_list[3]],points[p_list[1]],points[p_list[2]]])
		vquants.append(blocks[i][1][1])
		vecgrad.append(blocks[i][2][1])
		vecfaces.append(0)

		#blocks[i][3][1]=append_face([blocks[i][0][4],blocks[i][0][5],blocks[i][0][6],blocks[i][0][7]])
		vecs.append([points[p_list[4]],points[p_list[5]],points[p_list[7]],points[p_list[6]]])
		vquants.append(blocks[i][1][0])
		vecgrad.append(blocks[i][2][0])
		vecfaces.append(1)
		vecs.append([points[p_list[4]],points[p_list[7]],points[p_list[5]],points[p_list[6]]])
		vquants.append(blocks[i][1][1])
		vecgrad.append(blocks[i][2][1])
		vecfaces.append(1)

		#blocks[i][3][2]=append_face([blocks[i][0][0],blocks[i][0][1],blocks[i][0][5],blocks[i][0][4]])
		vecs.append([points[p_list[0]],points[p_list[1]],points[p_list[4]],points[p_list[5]]])
		vquants.append(blocks[i][1][0])
		vecgrad.append(blocks[i][2][0])
		vecfaces.append(2)
		vecs.append([points[p_list[0]],points[p_list[4]],points[p_list[1]],points[p_list[5]]])
		vquants.append(blocks[i][1][2])
		vecgrad.append(blocks[i][2][2])
		vecfaces.append(2)

		#blocks[i][3][3]=append_face([blocks[i][0][3],blocks[i][0][7],blocks[i][0][6],blocks[i][0][2]])
		vecs.append([points[p_list[3]],points[p_list[2]],points[p_list[7]],points[p_list[6]]])
		vquants.append(blocks[i][1][0])
		vecgrad.append(blocks[i][2][0])
		vecfaces.append(3)
		vecs.append([points[p_list[3]],points[p_list[7]],points[p_list[2]],points[p_list[6]]])
		vquants.append(blocks[i][1][2])
		vecgrad.append(blocks[i][2][2])
		vecfaces.append(3)

		#blocks[i][3][4]=append_face([blocks[i][0][4],blocks[i][0][7],blocks[i][0][3],blocks[i][0][0]])
		vecs.append([points[p_list[0]],points[p_list[3]],points[p_list[4]],points[p_list[7]]])
		vquants.append(blocks[i][1][1])
		vecgrad.append(blocks[i][2][1])
		vecfaces.append(4)
		vecs.append([points[p_list[0]],points[p_list[4]],points[p_list[3]],points[p_list[7]]])
		vquants.append(blocks[i][1][2])
		vecgrad.append(blocks[i][2][2])
		vecfaces.append(4)

		#blocks[i][3][5]=append_face([blocks[i][0][1],blocks[i][0][2],blocks[i][0][6],blocks[i][0][5]])
		vecs.append([points[p_list[1]],points[p_list[2]],points[p_list[5]],points[p_list[6]]])
		vquants.append(blocks[i][1][1])
		vecgrad.append(blocks[i][2][1])
		vecfaces.append(5)
		vecs.append([points[p_list[1]],points[p_list[5]],points[p_list[2]],points[p_list[6]]])
		vquants.append(blocks[i][1][2])
		vecgrad.append(blocks[i][2][2])
		vecfaces.append(5)

		for iv in range(vecs.size()):
			if blocks[i][3][vecfaces[iv]]==true:
				var xq=vquants[iv]
				var R=vecgrad[iv]
				var d1=0.0;
				var d2=0.0;
				for i2 in range(xq-1.0):				
					var vp1=vecs[iv][0]
					var vp2=vecs[iv][1]				
					var L=vp2.distance_to(vp1)/xq
					var a=(R*L-L)/(1.0+R)					
					d1+=(L-a)+(float(i2)/(xq-1.0))*(a*2)						
					var p1=vp1+(vp2-vp1).normalized()*d1	
					var p1arc=calc_point_edge_vec3(vp1,vp2,p1)
					if p1arc!=null:
						p1=p1arc
						print(p1)
					vp1=vecs[iv][2]
					vp2=vecs[iv][3]
					L=vp2.distance_to(vp1)/xq
					a=(R*L-L)/(1.0+R)					
					d2+=(L-a)+(float(i2)/(xq-1.0))*(a*2)											
					var p2=vp1+(vp2-vp1).normalized()*d2
					var p2arc=calc_point_edge_vec3(vp1,vp2,p2)
					if p2arc!=null:
						p2=p2arc
						print(p2)
					var line3d=line3d_comp.instance()
					line3d.set_points_3d(p1,(p2-p1)*0.1+p1)
					line3d.default_color.a=0.25#=Color(0.0,1.0,0.0,1.0)
					$scene/center/b_lines.add_child(line3d)
					line3d=line3d_comp.instance()
					line3d.set_points_3d(p2,(p1-p2)*0.1+p2)
					line3d.default_color.a=0.25#=Color(0.0,1.0,0.0,1.0)
					$scene/center/b_lines.add_child(line3d)
				
		
				
		
	for ch in $scene/center/faces.get_children():
		ch.queue_free()	
	faces_ele=[]	
	for i in range(faces.size()):
		var face_ele=face_ele_comp.instance()
		var vecx1=[]
		var vecx2=[]
		var vecy1=[]		
		var vecy2=[]				
		for i1 in range(11):			
			var vp3=points[faces[i][0][0]]+(points[faces[i][0][1]]-points[faces[i][0][0]])*(i1/10.0)
			vecx1.append(calc_point_edge_vec3(points[faces[i][0][0]],points[faces[i][0][1]],vp3))
			vp3=points[faces[i][0][3]]+(points[faces[i][0][2]]-points[faces[i][0][3]])*(i1/10.0)
			vecx2.append(calc_point_edge_vec3(points[faces[i][0][3]],points[faces[i][0][2]],vp3))
			vp3=points[faces[i][0][0]]+(points[faces[i][0][3]]-points[faces[i][0][0]])*(i1/10.0)
			vecy1.append(calc_point_edge_vec3(points[faces[i][0][0]],points[faces[i][0][3]],vp3))
			vp3=points[faces[i][0][1]]+(points[faces[i][0][2]]-points[faces[i][0][1]])*(i1/10.0)
			vecy2.append(calc_point_edge_vec3(points[faces[i][0][1]],points[faces[i][0][2]],vp3))

		#face_ele.set_points([points[faces[i][0][0]],points[faces[i][0][1]],points[faces[i][0][2]],points[faces[i][0][3]]])
		face_ele.set_points_edges(vecx1,vecx2,vecy1,vecy2)
		$scene/center/faces.add_child(face_ele)
		faces_ele.append(face_ele)		

func find_edge(ip1,ip2):
	for i in range(edges.size()):
		if edges[i][1]==ip1 and edges[i][2]==ip2:
			return i
	return -1
	
func calc_point_edge_vec3(p1,p2,p3):
	var e=-1
	for i in range(edges.size()):
		if points[edges[i][1]].distance_to(p1)<0.001 and points[edges[i][2]].distance_to(p2)<0.001:
			e=i
		if points[edges[i][1]].distance_to(p2)<0.001 and points[edges[i][2]].distance_to(p1)<0.001:
			e=i
			
	if e>=0:
		if edges[e][0]=="arc":
			return calc_circle_point(p1,p2,edges[e][3][1],p3.distance_to(p1)/p2.distance_to(p1))
		else:
			if edges[e][4].size()>0:
				#print("4!!!!!")
				return calc_polyline_point(p1,p2,edges[e][4],p3.distance_to(p1)/p2.distance_to(p1))
			elif edges[e][3].size()>0:
				return calc_polyline_point(p1,p2,edges[e][3],p3.distance_to(p1)/p2.distance_to(p1))
			else:
				return p1+(p2-p1).normalized()*(p3.distance_to(p1))
	else:
		return p1+(p2-p1).normalized()*(p3.distance_to(p1))

func append_line(iblock,ip1, ip2):
	var p1=points[ip1]
	var p2=points[ip2]
	
	#print(str(p1)+" - "+str(p2))
	var line3d=null
	var e=find_edge(ip1,ip2)
	for i in range(blocks_lines.size()):
		for l in blocks_lines[i]:
			if l.has_points(p1,p2):
				line3d=l
	if line3d==null:
		#print("created")
		line3d=line3d_comp.instance()		
		if e<0:
			line3d.set_points_3d(p1,p2)
		else:			
			if edges[e][0]=="arc":
				var vp=[]
				for i in range(10):
					vp.append(calc_circle_point(p1,p2,edges[e][3][1],float(i)/9.0))
				line3d.set_points_3d_vec(vp)				
			elif edges[e][0]=="spline" and edges[e][3].size()>0:
				var curve3d=Curve3D.new()
				curve3d.add_point(p1)
				for v in edges[e][3]:
					curve3d.add_point(v)
				curve3d.add_point(p2)					
				var vp=[]
				for i in range(20):
					#var idxt=calc_polyline_point_idx_t(p1,p2,edges[e][3],float(i)/19.0)
					#vp.append(curve3d.interpolate(idxt[0],float(i)/19.0))
					vp.append(curve3d.interpolate_baked(float(i)/19.0 * curve3d.get_baked_length(), true))
				line3d.set_points_3d_vec(vp)
				edges[e][4]=vp	
				edges			
				
			else:
				var vp=[]
				vp.append(p1)
				for p in edges[e][3]:
					vp.append(p)
				vp.append(p2)
				line3d.set_points_3d_vec(vp)				

		$scene/center/b_lines.add_child(line3d)
	blocks_lines[iblock].append(line3d)
	if e>=0:
		edges_lines[e]=line3d
	

		
func block_set_cell_len(i,xlen,ylen,zlen):
	var lx1=abs(points[blocks[i][0][1]].x-points[blocks[i][0][0]].x)
	var lx2=abs(points[blocks[i][0][2]].x-points[blocks[i][0][3]].x)
	var lx3=abs(points[blocks[i][0][5]].x-points[blocks[i][0][5]].x)
	var lx4=abs(points[blocks[i][0][6]].x-points[blocks[i][0][7]].x)
	var lx=max(max(max(lx1,lx2),lx3),lx4)
	var ly1=abs(points[blocks[i][0][3]].y-points[blocks[i][0][0]].y)
	var ly2=abs(points[blocks[i][0][2]].y-points[blocks[i][0][1]].y)
	var ly3=abs(points[blocks[i][0][7]].y-points[blocks[i][0][4]].y)
	var ly4=abs(points[blocks[i][0][6]].y-points[blocks[i][0][5]].y)
	var ly=max(max(max(ly1,ly2),ly3),ly4)
	var lz1=abs(points[blocks[i][0][4]].z-points[blocks[i][0][0]].z)
	var lz2=abs(points[blocks[i][0][5]].z-points[blocks[i][0][1]].z)
	var lz3=abs(points[blocks[i][0][6]].z-points[blocks[i][0][2]].z)
	var lz4=abs(points[blocks[i][0][7]].z-points[blocks[i][0][3]].z)
	var lz=max(max(max(lz1,lz2),lz3),lz4)
	var qx=int(ceil(lx/xlen))
	var qy=int(ceil(ly/ylen))
	var qz=int(ceil(lz/zlen))
	print([qx,qy,qz])
	blocks[i][1]=[qx,qy,qz]	
	var cellok=false
	while cellok==false:
		cellok=true
		for i in range(blocks.size()):
			for i2 in range(blocks.size()):
				if i!=i2:
					var vset=[false,false,false]
					if block_has_points(blocks[i2],[blocks[i][0][0],blocks[i][0][1],blocks[i][0][2],blocks[i][0][3]]) or block_has_points(blocks[i2],[blocks[i][0][4],blocks[i][0][5],blocks[i][0][6],blocks[i][0][7]]):
						vset[0]=true
						vset[1]=true
					if block_has_points(blocks[i2],[blocks[i][0][0],blocks[i][0][3],blocks[i][0][4],blocks[i][0][7]]) or block_has_points(blocks[i2],[blocks[i][0][1],blocks[i][0][2],blocks[i][0][5],blocks[i][0][6]]):
						vset[1]=true
						vset[2]=true
					if block_has_points(blocks[i2],[blocks[i][0][0],blocks[i][0][1],blocks[i][0][4],blocks[i][0][5]]) or block_has_points(blocks[i2],[blocks[i][0][2],blocks[i][0][3],blocks[i][0][6],blocks[i][0][7]]):
						vset[0]=true
						vset[2]=true
					for i3 in range(3):
						if vset[i3]:
							if blocks[i2][1][i3]>blocks[i][1][i3]:
								blocks[i][1][i3]=blocks[i2][1][i3]
								cellok=false
							if blocks[i2][1][i3]<blocks[i][1][i3]:
								blocks[i2][1][i3]=blocks[i][1][i3]
								cellok=false


func block_set_cell_quant(i,qx,qy,qz):
	print([qx,qy,qz])
	var q=[qx,qy,qz]
	blocks[i][1]=[qx,qy,qz]	
	var cellok=false
	while cellok==false:
		cellok=true
		for i in range(blocks.size()):
			for i2 in range(blocks.size()):
				if i!=i2:
					var vset=[false,false,false]
					if block_has_points(blocks[i2],[blocks[i][0][0],blocks[i][0][1],blocks[i][0][2],blocks[i][0][3]]) or block_has_points(blocks[i2],[blocks[i][0][4],blocks[i][0][5],blocks[i][0][6],blocks[i][0][7]]):
						vset[0]=true
						vset[1]=true
					if block_has_points(blocks[i2],[blocks[i][0][0],blocks[i][0][3],blocks[i][0][4],blocks[i][0][7]]) or block_has_points(blocks[i2],[blocks[i][0][1],blocks[i][0][2],blocks[i][0][5],blocks[i][0][6]]):
						vset[1]=true
						vset[2]=true
					if block_has_points(blocks[i2],[blocks[i][0][0],blocks[i][0][1],blocks[i][0][4],blocks[i][0][5]]) or block_has_points(blocks[i2],[blocks[i][0][2],blocks[i][0][3],blocks[i][0][6],blocks[i][0][7]]):
						vset[0]=true
						vset[2]=true
					for i3 in range(3):
						if vset[i3]:
							if blocks[i2][1][i3]!=blocks[i][1][i3]:
								blocks[i][1][i3]=q[i3]
								blocks[i2][1][i3]=q[i3]
								cellok=false

func block_set_cell_simple(i,qx,qy,qz):
	print([qx,qy,qz])
	var q=[qx,qy,qz]
	blocks[i][2]=[qx,qy,qz]	
	var cellok=false
	while cellok==false:
		cellok=true
		for i in range(blocks.size()):
			for i2 in range(blocks.size()):
				if i!=i2:
					var vset=[false,false,false]
					if block_has_points(blocks[i2],[blocks[i][0][0],blocks[i][0][1],blocks[i][0][2],blocks[i][0][3]]) or block_has_points(blocks[i2],[blocks[i][0][4],blocks[i][0][5],blocks[i][0][6],blocks[i][0][7]]):
						vset[0]=true
						vset[1]=true
					if block_has_points(blocks[i2],[blocks[i][0][0],blocks[i][0][3],blocks[i][0][4],blocks[i][0][7]]) or block_has_points(blocks[i2],[blocks[i][0][1],blocks[i][0][2],blocks[i][0][5],blocks[i][0][6]]):
						vset[1]=true
						vset[2]=true
					if block_has_points(blocks[i2],[blocks[i][0][0],blocks[i][0][1],blocks[i][0][4],blocks[i][0][5]]) or block_has_points(blocks[i2],[blocks[i][0][2],blocks[i][0][3],blocks[i][0][6],blocks[i][0][7]]):
						vset[0]=true
						vset[2]=true
					for i3 in range(3):
						if vset[i3]:
							if blocks[i2][2][i3]!=blocks[i][2][i3]:
								blocks[i][2][i3]=q[i3]
								blocks[i2][2][i3]=q[i3]
								cellok=false

func block_set_cell_edge_grading(i,v1,v2,v3,v4,v5,v6):
	var q=[v1,v2,v3,v4,v5,v6]
	blocks[i][2]=[v1,v2,v3,v4,v5,v6]
	#Falta verificar consistencia com demais arestas!

func remove_point(point_id):
	points.remove(point_id)
	for b in blocks:
		for i in range(b[0].size()):
			if b[0][i]>point_id:
				b[0][i]=b[0][i]-1
	for f in faces:
		for i in range(f[0].size()):
			if f[0][i]>point_id:
				f[0][i]=f[0][i]-1			

func remove_boundary(boundary_id):
	boundaries.remove(boundary_id)
			
						
func _on_Tree_button_pressed(item, column, id):
	if id>=point_edit_base and id<point_edit_base+dbase:
		point_idx=id-point_edit_base
		$panel_edit_point/edit_x.text=str(points[point_idx].x)
		$panel_edit_point/edit_y.text=str(points[point_idx].y)
		$panel_edit_point/edit_z.text=str(points[point_idx].z)
		$panel_edit_point.visible=true
		$panel_edit_point.rect_position=pos_window
		item_edit=item
	if id>=point_del_base and id<point_del_base+dbase:
		var point_id=id-point_del_base
		selected_point=point_id
		select_point(selected_point)
		$ConfirmationRemovePoint.dialog_text="Remove point "+str(point_id)+" ?\n(points list will be recreated)"
		$ConfirmationRemovePoint.popup_centered(Vector2(200,100))

	if id>=boundary_del_base and id<boundary_del_base+dbase:
		var boundary_id=id-boundary_del_base
		selected_boundary=boundary_id
		select_boundary(selected_boundary)
		$ConfirmationRemoveBoundary.dialog_text="Remove boundary "+str(boundary_id)+" ?\n(boundaries list will be recreated)"
		$ConfirmationRemoveBoundary.popup_centered(Vector2(200,100))

	
	if id>=block_del_base and id<block_del_base+dbase:
		var id_block=id-block_del_base
		select_block(id_block)
		selected_block=id_block
		$ConfirmationRemoveBlock.dialog_text="Remove block "+str(id_block)+" ?\n(blocks list will be recreated)"
		$ConfirmationRemoveBlock.popup_centered(Vector2(200,100))

	if id>=edge_del_base and id<edge_del_base+dbase:
		var id_edge=id-edge_del_base
		select_edge(id_edge)
		selected_edge=id_edge
		$ConfirmationRemoveEdge.dialog_text="Remove edge "+str(id_edge)+" ?"
		$ConfirmationRemoveEdge.popup_centered(Vector2(200,100))
		
	if id>=edge_edit_base and id<edge_edit_base+dbase:
		var id_edge=id-edge_edit_base
		selected_edge=id_edge
		$pop_edit_curve.popup(Rect2(mouse_position,Vector2(100,100)))

	if id>=edge_point_del_base and id<edge_point_del_base+dbase:
		var id_edge=int(floor((id-edge_point_del_base)/edgebase))
		var id_epoint=id%edgebase
		select_edge(id_edge)
		selected_edge=id_edge
		selected_epoint=id_epoint
		$ConfirmationRemoveEdgePoint.dialog_text="Remove point "+str(id_epoint)+" of edge "+str(id_edge)+" ?"
		$ConfirmationRemoveEdgePoint.popup_centered(Vector2(200,100))


		
	if id>=block_edit_base and id<block_edit_base+dbase:
		selected_block=id-block_edit_base
		select_block(selected_block)
		$panel_block_edit_points/edit_points.text=""
		for i in range(blocks[selected_block][0].size()):
			if i>0:
				$panel_block_edit_points/edit_points.text+=";"
			$panel_block_edit_points/edit_points.text+=str(blocks[selected_block][0][i])
		$panel_block_edit_points.visible=true
		$panel_block_edit_points.rect_position=pos_window

		
	if id>=block_cell_edit_base and id<block_cell_edit_base+dbase:
		var id_block=id-block_cell_edit_base
		selected_block=id_block
		select_block(selected_block)
		$panel_block_edit_cells/edit_x.text=str(blocks[selected_block][1][0])
		$panel_block_edit_cells/edit_y.text=str(blocks[selected_block][1][1])
		$panel_block_edit_cells/edit_z.text=str(blocks[selected_block][1][2])
		$panel_block_edit_cells.visible=true
		$panel_block_edit_cells.rect_position=pos_window		
				
	if id>=block_grading_edit_base and id<block_grading_edit_base+dbase:
		var id_block=id-block_grading_edit_base		
		selected_block=id_block
		select_block(selected_block)
		$pop_grading.popup(Rect2(mouse_position,Vector2(100,100)))

	if id>=block_zone_edit_base and id<block_zone_edit_base+dbase:
		var id_block=id-block_zone_edit_base		
		selected_block=id_block
		select_block(selected_block)
		$panel_block_edit_zone/edit_zone.text=blocks[selected_block][4]
		$panel_block_edit_zone.visible=true
		$panel_block_edit_zone.rect_position=pos_window	
						
	if id>=boundary_del_base and id<boundary_del_base+dbase:
		var id_boundary=id-boundary_del_base		
		
	if id>=boundary_name_edit_base and id<boundary_name_edit_base+dbase:
		var id_boundary=id-boundary_name_edit_base		
		selected_block=id_boundary
		select_boundary(selected_boundary)
		$panel_boundary_edit_name/edit_name.text=str(boundaries[selected_boundary][1])
		$panel_boundary_edit_name.visible=true
		$panel_boundary_edit_name.rect_position=pos_window			
		
	if id>=boundary_type_edit_base and id<boundary_type_edit_base+dbase:
		var id_boundary=id-boundary_type_edit_base				
		selected_block=id_boundary
		select_boundary(selected_boundary)
		$panel_boundary_edit_type/edit_type.text=str(boundaries[selected_boundary][2])
		$panel_boundary_edit_type.visible=true
		$panel_boundary_edit_type.rect_position=pos_window	
						
	if id>=boundary_faces_edit_base and id<boundary_faces_edit_base+dbase:
		$pop_boundary.popup(Rect2(mouse_position,Vector2(100,100)))	
		selected_boundary=id-boundary_faces_edit_base
		
	

func _on_button_ok_pressed():
		points[point_idx].x=float($panel_edit_point/edit_x.text)
		points[point_idx].y=float($panel_edit_point/edit_y.text)
		points[point_idx].z=float($panel_edit_point/edit_z.text)
		item_edit.set_text(1, "["+str(points[point_idx].x)+" "+str(points[point_idx].y)+" "+str(points[point_idx].z)+"]")
		$panel_edit_point.visible=false
		update_geometry()

func generate_blockmesh(filename):
	var file = File.new()
	var error = file.open(filename, File.WRITE)
	if error == OK:

		
		file.store_line("FoamFile")
		file.store_line("{")
		file.store_line("    version     2.0;")
		file.store_line("    format      ascii;")
		file.store_line("    class       dictionary;")
		file.store_line("    object      blockMeshDict;")
		file.store_line("}")
		file.store_line("convertToMeters 1;")
		file.store_line("vertices")
		file.store_line("(")
		for p in points:
			file.store_line("    ("+float2str(p.x)+" "+float2str(p.y)+" "+float2str(p.z)+")")
		file.store_line(");")
		
		file.store_line("blocks")
		file.store_line("(")
		for b in blocks:
			file.store_line("    hex ("+str(b[0][0])+" "+str(b[0][1])+" "+str(b[0][2])+" "+str(b[0][3])+" "+str(b[0][4])+" "+str(b[0][5])+" "+str(b[0][6])+" "+str(b[0][7])+") "+b[4]+" ("+str(b[1][0])+" "+str(b[1][1])+" "+str(b[1][2])+") simpleGrading ("+str(b[2][0])+" "+str(b[2][1])+" "+str(b[2][2])+")")
		file.store_line(");")
		file.store_line("edges")
		file.store_line("(")
		for e in edges:
			if e[0]=="arc":
				file.store_line("arc "+str(e[1])+" "+str(e[2])+" ("+float2str(e[3][0].x)+" "+float2str(e[3][0].y)+" "+float2str(e[3][0].z)+")")
			else:
				file.store_line(e[0]+" "+str(e[1])+" "+str(e[2]))
				file.store_line("(")
				for ep in e[3]:
					file.store_line(" ("+float2str(ep.x)+" "+float2str(ep.y)+" "+float2str(ep.z)+")")
				file.store_line(")")
		file.store_line(");")
		
		file.store_line("boundary")
		file.store_line("(")
		for b in boundaries:
			file.store_line("    "+b[1])
			file.store_line("   {")
			file.store_line("        type "+b[2]+";")
			file.store_line("        faces")
			file.store_line("        (")
			for f in b[0]:
				file.store_line("            ("+str(faces[f][0][0])+" "+str(faces[f][0][1])+" "+str(faces[f][0][2])+" "+str(faces[f][0][3])+")")
			file.store_line("        );")
			file.store_line("    }")
		file.store_line(");")
		file.store_line("mergePatchPairs")
		file.store_line("(")
		file.store_line(");")
		
		
	else:
		print("Error opening file!")
	file.close()

func vec_to_str(vec):
	var res=""
	for i in range(vec.size()):
		if i>0:
			res=res+";"
		res=res+str(vec[i])
	return res
	
func str_to_int_vec(txt):
	var res=[]
	for v in txt.split(";"):
		res.append(int(v))
	return res
	
func save_file(filename):
		
	var file = File.new()
	var error = file.open(filename, File.WRITE)
	if error == OK:

		file.store_line("blockfoam 0.4")
		file.store_line(str(points.size()))
		for p in points:
			file.store_line(float2str(p.x)+";"+float2str(p.y)+";"+float2str(p.z))

		#[points],[cells],[grading],[externalfaces],zone
		file.store_line(str(blocks.size()))
		for b in blocks:
			file.store_line(vec_to_str(b[0]))
			file.store_line(vec_to_str(b[1]))
			file.store_line(vec_to_str(b[2]))
			file.store_line(b[4])
			file.store_line(b[5])
		
		#faces name type
		file.store_line(str(boundaries.size()))
		for b in boundaries:
			file.store_line(vec_to_str(b[0]))
			file.store_line(b[1])
			file.store_line(b[2])
	
		file.store_line(str(edges.size()))
		for e in edges:
			file.store_line(e[0])
			file.store_line(str(e[1]))
			file.store_line(str(e[2]))
			file.store_line(str(e[3].size()))
			for p in e[3]:
				file.store_line(float2str(p.x)+";"+float2str(p.y)+";"+float2str(p.z))
		
		
	else:
		print("Error opening file!")
	file.close()


func load_file(filename):
		
	var file = File.new()
	var error = file.open(filename, File.READ)
	if error == OK:

		clear_points()
		var cab=file.get_line()
		var qpoints=int(file.get_line())		
		for i in range(qpoints):
			var x=file.get_line().split_floats(";")
			var p=Vector3(x[0],x[1],x[2])
			append_point(p)		
		
		#[points],[cells],[grading],[externalfaces],zone
		clear_blocks()
		var qblocks=int(file.get_line())		
		for i in range(qblocks):
			var ps=str_to_int_vec(file.get_line())
			var cs=str_to_int_vec(file.get_line())
			var gra=str_to_int_vec(file.get_line())
			var z=file.get_line()
			var gt=file.get_line()			
			append_block(ps,cs,gra,z,gt)

		boundaries=[]
		var qb=int(file.get_line())		
		for i in range(qb):
			var ps=str_to_int_vec(file.get_line())
			var n=file.get_line()
			var t=file.get_line()
			append_boundary(n,t)
			boundaries[boundaries.size()-1][0]=ps


		
		update_faces()
		update_geometry()

		
		edges=[]
		var qedges=int(file.get_line())		
		for i in range(qedges):
			var etype=file.get_line()
			var p1=int(file.get_line())
			var p2=int(file.get_line())
			var qp=int(file.get_line())
			var ps=[]
			for i2 in range(qp):
				var x=file.get_line().split_floats(";")
				ps.append(Vector3(x[0],x[1],x[2]))
			if etype=="arc":
				append_edge_arc_point(p1,p2,ps[0])
			else:
				append_edge_points(etype,p1,p2)
				edges[edges.size()-1][3]=ps
				

		
		update_faces()
		update_tree()
		update_geometry()
		update_unused_faces()


		
		
		
	else:
		print("Error opening file!")
	file.close()


func translate_points(ps,t):
	for p in ps:
		if p<points.size():
			points[p]=points[p]+t
			
func rotate_points(ps,center,axis,ang):
		for p in ps:
			if p<points.size():
				points[p]=points[p]-center
				points[p]=points[p].rotated(axis,deg2rad(ang))
				points[p]=points[p]+center

func scale_points(ps,center,scale):
		for p in ps:
			if p<points.size():
				points[p]=points[p]-center
				points[p].x=points[p].x*scale.x
				points[p].y=points[p].y*scale.y
				points[p].z=points[p].z*scale.z
				points[p]=points[p]+center


func select_points_str(text):
	var ps=str_to_int_vec(text)
	unselect_all_points()
	for p in ps:
		if p<points_ele.size():
			points_ele[p].set_selected(true)
	
func collapse_point(p1,p2):
	for b in blocks:
		for i in range(b[0].size()):
			if b[0][i]==p1:
				b[0][i]=p2
	for f in faces:
		for i in range(f[0].size()):
			if f[0][i]==p1:
				f[0][i]=p2
	remove_point(p1)
func _on_button_cancel_pressed():
		$panel_edit_point.visible=false

func _on_menu_actions_item_pressed(id):
	if id==0:
		$panel_create_master_block.visible=true
		$panel_create_master_block.rect_position=pos_window
	if id==1:
		$panel_create_boundary.visible=true
		$panel_create_boundary.rect_position=pos_window		
	if id==2:
		$panel_set_cells.visible=true
		$panel_set_cells.rect_position=pos_window				
	if id==3:
		$panel_collapse_points.visible=true
		$panel_collapse_points.rect_position=pos_window				
	if id==4:
		$panel_blocks_remove.visible=true
		$panel_blocks_remove.rect_position=pos_window
	if id==5:
		$panel_arc_by_center.visible=true
		$panel_arc_by_center.rect_position=pos_window	
	if id==6:
		$panel_arc_by_point.visible=true
		$panel_arc_by_point.rect_position=pos_window				
	if id==7:
		edge_type="spline"
		$panel_edge_points.visible=true
		$panel_edge_points.rect_position=pos_window				
	if id==8:
		edge_type="polyLine"
		$panel_edge_points.visible=true
		$panel_edge_points.rect_position=pos_window				
	if id==9:
		edge_type="BSpline"
		$panel_edge_points.visible=true
		$panel_edge_points.rect_position=pos_window					
	if id==10:
		$panel_add_point.visible=true
		$panel_add_point.rect_position=pos_window		
	if id==11:
		$panel_add_block.visible=true
		$panel_add_block.rect_position=pos_window		
	if id==12:
		$panel_translation.visible=true
		$panel_translation.rect_position=pos_window	
		select_points_str($panel_translation/edit_translation_points.text)
	if id==13:
		$panel_rotation.visible=true
		$panel_rotation.rect_position=pos_window	
		select_points_str($panel_rotation/edit_rotation_points.text)
	if id==14:
		$panel_scale.visible=true
		$panel_scale.rect_position=pos_window	
		select_points_str($panel_scale/edit_scale_points.text)
	if id==15:
		$ConfirmationClearAll.popup_centered(Vector2(200,100))		

func calc_polyline_point(p1,p2,ps1,step):
	var ps=[]
	if p2.distance_to(ps1[0])<p1.distance_to(ps1[0]):
		ps.append(p2)
		for p in ps1:
			ps.append(p)
		ps.append(p1)
		step=1-step
	else:
		ps.append(p1)
		for p in ps1:
			ps.append(p)
		ps.append(p2)
		
	var tdist=0
	for i in range(ps.size()-1):
		tdist+=ps[i+1].distance_to(ps[i])
	var dist=0
	var p=0
	for i in range(ps.size()-1):
		dist+=ps[i+1].distance_to(ps[i])
		if dist/tdist>=step:
			p=i
			break
	return (ps[p]-ps[p+1]).normalized()*((dist/tdist)-step)+ps[p+1]
	
func calc_polyline_point_idx_t(p1,p2,ps1,step):
	var ps=[]
	var res=[0,0.0]
	if p2.distance_to(ps1[0])<p1.distance_to(ps1[0]):
		ps.append(p2)
		for p in ps1:
			ps.append(p)
		ps.append(p1)
		step=1-step
	else:
		ps.append(p1)
		for p in ps1:
			ps.append(p)
		ps.append(p2)
		
	var tdist=0
	for i in range(ps.size()-1):
		tdist+=ps[i+1].distance_to(ps[i])
	var dist=0
	var p=0
	for i in range(ps.size()-1):
		dist+=ps[i+1].distance_to(ps[i])
		if dist/tdist>=step:
			p=i
			res[0]=i
			var vp=(ps[p]-ps[p+1]).normalized()*((dist/tdist)-step)+ps[p+1]
			res[1]=(vp.distance_to(ps[p]))/(ps[p+1].distance_to(ps[p]))
			break
	return res
		
		
func calc_circle_point(p1,p2,center,step):#step 0..1
	var v=(p2-p1)*step+p1
	var r=p1.distance_to(center)*(1-step)+p2.distance_to(center)*(step)
	return (v-center).normalized()*r+center


func calc_circle_center(p1, p2, p3):
	var vx=p3-p1
	var vy=p2-p1
	var vz=vx.cross(vy)
	var T=Transform(vx,vy,vz,p1)
	T=T.orthonormalized()
	var Ti=T.affine_inverse()
	var pp1=Ti.xform(p1)
	var pp2=Ti.xform(p2)
	var pp3=Ti.xform(p3)
	print(pp1)
	print(pp2)
	print(pp3)
	var center=calc_circle_center_2D(pp1, pp2, pp3)
	return T.xform(center)
	
func calc_circle_center_2D(p1, p2, p3):
	var x1 = p1.x
	var x2 = p2.x
	var x3 = p3.x
	var y1 = p1.y
	var y2 = p2.y
	var y3 = p3.y
	
	var A = x1*(y2-y3)-y1*(x2-x3)+x2*y3-x3*y2
	var B = (x1*x1+y1*y1)*(y3-y2)+(x2*x2+y2*y2)*(y1-y3)+(x3*x3+y3*y3)*(y2-y1);
	var C = (x1*x1+y1*y1)*(x2-x3)+(x2*x2+y2*y2)*(x3-x1)+(x3*x3+y3*y3)*(x1-x2);
	var D = (x1*x1+y1*y1)*(x3*y2-x2*y3)+(x2*x2+y2*y2)*(x1*y3-x3*y1)+(x3*x3+y3*y3)*(x2*y1-x1*y2);
	
	return Vector3(-B/(2*A),-C/(2*A),0)
			
func _on_menu_file_item_pressed(id):
	if id==0:
		$blockmeshFileDialog.popup(Rect2(200,150,600,400))
	if id==1:
		$blockfoamFileDialog.popup(Rect2(200,150,600,400))
	if id==2:
		$openBlockfoamFileDialog.popup(Rect2(200,150,600,400))
		
func _on_menu_view_item_pressed(id):
	if id==0:
		$scene.rotation_degrees=Vector3(0,0,0)
	if id==1:
		$scene.rotation_degrees=Vector3(0,0,-90)
	if id==2:
		$scene.rotation_degrees=Vector3(90,0,0)


func _on_button_create_master_block_cancel_pressed():
	$panel_create_master_block.visible=false


func _on_button_create_master_block_ok_pressed():
	var pini=Vector3(float($panel_create_master_block/edit_x_ini.text),float($panel_create_master_block/edit_y_ini.text),float($panel_create_master_block/edit_z_ini.text))
	var pfim=Vector3(float($panel_create_master_block/edit_x_fim.text),float($panel_create_master_block/edit_y_fim.text),float($panel_create_master_block/edit_z_fim.text))
	var xcuts=$panel_create_master_block/edit_xcuts.text.split_floats(";",false)
	var ycuts=$panel_create_master_block/edit_ycuts.text.split_floats(";",false)
	var zcuts=$panel_create_master_block/edit_zcuts.text.split_floats(";",false)
	create_master_block(pini,pfim,xcuts,ycuts,zcuts)
	update_geometry()
	$panel_create_master_block.visible=false
	$Camera.size=pfim.distance_to(pini)*2
	$scene.translation.x=-$scene/center.translation.x
	#$scene.translation.z=-$scene/center.translation.z
	


func _on_Tree_item_selected():
	var item=$Tree.get_selected()
	if item.get_parent().get_text(0).substr(0,2)=="b_":
		item=item.get_parent()
	if item.get_parent().get_text(0).substr(0,2)=="e_":
		item=item.get_parent()		
	if item.get_parent().get_text(0).substr(0,3)=="bc_":
		item=item.get_parent()		
	if item.get_parent().get_text(0).substr(0,3)=="ep_":
		item=item.get_parent()			
	if item.get_text(0).substr(0,2)=="b_":
		select_block(int(item.get_text(0).substr(2)))
	if item.get_text(0).substr(0,2)=="f_":
		select_face(int(item.get_text(0).substr(2)))
	if item.get_text(0).substr(0,3)=="bc_":
		select_boundary(int(item.get_text(0).substr(3)))
	if item.get_text(0).substr(0,2)=="p_":
		select_point(int(item.get_text(0).substr(2)))
	if item.get_text(0).substr(0,2)=="e_":
		select_edge(int(item.get_text(0).substr(2)))				


func _on_button_boundary_cancel_pressed():
	$panel_create_boundary.visible=false


func _on_button_boundary_ok_pressed():
	append_boundary($panel_create_boundary/edit_name.text,$panel_create_boundary/edit_type.text)
	update_geometry()
	update_tree()
	$panel_create_boundary.visible=false



func _on_pop_boundary_id_pressed(id):
	if id==0:
		boundaries[selected_boundary][0]=[]
		update_geometry()
		update_tree()		
	if id==1:
		$panel_boundary_edit_faces/edit_faces.text=""
		for i in boundaries[selected_boundary][0].size():
			if i>0:
				$panel_boundary_edit_faces/edit_faces.text=$panel_boundary_edit_faces/edit_faces.text+";"			
			$panel_boundary_edit_faces/edit_faces.text=$panel_boundary_edit_faces/edit_faces.text+str(boundaries[selected_boundary][0][i])
		$panel_boundary_edit_faces.visible=true
		$panel_boundary_edit_faces.rect_position=pos_window		
	if id==2:
		func_remove_faces=false
		$panel_boundary_add_faces.visible=true
		$panel_boundary_add_faces.rect_position=pos_window		
	if id==3:
		func_remove_faces=true
		$panel_boundary_add_faces.visible=true
		$panel_boundary_add_faces.rect_position=pos_window				
				
func _on_button_boundary_edit_faces_cancel_pressed():
	$panel_boundary_edit_faces.visible=false


func _on_button_boundary_edit_faces_ok_pressed():
		boundaries[selected_boundary][0]=[]
		var fs=$panel_boundary_edit_faces/edit_faces.text.split(";")
		for f in fs:
			var fi=int(f)
			if fi>=0 and fi<faces.size():
				boundaries[selected_boundary][0].append(fi)
		update_geometry()
		update_tree()	
		$panel_boundary_edit_faces.visible=false


func _on_button_boundary_add_faces_cancel_pressed():
	$panel_boundary_add_faces.visible=false
	select_boundary(selected_boundary)


func _on_button_boundary_add_faces_ok_pressed():
		var xini=min(float($panel_boundary_add_faces/edit_x_ini.text),float($panel_boundary_add_faces/edit_x_fim.text))
		var yini=min(float($panel_boundary_add_faces/edit_y_ini.text),float($panel_boundary_add_faces/edit_y_fim.text))
		var zini=min(float($panel_boundary_add_faces/edit_z_ini.text),float($panel_boundary_add_faces/edit_z_fim.text))
		var xfim=max(float($panel_boundary_add_faces/edit_x_ini.text),float($panel_boundary_add_faces/edit_x_fim.text))
		var yfim=max(float($panel_boundary_add_faces/edit_y_ini.text),float($panel_boundary_add_faces/edit_y_fim.text))
		var zfim=max(float($panel_boundary_add_faces/edit_z_ini.text),float($panel_boundary_add_faces/edit_z_fim.text))
		for i in faces.size():
			var is_in=true			
			for p in faces[i][0]:
				if points[p].x<xini or points[p].y<yini or points[p].z<zini:
					is_in=false
				if points[p].x>xfim or points[p].y>yfim or points[p].z>zfim:
					is_in=false
			if is_in:
				if func_remove_faces==false:
					if boundaries[selected_boundary][0].has(i)==false:
						boundaries[selected_boundary][0].append(i)
				else:
					if boundaries[selected_boundary][0].has(i)==true:
						boundaries[selected_boundary][0].erase(i)
					
		update_geometry()
		update_tree()	
		$panel_boundary_add_faces.visible=false
		select_boundary(selected_boundary)


func _on_blockmeshFileDialog_file_selected(path):
	generate_blockmesh(path)


func _on_button_set_cell_cancel_pressed():
	$panel_set_cells.visible=false


func _on_button_set_cell_ok_pressed():
	var xlen=float($panel_set_cells/edit_x.text)
	var ylen=float($panel_set_cells/edit_y.text)
	var zlen=float($panel_set_cells/edit_z.text)	
	for i1 in range(blocks.size()):
		blocks[i1][1]=[1,1,1]	
	for i in range(blocks.size()):
		block_set_cell_len(i,xlen,ylen,zlen)
	update_tree()
	update_geometry()
	$panel_set_cells.visible=false


func _on_button_collapse_point_cancel_pressed():
	$panel_collapse_points.visible=false


func _on_button_collapse_point_ok_pressed():
	var xlen=float($panel_set_cells/edit_x.text)
	var ylen=float($panel_set_cells/edit_y.text)	
	collapse_point(int($panel_collapse_points/edit_p1.text),int($panel_collapse_points/edit_p2.text))
	update_faces()
	update_tree()
	update_geometry()
	$panel_collapse_points.visible=false


func _on_button_block_edit_points_cancel_pressed():
	$panel_block_edit_points.visible=false


func _on_button_block_edit_points_ok_pressed():
	blocks[selected_block][0]=[]
	var fs=$panel_block_edit_points/edit_points.text.split(";")
	for f in fs:
		var fi=int(f)
		if fi>=0 and fi<faces.size():
			blocks[selected_block][0].append(fi)
	update_faces()		
	update_geometry()
	update_tree()		
	$panel_block_edit_points.visible=false


func _on_button_block_edit_cell_cancel_pressed():
	$panel_block_edit_cells.visible=false


func _on_button_block_edit_cell_ok_pressed():
	var xc=int($panel_block_edit_cells/edit_x.text)
	var yc=int($panel_block_edit_cells/edit_y.text)
	var zc=int($panel_block_edit_cells/edit_z.text)	
	block_set_cell_quant(selected_block,xc,yc,zc)
	update_tree()
	update_geometry()		
	$panel_block_edit_cells.visible=false


func _on_button_block_edit_simple_cancel_pressed():
	$panel_block_edit_simple.visible=false


func _on_button_block_edit_simple_ok_pressed():
	var xc=float($panel_block_edit_simple/edit_x.text)
	var yc=float($panel_block_edit_simple/edit_y.text)
	var zc=float($panel_block_edit_simple/edit_z.text)	
	block_set_cell_simple(selected_block,xc,yc,zc)
	update_tree()
	update_geometry()		
	$panel_block_edit_simple.visible=false


func _on_button_boundary_edit_name_cancel_pressed():
	$panel_boundary_edit_name.visible=false


func _on_button_boundary_edit_name_ok_pressed():
	boundaries[selected_boundary][1]=$panel_boundary_edit_name/edit_name.text
	update_tree()
	$panel_boundary_edit_name.visible=false


func _on_button_boundary_edit_type_cancel_pressed():
	$panel_boundary_edit_type.visible=false


func _on_button_boundary_edit_type_ok_pressed():
	boundaries[selected_boundary][2]=$panel_boundary_edit_type/edit_type.text
	update_tree()
	$panel_boundary_edit_type.visible=false


func _on_button_block_edit_zone_cancel_pressed():
	$panel_block_edit_zone.visible=false


func _on_button_block_edit_zone_ok_pressed():
	blocks[selected_block][4]=$panel_block_edit_zone/edit_zone.text
	update_tree()	
	$panel_block_edit_zone.visible=false


func _on_ConfirmationRemoveBlock_confirmed():
		blocks.remove(selected_block)
		update_faces()
		update_tree()
		update_geometry()



func _on_ConfirmationRemovePoint_confirmed():
		remove_point(selected_point)
		update_faces()
		update_tree()
		update_geometry()		



func _on_ConfirmationRemoveBoundary_confirmed():
		remove_boundary(selected_boundary)
		update_faces()
		update_tree()
		update_geometry()


func _on_button_boundary_add_faces_preview_pressed():
		var xini=min(float($panel_boundary_add_faces/edit_x_ini.text),float($panel_boundary_add_faces/edit_x_fim.text))
		var yini=min(float($panel_boundary_add_faces/edit_y_ini.text),float($panel_boundary_add_faces/edit_y_fim.text))
		var zini=min(float($panel_boundary_add_faces/edit_z_ini.text),float($panel_boundary_add_faces/edit_z_fim.text))
		var xfim=max(float($panel_boundary_add_faces/edit_x_ini.text),float($panel_boundary_add_faces/edit_x_fim.text))
		var yfim=max(float($panel_boundary_add_faces/edit_y_ini.text),float($panel_boundary_add_faces/edit_y_fim.text))
		var zfim=max(float($panel_boundary_add_faces/edit_z_ini.text),float($panel_boundary_add_faces/edit_z_fim.text))
		unselect_all_faces()
		for i in faces.size():
			var is_in=true			
			for p in faces[i][0]:
				if points[p].x<xini or points[p].y<yini or points[p].z<zini:
					is_in=false
				if points[p].x>xfim or points[p].y>yfim or points[p].z>zfim:
					is_in=false
			if is_in:
				faces_ele[i].set_selected(true)




func _on_button_blocks_remove_preview_pressed():
		unselect_all_faces()
		unselect_all_lines()
		unselect_all_points()
		var xini=min(float($panel_blocks_remove/edit_x_ini.text),float($panel_blocks_remove/edit_x_fim.text))
		var yini=min(float($panel_blocks_remove/edit_y_ini.text),float($panel_blocks_remove/edit_y_fim.text))
		var zini=min(float($panel_blocks_remove/edit_z_ini.text),float($panel_blocks_remove/edit_z_fim.text))
		var xfim=max(float($panel_blocks_remove/edit_x_ini.text),float($panel_blocks_remove/edit_x_fim.text))
		var yfim=max(float($panel_blocks_remove/edit_y_ini.text),float($panel_blocks_remove/edit_y_fim.text))
		var zfim=max(float($panel_blocks_remove/edit_z_ini.text),float($panel_blocks_remove/edit_z_fim.text))
		
		for i in blocks.size():
			var is_in=true			
			for p in blocks[i][0]:
				if points[p].x<xini or points[p].y<yini or points[p].z<zini:
					is_in=false
				if points[p].x>xfim or points[p].y>yfim or points[p].z>zfim:
					is_in=false
			if is_in:
				select_block(i,false)


func _on_button_blocks_remove_cancel_pressed():
	$panel_blocks_remove.visible=false


func _on_button_blocks_remove_ok_pressed():
		var xini=min(float($panel_blocks_remove/edit_x_ini.text),float($panel_blocks_remove/edit_x_fim.text))
		var yini=min(float($panel_blocks_remove/edit_y_ini.text),float($panel_blocks_remove/edit_y_fim.text))
		var zini=min(float($panel_blocks_remove/edit_z_ini.text),float($panel_blocks_remove/edit_z_fim.text))
		var xfim=max(float($panel_blocks_remove/edit_x_ini.text),float($panel_blocks_remove/edit_x_fim.text))
		var yfim=max(float($panel_blocks_remove/edit_y_ini.text),float($panel_blocks_remove/edit_y_fim.text))
		var zfim=max(float($panel_blocks_remove/edit_z_ini.text),float($panel_blocks_remove/edit_z_fim.text))
		
		var removed=true
		while removed==true:
			removed=false
			for i in blocks.size():
				var is_in=true			
				for p in blocks[i][0]:
					if points[p].x<xini or points[p].y<yini or points[p].z<zini:
						is_in=false
					if points[p].x>xfim or points[p].y>yfim or points[p].z>zfim:
						is_in=false
				if is_in:
					blocks.remove(i)
					removed=true
					break
				
		
		update_faces()						
		update_geometry()
		update_tree()	
		$panel_blocks_remove.visible=false



func _on_blockfoamFileDialog_file_selected(path):
	var fn=path
	if fn.ends_with(".blkfoam")==false:
		fn=fn+".blkfoam"
	save_file(fn)
	


func _on_openBlockfoamFileDialog_file_selected(path):
	load_file(path)
	$Camera.size=get_p_min().distance_to(get_p_max())*2
	$scene.translation.x=-$scene/center.translation.x	


func _on_pop_grading_id_pressed(id):
	if id==0:
		blocks[selected_block][5]="simpleGrading"
		if len(blocks[selected_block][2])>3:
			blocks[selected_block][2].remove(3)
			blocks[selected_block][2].remove(3)
			blocks[selected_block][2].remove(3)		
		$panel_block_edit_simple/edit_x.text=str(blocks[selected_block][2][0])
		$panel_block_edit_simple/edit_y.text=str(blocks[selected_block][2][1])
		$panel_block_edit_simple/edit_z.text=str(blocks[selected_block][2][2])
		$panel_block_edit_simple.visible=true
		$panel_block_edit_simple.rect_position=pos_window			
	if id==1:
		blocks[selected_block][5]="edgeGrading"
		if len(blocks[selected_block][2])<6:
			blocks[selected_block][2].append(1)		
			blocks[selected_block][2].append(1)
			blocks[selected_block][2].append(1)
		$panel_block_edit_edge_grading/edit_1.text=str(blocks[selected_block][2][0])
		$panel_block_edit_edge_grading/edit_2.text=str(blocks[selected_block][2][1])
		$panel_block_edit_edge_grading/edit_3.text=str(blocks[selected_block][2][2])
		$panel_block_edit_edge_grading/edit_4.text=str(blocks[selected_block][2][3])
		$panel_block_edit_edge_grading/edit_5.text=str(blocks[selected_block][2][4])
		$panel_block_edit_edge_grading/edit_6.text=str(blocks[selected_block][2][5])

		
		$panel_block_edit_edge_grading.visible=true
		$panel_block_edit_edge_grading.rect_position=pos_window			


func _on_button_block_edit_edge_grading_cancel_pressed():
	$panel_block_edit_edge_grading.visible=false


func _on_button_block_edit_edge_grading_ok_pressed():
	$panel_block_edit_edge_grading.visible=false
	var v1=float($panel_block_edit_edge_grading/edit_1.text)
	var v2=float($panel_block_edit_edge_grading/edit_2.text)
	var v3=float($panel_block_edit_edge_grading/edit_3.text)
	var v4=float($panel_block_edit_edge_grading/edit_4.text)
	var v5=float($panel_block_edit_edge_grading/edit_5.text)
	var v6=float($panel_block_edit_edge_grading/edit_6.text)

	block_set_cell_edge_grading(selected_block,v1,v2,v3,v4,v5,v6)
	update_tree()
	update_geometry()	


func _on_button_arc_by_center_preview_pressed():
	pass # Replace with function body.


func _on_button_arc_by_center_cancel_pressed():
	pass # Replace with function body.
	$panel_arc_by_center.visible=false

func _on_button_arc_by_center_ok_pressed():
	var p1=int($panel_arc_by_center/edit_p1.text)
	var p2=int($panel_arc_by_center/edit_p2.text)
	var vx=float($panel_arc_by_center/edit_x.text)
	var vy=float($panel_arc_by_center/edit_y.text)
	var vz=float($panel_arc_by_center/edit_z.text)
	append_edge_arc_center(p1,p2,Vector3(vx,vy,vz))
	$panel_arc_by_center.visible=false
	update_tree()
	update_geometry()
	select_edge(edges.size()-1)


func _on_ConfirmationRemoveEdge_confirmed():
		edges.remove(selected_edge)
		update_tree()
		update_geometry()


func _on_button_arc_by_point_cancel_pressed():
	$panel_arc_by_point.visible=false


func _on_button_arc_by_point_preview_pressed():
	pass # Replace with function body.


func _on_button_arc_by_point_ok_pressed():
	var p1=int($panel_arc_by_point/edit_p1.text)
	var p2=int($panel_arc_by_point/edit_p2.text)
	var vx=float($panel_arc_by_point/edit_x.text)
	var vy=float($panel_arc_by_point/edit_y.text)
	var vz=float($panel_arc_by_point/edit_z.text)
	append_edge_arc_point(p1,p2,Vector3(vx,vy,vz))
	$panel_arc_by_point.visible=false
	update_tree()
	update_geometry()
	select_edge(edges.size()-1)


func _on_Button_test_pressed():
	calc_circle_center(Vector3(0,0,1), Vector3(0,1,3), Vector3(1,0,2))


func _on_button_edge_points_cancel_pressed():
	$panel_edge_points.visible=false


func _on_button_edge_points_ok_pressed():
	var p1=int($panel_edge_points/edit_p1.text)
	var p2=int($panel_edge_points/edit_p2.text)
	append_edge_points(edge_type,p1,p2)	
	$panel_edge_points.visible=false
	update_tree()
	update_geometry()
	select_edge(edges.size()-1)	


func _on_button_edge_add_point_cancel_pressed():
	$panel_edge_add_point.visible=false


func _on_button_edge_add_point_ok_pressed():
	var x=float($panel_edge_add_point/edit_x.text)
	var y=float($panel_edge_add_point/edit_y.text)
	var z=float($panel_edge_add_point/edit_z.text)
	edges[selected_edge][3].append(Vector3(x,y,z))
	$panel_edge_add_point.visible=false
	update_tree()
	update_geometry()
	select_edge(selected_edge)		


func _on_ConfirmationRemoveEdgePoint_confirmed():
		edges[selected_edge][3].remove(selected_epoint)
		if edges[selected_edge][3].size()==0:
			edges[selected_edge][4]=[]
		update_tree()
		#update_faces()
		update_geometry()
		


func _on_button_add_point_cancel_pressed():
	$panel_add_point.visible=false


func _on_button_add_point_ok_pressed():
	var x=float($panel_add_point/edit_x.text)
	var y=float($panel_add_point/edit_y.text)
	var z=float($panel_add_point/edit_z.text)
	append_point(Vector3(x,y,z))
	$panel_add_point.visible=false
	update_tree()
	update_geometry()
	select_point(points.size()-1)


func _on_button_add_block_cancel_pressed():
	$panel_add_block.visible=false


func _on_button_add_block_ok_pressed():
	var p1=int($panel_add_block/edit_1.text)
	var p2=int($panel_add_block/edit_2.text)
	var p3=int($panel_add_block/edit_3.text)
	var p4=int($panel_add_block/edit_4.text)
	var p5=int($panel_add_block/edit_5.text)
	var p6=int($panel_add_block/edit_6.text)
	var p7=int($panel_add_block/edit_7.text)
	var p8=int($panel_add_block/edit_8.text)
			
	blocks.append([[p1,p2,p3,p4,p5,p6,p7,p8],[1,1,1],[1,1,1],[false,false,false,false,false,false],"","simpleGrading"])
	$panel_add_block.visible=false
	update_faces()
	update_tree()
	update_geometry()
	select_block(blocks.size()-1)


	
func _on_edit_translation_points_text_changed():
	select_points_str($panel_translation/edit_translation_points.text)


func _on_button_box_cancel_pressed():
	$panel_box_sel.visible=false


func _on_button_box_ok_pressed():
	var xini=min(float($panel_box_sel/edit_x_ini.text),float($panel_box_sel/edit_x_fim.text))
	var yini=min(float($panel_box_sel/edit_y_ini.text),float($panel_box_sel/edit_y_fim.text))
	var zini=min(float($panel_box_sel/edit_z_ini.text),float($panel_box_sel/edit_z_fim.text))
	var xfim=max(float($panel_box_sel/edit_x_ini.text),float($panel_box_sel/edit_x_fim.text))
	var yfim=max(float($panel_box_sel/edit_y_ini.text),float($panel_box_sel/edit_y_fim.text))
	var zfim=max(float($panel_box_sel/edit_z_ini.text),float($panel_box_sel/edit_z_fim.text))
	edit_ref.text=""
	for i in range(points.size()):
		if points[i].x>=xini and points[i].y>=yini and points[i].z>=zini and points[i].x<=xfim and points[i].y<=yfim and points[i].z<=zfim:
			if edit_ref.text!="":
				edit_ref.text+=";"
			edit_ref.text+=str(i)		
	$panel_box_sel.visible=false
	select_points_str(edit_ref.text)


func _on_button_translation_box_pressed():
	edit_ref=$panel_translation/edit_translation_points
	$panel_box_sel.visible=true
	$panel_box_sel.rect_position=pos_window+Vector2($panel_translation.rect_size.x+4,0)


func _on_button_translation_cancel_pressed():
	$panel_translation.visible=false


func _on_button_translation_ok_pressed():
	var vx=float($panel_translation/edit_x.text)
	var vy=float($panel_translation/edit_y.text)
	var vz=float($panel_translation/edit_z.text)
	translate_points(str_to_int_vec($panel_translation/edit_translation_points.text),Vector3(vx,vy,vz))
	$panel_translation.visible=false
	update_tree()
	update_geometry()


func _on_edit_rotation_points_text_changed():
	select_points_str($panel_rotation/edit_rotation_points.text)


func _on_button_rotation_cancel_pressed():
	$panel_rotation.visible=false


func _on_button_rotation_box_pressed():
	edit_ref=$panel_rotation/edit_rotation_points
	$panel_box_sel.visible=true
	$panel_box_sel.rect_position=pos_window+Vector2($panel_rotation.rect_size.x+4,0)


func _on_button_rotation_ok_pressed():
	var cx=float($panel_rotation/edit_center_x.text)
	var cy=float($panel_rotation/edit_center_y.text)
	var cz=float($panel_rotation/edit_center_z.text)
	var ax=float($panel_rotation/edit_axis_x.text)
	var ay=float($panel_rotation/edit_axis_y.text)
	var az=float($panel_rotation/edit_axis_z.text)
	var ang=float($panel_rotation/edit_angle.text)	
	rotate_points(str_to_int_vec($panel_rotation/edit_rotation_points.text),Vector3(cx,cy,cz),Vector3(ax,ay,az),ang)
	$panel_rotation.visible=false
	update_tree()
	update_geometry()


func _on_button_scale_box_pressed():
	edit_ref=$panel_scale/edit_scale_points
	$panel_box_sel.visible=true
	$panel_box_sel.rect_position=pos_window+Vector2($panel_scale.rect_size.x+4,0)


func _on_button_scale_cancel_pressed():
	$panel_scale.visible=false


func _on_button_scale_ok_pressed():
	var cx=float($panel_scale/edit_center_x.text)
	var cy=float($panel_scale/edit_center_y.text)
	var cz=float($panel_scale/edit_center_z.text)
	var ax=float($panel_scale/edit_scale_x.text)
	var ay=float($panel_scale/edit_scale_y.text)
	var az=float($panel_scale/edit_scale_z.text)
	scale_points(str_to_int_vec($panel_scale/edit_scale_points.text),Vector3(cx,cy,cz),Vector3(ax,ay,az))
	$panel_scale.visible=false
	update_tree()
	update_geometry()


func _on_edit_scale_points_text_changed():
	select_points_str($panel_scale/edit_scale_points.text)


func _on_pop_edit_curve_id_pressed(id):
	select_edge(selected_edge)	
	$panel_edge_add_point.visible=true
	$panel_edge_add_point.rect_position=pos_window	


func _on_ConfirmationClearAll_confirmed():
	clear_blocks()
	clear_points()
	edges.clear()
	boundaries.clear()
	faces.clear()
	update_tree()
	update_geometry()	
	
