/*
Copyright (c) 2026 skirlez

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/


// we can't really get unix time in milliseconds in gamemaker, so we just add current_time to this
function _ulid_gm_unix_time() {
	date_set_timezone(timezone_utc)
	var unix_seconds = int64(date_second_span(date_create_datetime(1970, 1, 1, 0, 0, 0), date_current_datetime()));
	return unix_seconds * int64(1000);
	date_set_timezone(timezone_local)
}

// see the comment above generate_ulid for info about this flag
global.ulid_gm_throw_on_random_overflow = true;

function _generate_ulid_buffer_internal() {
	static buffer = buffer_create(16, buffer_fixed, 1)
	buffer_seek(buffer, buffer_seek_start, 0)
				
	static unix_time = _ulid_gm_unix_time()
	static last_run = unix_time - 1 // ensure first run generates random component
	
	var epoch = unix_time + int64(current_time)
	var epoch_32 = (epoch >> 16) & 0xFFFFFFFF;
	var epoch_16 = epoch & 0xFFFF;
	
	// buffers in gamemaker are LE
	var epoch_32_swapped =
		((epoch_32 & 0xFF)			<< 24) |
		((epoch_32 & 0xFF00)		<< 8)  |
		((epoch_32 & 0xFF0000)		>> 8)  |
		((epoch_32 & 0xFF000000)	>> 24)
	var epoch_16_swapped = 
		((epoch_16 & 0xFF) << 8) | (epoch_16 >> 8)
	
	buffer_write(buffer, buffer_u32, epoch_32_swapped)
	buffer_write(buffer, buffer_u16, epoch_16_swapped)
	
	static rand_16 = 0
	static rand_64 = 0

	if last_run != epoch {
		rand_16 = int64(irandom(65536 - 1))
		rand_64 = int64(irandom(4294967296 - 1)) << 32 | int64(irandom(4294967296 - 1))
		last_run = epoch
	}
	else {
		// per the spec, ulids should remain sortable
		// to ensure this, generations within the same millisecond (same timestamp component)
		// have their random component increased by 1
		// (this is the reason why we reverse byte order before writing the random data, 
		// even though it's random, we need to be able to increment it properly)
		
		rand_64 += 1
		if rand_64 == 0 {
			rand_16 += 1
			if rand_16 == 0 {
				if global.ulid_gm_throw_on_random_overflow
					throw "Random component of ULID overflowed"
			}
		}
	}
	
	// this is the easiest way to swap byte order for an int64, as far as i can tell, 
	// it can't be done as bit shifts because of signed shift right (0xFF00000000000000 >> 56 == -1)
	
	static swap_endianness_buffer = buffer_create(8, buffer_fixed, 1)
	buffer_seek(swap_endianness_buffer, buffer_seek_start, 0)
	buffer_write(swap_endianness_buffer, buffer_u64, rand_64)
	buffer_seek(swap_endianness_buffer, buffer_seek_start, 0)
	
	buffer_write(buffer, buffer_u16, ((rand_16 & 0xFF) << 8) | (rand_16 >> 8))
	buffer_write(buffer, buffer_u64,  
								(int64(buffer_read(swap_endianness_buffer, buffer_u8)) << 56) |
								(int64(buffer_read(swap_endianness_buffer, buffer_u8)) << 48) |
								(int64(buffer_read(swap_endianness_buffer, buffer_u8)) << 40) |
								(int64(buffer_read(swap_endianness_buffer, buffer_u8)) << 32) |
								(int64(buffer_read(swap_endianness_buffer, buffer_u8)) << 24) |
								(int64(buffer_read(swap_endianness_buffer, buffer_u8)) << 16) |
								(int64(buffer_read(swap_endianness_buffer, buffer_u8)) << 8)  |
								int64(buffer_read(swap_endianness_buffer, buffer_u8)))
					
	buffer_seek(buffer, buffer_seek_start, 0)
	return buffer;

}

/**
*
* Generates and returns a ULID string.  
* Optionally accepts a `buffer` to create the ULID from. If a buffer is passed in, it will not be freed.
*
* If `global.ulid_gm_throw_on_random_overflow` is set,
* this function will throw an error if the random component overflows
* which can happen if an extremely large (around 2^79 on average) amount of ULIDs
* are generated in the same millisecond.
*/

function generate_ulid(buffer = _generate_ulid_buffer_internal()) {
	static characterset = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
							65, 66, 67, 68, 69, 70, 71, 72, 74, 75, 77,
							78, 80, 81,82, 83, 84, 86, 87, 88, 89, 90]
	
	static ulid = buffer_create(26, buffer_fixed, 1)
	buffer_seek(ulid, buffer_seek_start, 0)
	// add 2 here to make it 130 bits for 26 characters (they will be read as 0)
	var bits_unread = 10;
	var num = buffer_read(buffer, buffer_u8)
	for (var i = 0; i < 26; i++) {
		var index;
		if bits_unread < 5 {
			static masks = [0, 1, 3, 7, 15, 31]
			var previous = num;
			num = buffer_read(buffer, buffer_u8)
			// stupid line. i promise it's correct
			index = (((previous) & masks[bits_unread]) << (5 - bits_unread)) | ((num >> (8 - (5 - bits_unread))) & masks[5 - bits_unread]);
		}
		else
			index = (num >> (bits_unread - 5)) & 31;
		buffer_write(ulid, buffer_u8, characterset[index])
		bits_unread -= 5;
		if bits_unread < 0
			bits_unread += 8
	}
	buffer_seek(ulid, buffer_seek_start, 0)
	return buffer_read(ulid, buffer_string);
}


/**
*
* Returns a ULID as a buffer of fixed length.
*
* If `global.ulid_gm_throw_on_random_overflow` is set,
* this function will throw an error if the random component overflows
* which can happen if an extremely large (around 2^79 on average) amount of ULIDs
* are generated in the same millisecond.
*/
function generate_ulid_buffer() {
	var buffer = _generate_ulid_buffer_internal()
	var out = buffer_create(16, buffer_fixed, 1)
	buffer_copy(buffer, 0, 16, out, 0)
	return out
}