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
	var unix_seconds = int64(date_second_span(date_create_datetime(1970, 1, 1, 0, 0, 0), date_current_datetime()));
	return unix_seconds * int64(1000);
}

// see the comment above generate_ulid for info about this flag
global.ulid_gm_throw_on_random_overflow = true;

function _ulid_buffer_internal() {
	gml_pragma("forceinline");
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
	static rand_32_1 = 0
	static rand_32_2 = 0

	if last_run != epoch {
		rand_16 = int64(irandom(65536 - 1))
		rand_32_1 = int64(irandom(4294967296 - 1))
		rand_32_2 = int64(irandom(4294967296 - 1))
		last_run = epoch
	}
	else {
		// as per the spec, ulids should remain sortable
		// to ensure this, generations within the same millisecond (same timestamp component)
		// have their random component increased by 1
		// (this is the reason why we reverse byte order before writing the random data, 
		// even though it's random, we need to be able to increment it properly)
		
		rand_32_2 += 1
		if rand_32_2 == 0 {
			rand_32_1 += 1
			if rand_32_1 == 0 {
				rand_16 += 1
				if rand_16 == 0 {
					if global.ulid_gm_throw_on_random_overflow
						throw "Random component of ULID overflowed"
				}
			}
		}
	}
	
	
	buffer_write(buffer, buffer_u16, ((rand_16 & 0xFF) << 8) | (rand_16 >> 8))
	
	buffer_write(buffer, buffer_u32, ((rand_32_1 & 0x000000FF) << 24) |
									 ((rand_32_1 & 0x0000FF00) << 8)  |
									 ((rand_32_1 & 0x00FF0000) >> 8)  |
									 ((rand_32_1 & 0xFF000000) >> 24))
									 
	buffer_write(buffer, buffer_u32, ((rand_32_2 & 0x000000FF) << 24) |
									 ((rand_32_2 & 0x0000FF00) << 8)  |
									 ((rand_32_2 & 0x00FF0000) >> 8)  |
									 ((rand_32_2 & 0xFF000000) >> 24))
					
	buffer_seek(buffer, buffer_seek_start, 0)
	return buffer;

}

/**
* Generates and returns an uppercase ULID string.  
*
* If `global.ulid_gm_throw_on_random_overflow` is set (and it is by default),
* this function will throw an error if the random component overflows
* which can happen if an extremely large (around 2^79 on average) amount of ULIDs
* are generated in the same millisecond.
*/
function ulid_string() {
	return ulid_string_from_buffer(_ulid_buffer_internal());
}



/**
* Creates a ULID string from a `buffer`. The function does not free `buffer`.
*
* Size checks are not done on `buffer` - it must have 
* 16 readable bytes from its current seek position.
*/
function ulid_string_from_buffer(buffer) {
	static characterset = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
							65, 66, 67, 68, 69, 70, 71, 72, 74, 75, 77,
							78, 80, 81, 82, 83, 84, 86, 87, 88, 89, 90]
	static ulid_build = buffer_create(26 + 1, buffer_fixed, 1)
	buffer_seek(ulid_build, buffer_seek_start, 0)
	
	// add 2 here to make it 130 bits for 26 characters (they will be read as 0)
	var bits_unread = 10;
	var num = buffer_read(buffer, buffer_u8)
	
	// loop could be unrolled (but that's very boring)
	for (var i = 0; i < 26; i++) {
		var index;
		if bits_unread < 5 {
			static masks = [0b00000, 0b00001, 0b00011, 0b00111, 0b01111, 0b11111]
			var previous = num;
			num = buffer_read(buffer, buffer_u8)
			// stupid line. i promise it's correct
			index = (((previous) & masks[bits_unread]) << (5 - bits_unread)) | ((num >> (8 - (5 - bits_unread))) & masks[5 - bits_unread]);
		}
		else
			index = (num >> (bits_unread - 5)) & 31;
		buffer_write(ulid_build, buffer_u8, characterset[index])
		bits_unread -= 5;
		if bits_unread < 0
			bits_unread += 8
	}
	buffer_seek(ulid_build, buffer_seek_start, 0)
	return buffer_read(ulid_build, buffer_string);
}

/**
* Generates and returns a ULID as a 1-byte aligned fixed length buffer.
*
* If `global.ulid_gm_throw_on_random_overflow` is set (and it is by default),
* this function will throw an error if the random component overflows
* which can happen if an extremely large (around 2^79 on average) amount of ULIDs
* are generated in the same millisecond.
*/

function ulid_buffer() {
	var ulid = buffer_create(16, buffer_fixed, 1)
	var buffer = _ulid_buffer_internal()
	buffer_copy(buffer, 0, 16, ulid, 0)
	return ulid;
}

/**
* Creates a ULID buffer from a string (`str`).
* Validity checks are not performed on `str` - it should have at least 26 characters,
* and those characters should be from the uppercase ULID character set.
*/
function ulid_buffer_from_string(str) {
	var ulid = buffer_create(16, buffer_fixed, 1)
	// table mapping (character ordinal - 48) -> index in the character set
	static reverse_table = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
							0, 0, 0, 0, 0, 0, 0, 10, 11, 12,
							13, 14, 15, 16, 17, 0, 18, 19, 0,
							20, 21, 0, 22, 23, 24, 25, 26, 0,
							27, 28, 29, 30, 31];
	var bits_read = -2;
	var accum = 0;
		
	// loop could be unrolled (but that's very boring)
	for (var i = 1; i < 26 + 1; i++) {
		var ordinal = string_ord_at(str, i)
		if bits_read < 3 {
			accum = (accum << 5) | reverse_table[ordinal - 48]
		}
		else {
			static masks = [0b00000, 0b00001, 0b00011, 0b00111, 0b01111, 0b11111]
			var complete_to_8 = 8 - bits_read
			var index = reverse_table[ordinal - 48]
			accum = (accum << complete_to_8) | (index >> (5 - complete_to_8))
			buffer_write(ulid, buffer_u8, accum)
			accum = index & (masks[5 - complete_to_8])
		}
		bits_read += 5
		if bits_read >= 8
			bits_read -= 8
	}
	buffer_seek(ulid, buffer_seek_start, 0)
	return ulid;
}