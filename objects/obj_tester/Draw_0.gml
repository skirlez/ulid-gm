if state == states.idle {
	draw_set_halign(fa_center)
	draw_set_valign(fa_middle)
	draw_text(room_width / 2, room_height / 2, $"Press space to generate 3 ULIDs\nPress enter to generate {test_amount} ULIDs")
}
else if state == states.single_results {
	draw_set_halign(fa_center)
	draw_set_valign(fa_middle)
	draw_text(room_width / 2, room_height / 2, $"{ulid}\n\n{ulid_2}\n\n{high_3}, {low_3}")
}
else if state == states.batch_results {
	draw_set_halign(fa_center)
	draw_set_valign(fa_middle)
	draw_text(room_width / 2, room_height / 2, $"Generated {test_amount} ULID strings\nin {test_end - test_start} milliseconds")
}
