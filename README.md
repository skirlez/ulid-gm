# ulid-gm

An implementation of [ULID](https://github.com/ulid/spec) for GameMaker.

Originally written for [Void Stranger Endless Void](https://github.com/skirlez/void-stranger-endless-void), I've polished it up, made it correct (as far as I can tell)

## Usage

### `ulid_string()`
Generates and returns an uppercase ULID string.  

### `ulid_string_from_buffer(buffer)`
Creates an uppercase ULID string from a `buffer`. The function does not free `buffer`.
Validity checks are not performed on `buffer` - it must have 16 readable bytes from its current seek position.

### `ulid_buffer()`
Generates and returns a ULID as a 1-byte aligned fixed length buffer.

### `ulid_buffer_from_string(str)`
Creates a ULID buffer from a string (`str`).
Validity checks are not performed on `str` - it should use only the ULID characterset, be uppercase, and have at least 26 characters.

### Random Component Overflow
If `global.ulid_gm_throw_on_random_overflow` is set, `ulid_string()` and `ulid_buffer()` will throw an error if the random component overflows (following the spec).
which can happen if an extremely large (around 2^79 on average) amount of ULIDs are generated in the same millisecond.

**Note that this global is set to `true` by default!** You can turn it off if you don't care about sorting ULIDs, or just catch the exception.

Though probabilistically speaking, even if the global is set to `true`, no one will ever encounter this error.

## License
The code is licensed under the terms of the MIT license, found in this repository.

## Contributing
Please contribute
