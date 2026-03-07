// for debugging
function ulid_to_bits(buf) {
	buffer_seek(buf, 0, 0)
	var str = "";
	for (var j = 0; j < 16; j++) {
		var byte = buffer_read(buf, buffer_u8)

		for (var i = 0; i < 8; i++) {
			var bit = 0b1000_0000 >> i
			if (byte & bit)
				str += "1"
			else
				str += "0"
		}
	}
	buffer_seek(buf, 0, 0)
	show_debug_message(str)
}

if keyboard_check_pressed(vk_space) {
	ulid = ulid_string()
	ulid_2 = ulid_string()
	var ulid_3 = ulid_buffer()
	show_debug_message($"1st ULID: {ulid}")
	show_debug_message($"2nd ULID: {ulid_2}")
	
	high_3 = buffer_read(ulid_3, buffer_u64)
	low_3 = buffer_read(ulid_3, buffer_u64)
	buffer_seek(ulid_3, 0, 0)
	var ulid_3_as_str = ulid_string_from_buffer(ulid_3)
	show_debug_message($"3rd ULID: {ulid_3_as_str}")
	
	

	var ulid_3_recreated = ulid_buffer_from_string(ulid_3_as_str)
	
	var high_3_r = buffer_read(ulid_3_recreated, buffer_u64)
	var low_3_r = buffer_read(ulid_3_recreated, buffer_u64)
	
	show_debug_message($"3rd ULID bytes: {high_3}, {low_3}")
	show_debug_message($"3rd ULID recreated bytes: {high_3_r}, {low_3_r}")
	
	buffer_delete(ulid_3)
	buffer_delete(ulid_3_recreated)
	state = states.single_results
}
if keyboard_check_pressed(vk_enter) {
	test_start = current_time
	for (var i = 0; i < test_amount; i++) {
		ulid_string()	
	}
	test_end = current_time
	state = states.batch_results
}
