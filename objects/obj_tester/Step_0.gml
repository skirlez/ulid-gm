
if keyboard_check_pressed(vk_space) {
	ulid = generate_ulid()
	ulid_2 = generate_ulid()
	var ulid_3 = generate_ulid_buffer()
	show_debug_message($"1st ULID: {ulid}")
	show_debug_message($"2nd ULID: {ulid_2}")
	
	high_3 = buffer_read(ulid_3, buffer_u64)
	low_3 = buffer_read(ulid_3, buffer_u64)
	buffer_delete(ulid_3)
	show_debug_message($"3rd ULID: {high_3}, {low_3}")
	state = states.single_results
}
if keyboard_check_pressed(vk_enter) {
	test_start = current_time
	for (var i = 0; i < test_amount; i++) {
		generate_ulid()	
	}
	test_end = current_time
	state = states.batch_results
}
