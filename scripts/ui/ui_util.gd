class_name UiUtil
## Posizionamento esplicito di Control rispetto a un punto di ancoraggio del genitore.


## ax/ay: ancoraggio 0..1 nel genitore (0.5,0 = centro in alto); rect: offset rispetto a quel punto.
static func place(c: Control, ax: float, ay: float, rect: Rect2) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = rect.position.x
	c.offset_top = rect.position.y
	c.offset_right = rect.end.x
	c.offset_bottom = rect.end.y


static func fill(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
