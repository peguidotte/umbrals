extends RefCounted
## Cloth rows keep their width and vertical extent; the near leg owns the overlap.
static func project(point: Vector2, source: Dictionary, config: Dictionary, top_offset: Vector2, foot_offset: Vector2) -> Vector2:
	var top: float = config.volume_span_y[0]
	var bottom: float = config.volume_span_y[1]
	var span: float = bottom-top
	var weight: float = clampf((point.y-top)/span,0,1)
	var offset: Vector2 = top_offset.lerp(foot_offset,weight)
	var source_slope: float = float(source.ankle[0]-source.hip[0])/float(source.ankle[1]-source.hip[1])
	var vertical_scale: float = 1+(foot_offset.y-top_offset.y)/span
	var posed_slope: float = (source_slope+(foot_offset.x-top_offset.x)/span)/vertical_scale
	var normal_width: float = maxf(1,sqrt(1+posed_slope*posed_slope)/sqrt(1+source_slope*source_slope))
	var width: float = lerpf(normal_width,1,smoothstep(config.width_fade_y[0],config.width_fade_y[1],point.y))
	var center: float = float(source.hip[0])+source_slope*(point.y-float(source.hip[1]))
	return Vector2(center+offset.x+(point.x-center)*width,point.y+offset.y)
