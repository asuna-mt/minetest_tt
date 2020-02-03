# Tooltip API
This API explains how to handle the extended item tooltips (`description` field).

## Fields

Add these to the item definition.

* `_tt_ignore`: If `true`, the `description` of this item won't be altered at all
* `_tt_help`: Custom help text
* `_tt_food`: If `true`, item is a food item that can be consumed by the player
* `_tt_food_hp`: Health increase (in HP) for player when consuming food item
* `_tt_food_satiation`: Satiation increase for player when consuming food item (note: the meaning of satiation is depending on the game being used; some games might not have a satiation mechanic at all, in which case you can skip this field)

Once this mod had overwritten the `description` field of an item was overwritten, it will save the original (unaltered) `description` in the `_tt_original_description` field.

## `tt.register_snippet(func)`

Register a custom snippet function.
`func` is a function of the form `func(itemstring)`.
It will be called for (nearly) every itemstring and it must return a string you want to append to this item or `nil` if nothing shall be appended.
You can optionally return the text color in `"#RRGGBB"` format as the second return value.

Example:

```
tt.register_snippet(function(itemstring)
	if minetest.get_item_group(itemstring, "magic") == 1 then
		return "This item is magic"
	end
end)
```
